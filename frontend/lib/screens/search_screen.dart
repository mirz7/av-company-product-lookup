import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isSearching = false;
  bool _loadingFrequent = true;
  Map<String, dynamic>? _productData;
  String? _errorMessage;
  List<Map<String, dynamic>> _frequentProducts = [];

  // Lighter gradient — still dark/red but not pitch-black
  static const List<Color> _bgGradient = [
    Color(0xFF1E1E2E), // deep charcoal-blue (not pure black)
    Color(0xFF2D1010), // muted dark red
    Color(0xFFB22A1A), // slightly brighter red at bottom
  ];

  @override
  void initState() {
    super.initState();
    _loadFrequent();
  }

  Future<void> _loadFrequent() async {
    final products = await _apiService.getFrequentProducts();
    if (mounted) setState(() { _frequentProducts = products; _loadingFrequent = false; });
  }

  Future<void> _searchProduct() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() { _isSearching = true; _errorMessage = null; _productData = null; });
    final data = await _apiService.getProduct(query);
    if (mounted) setState(() {
      _isSearching = false;
      if (data != null) { _productData = data; }
      else { _errorMessage = 'No product matched "$query". Double-check the code.'; }
    });
  }

  Future<void> _scanBarcode() async {
    var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SimpleBarcodeScannerPage()));
    if (res is String && res != '-1') {
      _searchController.text = res;
      _searchProduct();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: _bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
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

                      if (_productData != null) ...[
                        _buildSectionLabel('SEARCH RESULT', badge: '1 Match Found'),
                        const SizedBox(height: 12),
                        _buildProductCard(_productData!, isSearchResult: true),
                      ],

                      if (_productData == null && !_isSearching && _errorMessage == null) ...[
                        _buildSectionLabel('FREQUENTLY SEARCHED'),
                        const SizedBox(height: 12),
                        _loadingFrequent
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B6B)))
                            : _frequentProducts.isEmpty
                                ? Center(child: Text('No products yet', style: TextStyle(color: Colors.white.withOpacity(0.3))))
                                : Column(
                                    children: _frequentProducts.asMap().entries.map((entry) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: GestureDetector(
                                          onTap: () {
                                            _searchController.text = entry.value['product_code'] ?? '';
                                            _searchProduct();
                                          },
                                          child: _buildProductCard(entry.value, delay: entry.key * 80),
                                        ),
                                      );
                                    }).toList(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
              ),
              child: Image.asset('assets/images/logo.png', height: 26, errorBuilder: (c, e, s) => const Icon(Icons.business, size: 26)),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AV & COMPANY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                Text('Retail Hub', style: TextStyle(fontSize: 11, color: Colors.white38, letterSpacing: 0.5)),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF9E2016), Color(0xFFB22A1A)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: const Color(0xFF9E2016).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                alignment: Alignment.center,
                child: const Text('Product Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _scanBarcode,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.qr_code_scanner, size: 16, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 6),
                    Text('Barcode Scan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5))),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSearchField() {
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                decoration: InputDecoration(
                  hintText: 'e.g. CF-9021',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 20, fontWeight: FontWeight.w700),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onSubmitted: (_) => _searchProduct(),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.4), size: 20),
                onPressed: () {
                  _searchController.clear();
                  setState(() { _productData = null; _errorMessage = null; });
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
                child: const Text('Go', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildSectionLabel(String label, {String? badge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: const Color(0xFFFF6B6B), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.45), letterSpacing: 1.5)),
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
    final name = data['name']?.isNotEmpty == true ? data['name'] : data['product_code'] ?? 'Product';
    final code = data['product_code'] ?? '';
    final price = data['price']?.toString() ?? '—';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isSearchResult ? 0.1 : 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(isSearchResult ? 0.18 : 0.1)),
            boxShadow: isSearchResult ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))] : null,
          ),
          child: Column(children: [
            // Top accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF9E2016), Color(0xFFFF6B6B)]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                      Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                        child: Text(code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6), letterSpacing: 0.5)),
                      ),
                    ]),
                  ),
                  // Price
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('\$$price', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('RETAIL', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.3), letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    ).animate().fade(delay: Duration(milliseconds: delay), duration: 350.ms).slideY(begin: 0.06, delay: Duration(milliseconds: delay));
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: 0,
        selectedItemColor: const Color(0xFFFF6B6B),
        unselectedItemColor: Colors.white30,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 1.0),
        onTap: (index) {
          if (index == 1) Navigator.pushReplacementNamed(context, '/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'SEARCH'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'PROFILE'),
        ],
      ),
    );
  }
}
