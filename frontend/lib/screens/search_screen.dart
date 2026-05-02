import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _productData;
  String? _errorMessage;

  final String logoUrl = "https://lh3.googleusercontent.com/aida/ADBb0uh8CTvSHI_1-5xL4Ew7J-ycSYCb46Rbl2EAWU3AhWrvKJaAa4WwqVqZRdcMcnwBwmOQ_qdNfzXwX0T04Sx2eL-aNI50UTkBZL4pjn6yP9m0eN-nJm-aNtOXefV_VXmd3yPyDOCov9N3siIDOqiYG3A8o8leP_9RDe6ZP_SVF95LPAFV12p2K_hfw_16HkNnsrgoP5hvP2STLjtq8le4Hnj-RXTVr0bZYYfuXVULFQANlsDDyhwIFHTKcsQGm04TGMYTBnj-QcCBLg";
  final String profileUrl = "https://lh3.googleusercontent.com/aida-public/AB6AXuBjIB_rkYSsAnFjFrjEDpiI1HKMF2CuQ2iR8jgNnl7hwJbiIYvOucnbbJWDAWcXlTk1UF3hx-N0SgtnPj9hCDYZWyhRlqvOCX8HdfbQCiRNaBgf-jMdqMnDor1wyrjlTf2OAhmStXVsgrPhR8cLqaDJmsy3uhGMWWbhlEo4r7QKzE2O1RF4IB8rwLFRn69_V1Pbqx164OgrzCFHH2b3fpP9ogoe2CsrJSbaXC_hLzULhBz-wSrDe00CgvjPsrV02kQb2J0QX25JFvQ";

  Future<void> _searchProduct() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _productData = null;
    });

    final data = await _apiService.getProduct(query);
    setState(() {
      _isLoading = false;
      if (data != null) {
        _productData = data;
      } else {
        _errorMessage = "Product not found or session expired. Please login again.";
      }
    });
  }

  Future<void> _scanBarcode() async {
    var res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleBarcodeScannerPage(),
      ),
    );
    if (res is String && res != '-1') {
      _searchController.text = res;
      _searchProduct();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F9), // surface-bright
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/logo.png', height: 32, errorBuilder: (c,e,s) => const Icon(Icons.business)),
                      const SizedBox(width: 12),
                      const Text(
                        'AV & COMPANY',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF091D2E), letterSpacing: -1.0),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF9E2016).withOpacity(0.2), width: 2),
                      image: DecorationImage(
                        image: NetworkImage(profileUrl),
                        fit: BoxFit.cover,
                      )
                    ),
                  )
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE1BFB9).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                              ),
                              alignment: Alignment.center,
                              child: const Text('Product Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9E2016))),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: _scanBarcode,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.qr_code_scanner, size: 16, color: Color(0xFF4E6073)),
                                    SizedBox(width: 8),
                                    Text('Barcode Scan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4E6073))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Search Field
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            border: const Border(bottom: BorderSide(color: Color(0xFF9E2016), width: 2)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Icon(Icons.search, color: Color(0xFF4E6073)),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF191C1C)),
                                  decoration: const InputDecoration(
                                    hintText: 'CF-9021',
                                    hintStyle: TextStyle(color: Color(0xFFD9DADA)),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  onSubmitted: (_) => _searchProduct(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Color(0xFF4E6073)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _productData = null;
                                    _errorMessage = null;
                                  });
                                },
                              )
                            ],
                          ),
                        ),
                        Positioned(
                          top: -8,
                          left: 12,
                          child: Container(
                            color: const Color(0xFFF8F9F9),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: const Text('ENTRY FIELD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9E2016), letterSpacing: 1.5)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (_isLoading)
                      const Center(child: CircularProgressIndicator(color: Color(0xFF9E2016))),

                    if (_errorMessage != null)
                      Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                        ),
                      ).animate().fade().slideY(begin: 0.1),

                    if (_productData != null)
                      _buildResultCard(_productData!),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              currentIndex: 0,
              selectedItemColor: const Color(0xFF9E2016),
              unselectedItemColor: const Color(0xFF4E6073),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
              onTap: (index) {
                if (index == 1) {
                  Navigator.pushReplacementNamed(context, '/profile');
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.search), label: 'SEARCH'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('SEARCH RESULT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4E6073), letterSpacing: 1.5)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF9E2016).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('1 Match Found', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9E2016))),
            )
          ],
        ),
        const SizedBox(height: 16),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: const Color(0xFF2C3E50).withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Column(
                children: [
                  Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF9E2016), Color(0xFFC0392B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'Product Name',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF191C1C), height: 1.2),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text('SKU: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4E6073))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFFEDEEEE), borderRadius: BorderRadius.circular(4)),
                                        child: Text(data['code'] ?? 'Unknown', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF191C1C))),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFF9E2016).withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.inventory_2, color: Color(0xFF9E2016), size: 32),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE1BFB9).withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(color: const Color(0xFF9E2016).withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.sell, color: Color(0xFF9E2016), size: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('RETAIL PRICE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4E6073))),
                                ],
                              ),
                              Text('\$${data['price']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF191C1C))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFFE1BFB9), height: 1, thickness: 0.3),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF9E2016), Color(0xFFC0392B)]),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: const Color(0xFF9E2016).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Add to Cart', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE1BFB9).withOpacity(0.5), width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.more_horiz, color: Color(0xFF4E6073)),
                                onPressed: () {},
                              ),
                            )
                          ],
                        )

                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1);
  }
}
