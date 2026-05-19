import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/product_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final ProductService _svc = ProductService();
  bool _loading = false, _cameraMode = false;
  MobileScannerController? _cam;
  List<Map<String, dynamic>>? _products;
  String? _error;
  int _total = 0;

  @override
  void initState() { super.initState(); _load(''); }

  Future<void> _load(String q) async {
    setState(() { _loading = true; _error = null; });
    final d = await _svc.searchProductsRaw(q);
    if (mounted) {
      setState(() { 
        _loading = false; 
        _products = d; 
        if (q.isEmpty) _total = d?.length ?? 0; 
        else if (d == null || d.isEmpty) _error = 'No products matched "$q".'; 
      });
    }
  }

  void _activateCam() { setState(() => _cameraMode = true); _cam = MobileScannerController(); }
  void _deactivateCam() { _cam?.dispose(); _cam = null; setState(() => _cameraMode = false); }
  void _onDetect(BarcodeCapture c) {
    final v = c.barcodes.first.rawValue;
    if (v != null && v.isNotEmpty) { _deactivateCam(); _ctrl.text = v; _load(v); }
  }

  @override
  void dispose() { _ctrl.dispose(); _cam?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF2D1010)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFCFBBAA)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final card = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.8);
    final border = isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder;
    final hint = isDark ? Colors.white54 : AppTheme.lightSubText.withOpacity(0.6);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2D1010) : const Color(0xFFCFBBAA),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: bg, begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.5, 1.0])),
        child: SafeArea(child: Column(children: [
          // AppBar
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                height: 42, width: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Center(child: Text('AV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)))),
                ),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AV & COMPANY', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 2.0)),
                const SizedBox(height: 1),
                Text('Product Search', style: TextStyle(fontSize: 11, color: sub, letterSpacing: 0.5)),
              ]),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.search_rounded, color: AppTheme.primaryGlow, size: 14),
                const SizedBox(width: 6),
                Text('SEARCH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGlow, letterSpacing: 1.5)),
              ]),
            ),
          ])).animate().fadeIn(delay: 100.ms),

          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Tab bar
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                  child: Row(children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _cameraMode ? _deactivateCam : null,
                          borderRadius: BorderRadius.circular(10),
                          splashColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.12),
                          child: AnimatedContainer(
                            duration: 300.ms, curve: Curves.easeInOut, padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: !_cameraMode ? const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]) : null,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !_cameraMode ? [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))] : null
                            ),
                            alignment: Alignment.center,
                            child: Text('Product Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: !_cameraMode ? Colors.white : sub)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _cameraMode ? null : _activateCam,
                          borderRadius: BorderRadius.circular(10),
                          splashColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.12),
                          child: AnimatedContainer(
                            duration: 300.ms, curve: Curves.easeInOut, padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: _cameraMode ? const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]) : null,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _cameraMode ? [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))] : null
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner, size: 16, color: _cameraMode ? Colors.white : sub),
                                const SizedBox(width: 6),
                                Text('Barcode Scan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _cameraMode ? Colors.white : sub)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 20),
            // Search / Camera
            if (_cameraMode)
              AnimatedContainer(duration: 400.ms, curve: Curves.easeInOut, height: 260, child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(children: [
                MobileScanner(controller: _cam!, onDetect: _onDetect),
                Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.4)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                Positioned(top: 12, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.qr_code_scanner, color: AppTheme.primaryGlow, size: 16), const SizedBox(width: 6), Text('SCANNER ACTIVE', style: TextStyle(color: AppTheme.primaryGlow, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5))])),
                Positioned(bottom: 24, left: 0, right: 0, child: Text('Point at a barcode to scan', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              ]))).animate().fadeIn(duration: 350.ms)
            else
              ClipRRect(borderRadius: BorderRadius.circular(16), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                child: Row(children: [
                  const Padding(padding: EdgeInsets.all(16), child: Icon(Icons.search_rounded, color: AppTheme.primary, size: 24)),
                  Expanded(child: TextField(controller: _ctrl, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
                    decoration: InputDecoration(hintText: 'Search by name or code...', hintStyle: TextStyle(color: hint, fontSize: 16, fontWeight: FontWeight.w500), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 18)),
                    onSubmitted: (v) => _load(v), onChanged: (_) => setState(() {}))),
                  if (_ctrl.text.isNotEmpty) IconButton(icon: Icon(Icons.close_rounded, color: sub, size: 20), onPressed: () { _ctrl.clear(); setState(() => _error = null); _load(''); }),
                  Material(color: Colors.transparent, child: InkWell(onTap: () => _load(_ctrl.text.trim()), borderRadius: BorderRadius.circular(12), splashColor: Colors.white.withOpacity(0.2), child: Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]),
                    child: const Text('Go', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))))),
                ]),
              ))).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator(color: AppTheme.primary)).animate().fadeIn(),
            if (_error != null)
              ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.danger.withOpacity(0.2))),
                child: Row(children: [Icon(Icons.search_off_rounded, color: AppTheme.danger, size: 20), const SizedBox(width: 12), Expanded(child: Text(_error!, style: TextStyle(color: AppTheme.danger, fontSize: 13)))]),
              ))).animate().fadeIn().shake(hz: 3, offset: const Offset(4, 0)),
            if (_products != null && _products!.isNotEmpty) ...[
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Text(_ctrl.text.isEmpty ? 'PRODUCTS' : 'SEARCH RESULTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sub, letterSpacing: 1.5))]),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
                  child: Text(_ctrl.text.isEmpty ? '$_total Total' : '${_products!.length} Found', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGlow))),
              ]),
              const SizedBox(height: 12),
              ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _products!.length, separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => _card(_products![i], textColor, sub, card, border, isDark, _ctrl.text.isNotEmpty, i * 50)),
            ],
            const SizedBox(height: 16),
          ]))),
        ])),
      ),
    );
  }

  Widget _card(Map<String, dynamic> d, Color textColor, Color sub, Color card, Color border, bool isDark, bool isResult, int delay) {
    final name = d['name']?.isNotEmpty == true ? d['name'] : d['product_code'] ?? 'Product';
    final code = d['product_code'] ?? '';
    final price = d['price']?.toString() ?? '—';
    final pA = d['price_1']?.toString() ?? '—';
    final pB = d['price_2']?.toString() ?? '—';
    final pC = d['price_3']?.toString() ?? '—';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showProductDetails(d),
        borderRadius: BorderRadius.circular(18),
        splashColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.12),
        child: ClipRRect(borderRadius: BorderRadius.circular(18), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: isResult ? AppTheme.primary.withOpacity(0.25) : border), boxShadow: isResult ? [BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))] : null),
        child: Column(children: [
          Container(height: 4, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryGlow]), borderRadius: const BorderRadius.vertical(top: Radius.circular(18)))),
          Padding(padding: const EdgeInsets.only(left: 18, right: 18, top: 14, bottom: 10), child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primary.withOpacity(0.25))), child: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGlow, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBg3, borderRadius: BorderRadius.circular(6)), child: Text(code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sub, letterSpacing: 0.5))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('₹$price', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)), Text('PRICE', style: TextStyle(fontSize: 9, color: sub, letterSpacing: 1.5, fontWeight: FontWeight.bold))]),
          ])),
          Container(height: 1, color: border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Tap for details', style: TextStyle(fontSize: 10, color: sub)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: sub),
              ],
            ),
          ),
        ]),
      ))),
      ),
    ).animate().fade(delay: Duration(milliseconds: delay > 500 ? 500 : delay), duration: 350.ms).slideY(begin: 0.06, delay: Duration(milliseconds: delay > 500 ? 500 : delay));
  }

  void _showProductDetails(Map<String, dynamic> data) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
        final name = data['name']?.isNotEmpty == true ? data['name'] : data['product_code'] ?? 'Product';
        final code = data['product_code'] ?? '';
        final price = data['price']?.toString() ?? '—';
        final priceB = data['price_2']?.toString() ?? '—';
        final priceC = data['price_3']?.toString() ?? '—';
        
        final sheetBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
        final textColor = isDark ? Colors.white : AppTheme.lightText;
        final subTextColor = isDark ? Colors.white54 : AppTheme.lightSubText;

        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: FadeTransition(
                opacity: animation,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 40),
                    decoration: BoxDecoration(
                      color: sheetBg,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, -5))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(10)))),
                        Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8)), child: Text(code, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: subTextColor, letterSpacing: 0.5))),
                        const SizedBox(height: 36),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('PRICE', style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            Text('₹$price', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppTheme.primaryGlow)),
                          ]),
                        ]),
                        const SizedBox(height: 28),
                        Container(height: 1, color: isDark ? Colors.white12 : AppTheme.lightBorder),
                        const SizedBox(height: 28),
                        Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('PRICE B', style: TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            const SizedBox(height: 6),
                            Text('₹$priceB', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textColor)),
                          ])),
                          Container(width: 1, height: 44, color: isDark ? Colors.white12 : AppTheme.lightBorder),
                          const SizedBox(width: 24),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('PRICE C', style: TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            const SizedBox(height: 6),
                            Text('₹$priceC', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textColor)),
                          ])),
                        ]),
                        const SizedBox(height: 40),
                        SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: AppTheme.primary.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pi(String label, String val, Color textColor, Color sub, {CrossAxisAlignment align = CrossAxisAlignment.start}) => Column(crossAxisAlignment: align, children: [
    Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: sub, letterSpacing: 1.0)),
    const SizedBox(height: 2),
    Text('₹$val', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
  ]);
}
