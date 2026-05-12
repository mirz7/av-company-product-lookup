import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isSearching = false;
  bool _isCameraMode = false;
  MobileScannerController? _cameraController;
  List<Map<String, dynamic>>? _products;
  String? _errorMessage;
  int _totalProductsInDb = 0;
  // Price access flags — refreshed from server on each profile load
  bool _canSeeExtendedPrices = false; // Price B + C

  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
    _fetchTotalProducts();
  }

  Future<void> _fetchTotalProducts() async {
    final profile = await _apiService.getProfile();
    if (mounted && profile != null) {
      setState(() {
        _totalProductsInDb = profile['total_products'] ?? 0;
        // price_level >= 2 means the admin granted wholesale/discount (Price B+C)
        final level = profile['price_level'] ?? 1;
        _canSeeExtendedPrices = level >= 2;
      });
    }
  }

  Future<void> _loadInitialProducts() async {
    setState(() { _isSearching = true; });
    final data = await _apiService.searchProducts("");
    if (mounted) setState(() {
      _isSearching = false;
      _products = data;
    });
  }

  Future<void> _searchProduct() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _loadInitialProducts();
      return;
    }
    
    // Background increment for searches today
    _apiService.incrementSearchCount();
    
    setState(() { _isSearching = true; _errorMessage = null; _products = null; });
    final data = await _apiService.searchProducts(query);
    if (mounted) setState(() {
      _isSearching = false;
      if (data != null && data.isNotEmpty) { _products = data; }
      else { _errorMessage = 'No products matched "$query".'; }
    });
  }

  Future<void> _scanBarcode() async {}

  void _activateCameraMode() {
    setState(() { _isCameraMode = true; });
    _cameraController = MobileScannerController();
  }

  void _deactivateCameraMode() {
    _cameraController?.dispose();
    _cameraController = null;
    setState(() { _isCameraMode = false; });
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue != null && rawValue.isNotEmpty) {
      _deactivateCameraMode();
      _searchController.text = rawValue;
      _searchProduct();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bgColors = isDark
        ? [AppTheme.darkSurface, AppTheme.darkBg2, const Color(0xFF2A0D0D)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFEAD4CC)];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2A0D0D) : const Color(0xFFEAD4CC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTabBar(),
                      const SizedBox(height: 20),
                      _buildSearchField(),
                      const SizedBox(height: 24),

                      if (_isSearching)
                        const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B6B))).animate().fadeIn(),

                      if (_errorMessage != null)
                        _buildErrorBanner(_errorMessage!),

                      if (_products != null && _products!.isNotEmpty) ...[
                        _buildSectionLabel(
                          _searchController.text.isEmpty ? 'PRODUCTS' : 'SEARCH RESULTS', 
                          badge: _searchController.text.isEmpty 
                              ? (_totalProductsInDb > 0 ? '$_totalProductsInDb Total' : '${_products!.length} Found')
                              : '${_products!.length} Found'
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _products!.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildProductCard(_products![index], isSearchResult: _searchController.text.isNotEmpty, delay: index * 50);
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar() {
    final isDark = context.read<ThemeProvider>().isDark;
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final subTextColor = isDark ? Colors.white54 : AppTheme.lightSubText;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('assets/images/logo.png', height: 38, width: 38, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.business, size: 38, color: Color(0xFF9E2016))),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AV & Company', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)),
                Text('Retail Hub', style: TextStyle(fontSize: 11, color: subTextColor, letterSpacing: 0.5)),
              ],
            ),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFB22A1A).withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.4)),
            ),
            child: const Row(children: [
              Icon(Icons.search_rounded, color: Color(0xFFFF6B6B), size: 14),
              SizedBox(width: 6),
              Text('SEARCH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B), letterSpacing: 1.5)),
            ]),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildTabBar() {
    final isDark = context.read<ThemeProvider>().isDark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Stack(
            children: [
              // Sliding Pill Background
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: _isCameraMode ? Alignment.centerRight : Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9E2016), Color(0xFFB22A1A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9E2016).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () { if (_isCameraMode) _deactivateCameraMode(); },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        child: Text(
                          'Product Code',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: !_isCameraMode ? Colors.white : (isDark ? Colors.white.withOpacity(0.4) : AppTheme.silverDark),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () { if (!_isCameraMode) _activateCameraMode(); },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 16,
                              color: _isCameraMode ? Colors.white : (isDark ? Colors.white.withOpacity(0.4) : AppTheme.silverDark),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Barcode Scan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _isCameraMode ? Colors.white : (isDark ? Colors.white.withOpacity(0.4) : AppTheme.silverDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final isDark = context.read<ThemeProvider>().isDark;
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final subTextColor = isDark ? Colors.white54 : AppTheme.lightSubText;
    final borderColor = isDark ? Colors.white.withOpacity(0.15) : AppTheme.lightBorder;
    if (_isCameraMode) {
      // Inline camera view for barcode scanning
      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        height: 260,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Camera feed
              MobileScanner(
                controller: _cameraController!,
                onDetect: _onBarcodeDetected,
              ),
              // Scan overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Scan target box - 85% width
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boxW = constraints.maxWidth * 0.85;
                    final boxH = boxW * 0.48;
                    return Center(
                      child: Container(
                        width: boxW,
                        height: boxH,
                        decoration: BoxDecoration(
                          // border removed to keep only corner accents
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Stack(
                          children: [
                            Positioned(top: -1, left: -1, child: _cornerAccent()),
                            Positioned(top: -1, right: -1, child: Transform.rotate(angle: 1.5708, child: _cornerAccent())),
                            Positioned(bottom: -1, left: -1, child: Transform.rotate(angle: -1.5708, child: _cornerAccent())),
                            Positioned(bottom: -1, right: -1, child: Transform.rotate(angle: 3.1416, child: _cornerAccent())),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Scanning line - proportionate
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) => Center(
                    child: SizedBox(
                      width: constraints.maxWidth * 0.85,
                      child: const _ScanLine(),
                    ),
                  ),
                ),
              ),
              // Instructions
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Text(
                  'Point at a barcode to scan',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              // Top label
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: const Color(0xFFFF6B6B), size: 16),
                    const SizedBox(width: 6),
                    const Text('SCANNER ACTIVE', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05);
    }

    // Default text input
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20)],
          ),
          child: Row(children: [
            const Padding(padding: EdgeInsets.all(16.0), child: Icon(Icons.search_rounded, color: Color(0xFFFF6B6B), size: 24)),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor, letterSpacing: 0.5),
                decoration: InputDecoration(
                  hintText: 'Search by name or code...',
                  hintStyle: TextStyle(color: subTextColor.withOpacity(0.45), fontSize: 17, fontWeight: FontWeight.w700),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onSubmitted: (_) => _searchProduct(),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close_rounded, color: subTextColor, size: 20),
                onPressed: () {
                  _searchController.clear();
                  setState(() { _errorMessage = null; });
                  _loadInitialProducts();
                },
              ),
            GestureDetector(
              onTap: _searchProduct,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF9E2016), Color(0xFFB22A1A)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: const Color(0xFF9E2016).withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Text('Go', style: TextStyle(color: isDark ? Colors.white : AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _cornerAccent() {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFFF6B6B), width: 3),
          left: BorderSide(color: Color(0xFFFF6B6B), width: 3),
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
      ),
    );
  }

  Widget _buildSectionLabel(String label, {String? badge}) {
    final isDark = context.read<ThemeProvider>().isDark;
    final subTextColor = isDark ? Colors.white54 : AppTheme.lightSubText;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: const Color(0xFFFF6B6B), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subTextColor, letterSpacing: 1.5)),
        ]),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF9E2016).withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF9E2016).withOpacity(0.5)),
            ),
            child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B))),
          ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data, {bool isSearchResult = false, int delay = 0}) {
    final isDark = context.read<ThemeProvider>().isDark;
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final subTextColor = isDark ? Colors.white54 : AppTheme.lightSubText;
    final name = data['name']?.isNotEmpty == true ? data['name'] : data['product_code'] ?? 'Product';
    final code = data['product_code'] ?? '';
    final price = data['price']?.toString() ?? '—';
    final priceA = data['price_1']?.toString() ?? '—';
    final priceB = data['price_2']?.toString() ?? '—';
    final priceC = data['price_3']?.toString() ?? '—';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(isSearchResult ? 0.1 : 0.07) : Colors.white.withOpacity(isSearchResult ? 0.92 : 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white.withOpacity(isSearchResult ? 0.18 : 0.1) : AppTheme.lightBorder),
            boxShadow: isSearchResult ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))] : null,
          ),
          child: Column(children: [
            // Top accent bar
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF9E2016), Color(0xFFFF6B6B)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 18, right: 18, top: 14, bottom: 10),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9E2016).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF9E2016).withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFFF6B6B), size: 22),
                  ),
                  const SizedBox(width: 14),
                  // Name + code
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          code,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.4),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  // Price
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('₹$price', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
                    Text('PRICE', style: TextStyle(fontSize: 9, color: subTextColor, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),
            // Only show divider and extended prices if access is granted
            if (_canSeeExtendedPrices) ...[
              // Divider
              Container(height: 1, color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.lightBorder),
              // Extended Prices Row (B and C)
              // Extended Prices Row (B and C)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: _buildPriceItem('Price B', priceB, center: true)),
                    Container(width: 1, height: 24, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                    Expanded(child: _buildPriceItem('Price C', priceC, center: true)),
                  ],
                ),
              ),
            ],
          ]),
        ),
      ),
    ).animate().fade(delay: Duration(milliseconds: delay > 500 ? 500 : delay), duration: 350.ms).slideY(begin: 0.06, delay: Duration(milliseconds: delay > 500 ? 500 : delay));
  }

  Widget _buildPriceItem(String label, String value, {bool center = false}) {
    final isDark = context.read<ThemeProvider>().isDark;
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final subTextColor = isDark ? Colors.white54 : AppTheme.lightSubText;
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: subTextColor, letterSpacing: 1.0)),
        const SizedBox(height: 2),
        Text('₹$value', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
      ],
    );
  }

  Widget _buildErrorBanner(String msg) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.search_off_rounded, color: Color(0xFFFF6B6B), size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13))),
          ]),
        ),
      ),
    ).animate().fadeIn().shake(hz: 3, offset: const Offset(4, 0));
  }

  Widget _buildBottomNav() {
    final isDark = context.read<ThemeProvider>().isDark;
    final navBg = isDark ? const Color(0xFF12121F) : AppTheme.lightSurface;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder;
    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.1), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: Row(
        children: [
          Expanded(
            child: _navItem(
              icon: Icons.search_rounded,
              label: 'SEARCH',
              isActive: true,
              onTap: () {},
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _navItem(
              icon: Icons.person_rounded,
              label: 'MY SPACE',
              isActive: false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const ProfileScreen(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required bool isActive, required VoidCallback onTap, required bool isDark}) {
    final color = isActive ? AppTheme.crimsonGlow : (isDark ? Colors.white38 : AppTheme.silverDark);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.crimsonGlow.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

/// Animated horizontal scanning line for the barcode camera view
class _ScanLine extends StatefulWidget {
  const _ScanLine();

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _animation = Tween<double>(begin: -55, end: 55).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _animation.value),
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, const Color(0xFFFF6B6B).withOpacity(0.8), Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(1),
            boxShadow: [BoxShadow(color: const Color(0xFFFF6B6B).withOpacity(0.6), blurRadius: 6)],
          ),
        ),
      ),
    );
  }
}
