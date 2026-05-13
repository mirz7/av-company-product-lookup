import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/theme_provider.dart';

class PhotoCropScreen extends StatefulWidget {
  final String? initialImagePath;
  const PhotoCropScreen({super.key, this.initialImagePath});

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }


  Future<void> _pickFromCamera() async {
    if (kIsWeb) {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No cameras found on this device.');
        return;
      }
      
      final XFile? capturedFile = await showDialog<XFile>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _WebCameraDialog(cameras: cameras),
      );

      if (capturedFile != null && mounted) {
        await _cropImage(capturedFile.path);
      }
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked != null && mounted) {
      await _cropImage(picked.path);
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null && mounted) {
      await _cropImage(picked.path);
    }
  }

  Future<void> _cropImage(String sourcePath) async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final isDark = context.read<ThemeProvider>().isDark;

      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Profile Photo',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF9E2016),
            backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
            dimmedLayerColor: Colors.black.withOpacity(0.8),
            cropStyle: CropStyle.circle,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            showCropGrid: false,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Edit Profile Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            cropStyle: CropStyle.circle,
            doneButtonTitle: 'Save',
            cancelButtonTitle: 'Cancel',
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 400, height: 400),
            translations: const WebTranslations(
              title: 'Align Photo',
              cropButton: 'Apply',
              cancelButton: 'Cancel',
              rotateLeftTooltip: 'Rotate Left',
              rotateRightTooltip: 'Rotate Right',
            ),
          ),
        ],
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (cropped != null) {
          Navigator.pop(context, cropped.path);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = 'Cropping failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    // This screen is used as a bottom sheet launcher — it shows the source picker
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D12) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Icon + title
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9E2016), Color(0xFFD63031)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF9E2016).withOpacity(0.4), blurRadius: 20)],
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 16),
          Text(
            'Update Profile Photo',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 6),
          Text(
            'Choose a source to pick your photo.\nYour photo will be cropped to a circle.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54, height: 1.5, letterSpacing: 0.2),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 32),

          // Camera button
          _SourceButton(
            icon: Icons.camera_alt_outlined,
            label: 'Take a Photo',
            subtitle: 'Use your camera',
            color: const Color(0xFF9E2016),
            isDark: isDark,
            onTap: _isProcessing ? null : _pickFromCamera,
            delay: 200,
          ),
          const SizedBox(height: 12),

          // Gallery button
          _SourceButton(
            icon: Icons.photo_library_outlined,
            label: 'Choose from Gallery',
            subtitle: 'Browse your photos',
            color: const Color(0xFF9E2016),
            isDark: isDark,
            onTap: _isProcessing ? null : _pickFromGallery,
            delay: 260,
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFF9E2016), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],

          if (_isProcessing) ...[
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Color(0xFF9E2016)),
          ],
        ],
      ),
    );
  }
}

class _WebCameraDialog extends StatefulWidget {
  final List<CameraDescription> cameras;
  const _WebCameraDialog({required this.cameras});

  @override
  State<_WebCameraDialog> createState() => _WebCameraDialogState();
}

class _WebCameraDialogState extends State<_WebCameraDialog> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // Try to find front camera
    CameraDescription selectedCamera = widget.cameras.first;
    for (var camera in widget.cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        selectedCamera = camera;
        break;
      }
    }
    
    _controller = CameraController(selectedCamera, ResolutionPreset.medium, enableAudio: false);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Take Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_controller);
                  } else {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF9E2016)));
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF9E2016),
                onPressed: () async {
                  try {
                    await _initializeControllerFuture;
                    final image = await _controller.takePicture();
                    if (mounted) Navigator.pop(context, image);
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;
  final int delay;
  const _SourceButton({required this.icon, required this.label, required this.subtitle,
      required this.color, required this.isDark, required this.onTap, required this.delay});

  @override
  State<_SourceButton> createState() => _SourceButtonState();
}

class _SourceButtonState extends State<_SourceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1A1A2A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDark 
                  ? Colors.white.withOpacity(0.08) 
                  : widget.color.withOpacity(0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.color.withOpacity(0.8), widget.color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: widget.isDark ? Colors.white : const Color(0xFF1A1A2E),
                  letterSpacing: 0.3,
                )),
                const SizedBox(height: 3),
                Text(widget.subtitle, style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? Colors.white54 : Colors.black45,
                  fontWeight: FontWeight.w500,
                )),
              ],
            )),
            Icon(Icons.arrow_forward_ios_rounded,
                color: widget.isDark ? Colors.white24 : Colors.black12, size: 16),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: widget.delay)).slideY(begin: 0.08);
  }
}
