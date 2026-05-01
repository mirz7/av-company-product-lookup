import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearching = false;
  bool _isLoading = false;
  String? _productPrice;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _isSearching = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    final code = _searchController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _productPrice = null;
      _errorMessage = null;
    });

    _searchFocusNode.unfocus();

    final price = await _apiService.getProductPrice(code);

    setState(() {
      _isLoading = false;
      if (price != null) {
        _productPrice = price;
      } else {
        _errorMessage = 'Product not found.';
      }
    });
  }

  Future<void> _handleLogout() async {
    await _apiService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Hero(
          tag: 'app_logo',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_rounded, color: Color(0xFF00E5FF)),
              SizedBox(width: 8),
              Text(
                'Product Search',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Animated Search Bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: _isSearching
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.9)
                    : Theme.of(context).colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: _isSearching
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Enter product code...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
                onSubmitted: (_) => _handleSearch(),
                onChanged: (_) => setState(() {}),
              ),
            ).animate().slideY(begin: -0.5, curve: Curves.easeOutCubic).fade(),

            const SizedBox(height: 32),

            // Search Button (if not using keyboard enter)
            if (_searchController.text.isNotEmpty)
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ).animate().fade().slideY(begin: 0.2),

            const SizedBox(height: 32),

            // Results Area
            Expanded(
              child: Center(
                child: _buildResultArea(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    if (_isLoading) {
      return _buildSkeletonLoader();
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.redAccent.shade200),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
      ).animate().fade().scale(curve: Curves.elasticOut, duration: 800.ms);
    }

    if (_productPrice != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Price',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '\$$_productPrice',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ).animate().fade(duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic);
    }

    // Default state
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.qr_code_scanner, size: 80, color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 16),
        Text(
          'Ready to search',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
        ),
      ],
    ).animate().fade(duration: 800.ms);
  }

  Widget _buildSkeletonLoader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 150,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1500.ms, color: Colors.white24);
  }
}
