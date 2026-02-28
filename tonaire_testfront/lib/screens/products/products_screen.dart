import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _perPage = 20;

  String _search = '';
  int? _selectedCategoryId;
  String _sortBy = 'name';
  String _sortOrder = 'ASC';

  Timer? _debounce;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchProducts(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _fetchCategories() async {
    final result = await ApiService.getCategories();
    if (result['success']) {
      setState(() => _categories = List<Map<String, dynamic>>.from(result['data']['data']));
    }
  }

  Future<void> _fetchProducts({bool reset = false}) async {
    if (reset) {
      setState(() { _products = []; _currentPage = 1; _hasMore = true; _loading = true; });
    }

    final result = await ApiService.getProducts(
      search: _search,
      categoryId: _selectedCategoryId,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
      page: reset ? 1 : _currentPage,
      limit: _perPage,
    );

    if (result['success']) {
      final data = result['data'];
      final newProducts = List<Map<String, dynamic>>.from(data['data']);
      final pagination = data['pagination'];
      setState(() {
        if (reset) {
          _products = newProducts;
          _currentPage = 1;
        } else {
          _products.addAll(newProducts);
        }
        _hasMore = _currentPage < (pagination['total_pages'] ?? 1);
        _loading = false;
        _loadingMore = false;
      });
    } else {
      setState(() { _loading = false; _loadingMore = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() { _loadingMore = true; _currentPage++; });
    await _fetchProducts();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _search = value);
      _fetchProducts(reset: true);
    });
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final descCtrl = TextEditingController(text: product?['description'] ?? '');
    final priceCtrl = TextEditingController(text: product?['price']?.toString() ?? '');
    int? selectedCatId = product?['category_id'];
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product == null ? 'Add Product' : 'Edit Product',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Product Name (English or Khmer)', prefixIcon: Icon(Icons.label_outlined)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.description_outlined)),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price (\$)', prefixIcon: Icon(Icons.attach_money)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Price is required';
                      if (double.tryParse(v) == null) return 'Invalid price';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedCatId,
                    decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                    items: _categories.map((c) => DropdownMenuItem<int>(
                      value: c['id'],
                      child: Text(c['name'], overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setModalState(() => selectedCatId = v),
                    validator: (v) => v == null ? 'Category is required' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => saving = true);
                            Map<String, dynamic> result;
                            if (product == null) {
                              result = await ApiService.createProduct(
                                name: nameCtrl.text,
                                categoryId: selectedCatId!,
                                price: double.parse(priceCtrl.text),
                                description: descCtrl.text,
                              );
                            } else {
                              result = await ApiService.updateProduct(
                                product['id'],
                                name: nameCtrl.text,
                                categoryId: selectedCatId!,
                                price: double.parse(priceCtrl.text),
                                description: descCtrl.text,
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (result['success']) {
                              _fetchProducts(reset: true);
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['error']), backgroundColor: AppTheme.error),
                                );
                              }
                            }
                          },
                    child: saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(product == null ? 'Add Product' : 'Save Changes', style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await ApiService.deleteProduct(product['id']);
      if (result['success']) {
        _fetchProducts(reset: true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filters section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search products... / ស្វែងរក...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _onSearchChanged(''); })
                        : null,
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                // Filter row
                Row(
                  children: [
                    // Category dropdown
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _selectedCategoryId,
                            hint: const Text('All Categories', style: TextStyle(fontSize: 13)),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('All Categories', style: TextStyle(fontSize: 13))),
                              ..._categories.map((c) => DropdownMenuItem<int?>(
                                value: c['id'],
                                child: Text(c['name'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                              )),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedCategoryId = v);
                              _fetchProducts(reset: true);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort by
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'name', child: Text('Name', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'price', child: Text('Price', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (v) {
                              setState(() => _sortBy = v!);
                              _fetchProducts(reset: true);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort order
                    GestureDetector(
                      onTap: () {
                        setState(() => _sortOrder = _sortOrder == 'ASC' ? 'DESC' : 'ASC');
                        _fetchProducts(reset: true);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _sortOrder == 'ASC' ? Icons.arrow_upward : Icons.arrow_downward,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Product list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              _search.isEmpty ? 'No products yet' : 'No products found',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _fetchProducts(reset: true),
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _products.length) {
                              return const Center(child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ));
                            }
                            final p = _products[i];
                            return _ProductCard(
                              product: p,
                              onEdit: () => _showProductDialog(product: p),
                              onDelete: () => _deleteProduct(p),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['image_url'] != null
        ? '${ApiService.baseUrl.replaceAll('//', '//').replaceAll('/auth', '')}${product['image_url']}'
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: SizedBox(
              width: 90,
              height: 90,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (product['category_name'] != null)
                    Text(product['category_name'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '\$${double.tryParse(product['price'].toString())?.toStringAsFixed(2) ?? product['price']}',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Column(
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20), onPressed: onEdit),
              IconButton(icon: const Icon(Icons.delete_outlined, color: AppTheme.error, size: 20), onPressed: onDelete),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey.shade100,
    child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 32)),
  );
}
