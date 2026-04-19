// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/services/currency_service.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/screens/home_screen.dart';

class AdminProductListScreen extends StatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<ProductEntity> _products = [];
  bool _isUploading = false;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    // Debug: Check all products and their references
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugCheckAllProducts();
    });
  }

  Future<void> _debugCheckAllProducts() async {
    try {
      debugPrint('=== DEBUG: Checking all products and their order references ===');
      
      // Get all products
      final products = await _supabase.from('products').select('id, name');
      
      for (final product in products) {
        final productId = product['id'];
        final productName = product['name'];
        
        // Check order references for each product
        final orderRefs = await _supabase
            .from('order_items')
            .select('order_id')
            .eq('product_id', productId);
        
        debugPrint('Product: $productName (ID: $productId) - References: ${orderRefs.length}');
        
        if (orderRefs.isNotEmpty) {
          debugPrint('  -> Referenced in orders: ${orderRefs.map((r) => r['order_id']).toList()}');
        }
      }
      
      debugPrint('=== DEBUG: End of product analysis ===');
    } catch (e) {
      debugPrint('Error in debug check: $e');
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('products')
          .select();
      final List<dynamic> data = response as List<dynamic>;

      if (mounted) {
        setState(() {
          _products = data.map((json) => ProductModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct(int id) async {
    try {
      debugPrint('=== Attempting to delete product ID: $id ===');
      
      // Try to use the safe_delete_product function first
      try {
        final result = await _supabase.rpc('safe_delete_product', params: {'product_id': id});
        debugPrint('RPC function result: $result');
        if (result == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Produit supprimé avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            _fetchProducts(); // Refresh list
          }
          return;
        }
      } catch (rpcError) {
        // RPC function not available, fall back to manual handling
        debugPrint('RPC function not available, using manual deletion: $rpcError');
      }

      // Always perform force delete directly without checking references
      debugPrint('Performing force delete for product $id');
      await _forceDeleteProductDirectly(id);
      
    } catch (e) {
      debugPrint('Error during deletion of product $id: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _forceDeleteProductDirectly(int id) async {
    try {
      debugPrint('Starting force delete for product $id');
      
      // First, try to delete all order_items references
      debugPrint('Deleting order items for product $id');
      final orderItemsDelete = await _supabase
          .from('order_items')
          .delete()
          .eq('product_id', id);
      
      debugPrint('Order items deleted: $orderItemsDelete');
      
      // Then delete the product
      debugPrint('Deleting product $id');
      final productDelete = await _supabase
          .from('products')
          .delete()
          .eq('id', id);
      
      debugPrint('Product deleted: $productDelete');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchProducts();
      }
    } catch (e) {
      debugPrint('Error in force delete: $e');
      
      // If it's still a foreign key error, try a different approach
      if (e.toString().contains('order_items_product_id_fkey')) {
        debugPrint('Foreign key constraint still active, trying alternative approach');
        
        try {
          // Try using raw SQL or different approach
          await _supabase.rpc('force_delete_product_with_dependencies', params: {'product_id': id});
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Produit supprimé avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            _fetchProducts();
          }
        } catch (rpcError) {
          debugPrint('RPC approach failed: $rpcError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete. Please contact system administrator.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Other type of error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    setState(() => _isUploading = true);
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final path = 'products/$fileName';

      final fileBytes = await image.readAsBytes();

      await _supabase.storage.from('product-images').uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(
                cacheControl: '3600', upsert: false, contentType: 'image/jpeg'),
          );

      final publicUrl =
          _supabase.storage.from('product-images').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during upload: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showAddEditProductDialog({ProductEntity? product}) {
    final isEditing = product != null;
    _selectedImage = null; // Reset selection
    final nameController = TextEditingController(text: product?.name ?? '');
    
    // Display price as DZD directly without conversion
    final displayPrice = product != null 
        ? CurrencyService.convertFromUSD(product.price).round().toString()
        : '';
    final priceController = TextEditingController(text: displayPrice);
    
    final descController =
        TextEditingController(text: product?.description ?? '');
    final categoryController =
        TextEditingController(text: product?.category ?? '');

    showDialog(
      context: context,
      barrierDismissible: !_isUploading,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: Text(
                  isEditing ? 'Edit Product' : 'Add Product',
                  style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(nameController, 'Name'),
                    const SizedBox(height: 10),
                    _buildTextField(priceController, 'Price (DA)',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true)),
                    const SizedBox(height: 10),
                    _buildTextField(descController, 'Description', maxLines: 3),
                    const SizedBox(height: 10),
                    _buildTextField(categoryController,
                        'Category (e.g., Sport, Luxury, Fitness)'),
                    const SizedBox(height: 15),
                    Column(
                      children: [
                        if (_selectedImage != null ||
                            (isEditing && product.image.isNotEmpty))
                          Container(
                            height: 150,
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withOpacity(0.05),
                              image: _selectedImage != null
                                  ? DecorationImage(
                                      image: kIsWeb
                                          ? NetworkImage(_selectedImage!.path)
                                          : FileImage(
                                                  File(_selectedImage!.path))
                                              as ImageProvider,
                                      fit: BoxFit.contain,
                                    )
                                  : DecorationImage(
                                      image: NetworkImage(product!.image),
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: _isUploading
                              ? null
                              : () async {
                                  final XFile? image = await _picker.pickImage(
                                      source: ImageSource.gallery);
                                  if (image != null) {
                                    setDialogState(() {
                                      _selectedImage = image;
                                    });
                                  }
                                },
                          icon: const Icon(Icons.image, color: Colors.white),
                          label: Text(
                            _selectedImage != null
                                ? 'Change Image'
                                : 'Select Image',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: _isUploading
                      ? null
                      : () async {
                          String imageUrl = isEditing ? product.image : '';

                          if (_selectedImage != null) {
                            setDialogState(
                                () {}); // Trigger rebuild to show loading
                            final uploadedUrl =
                                await _uploadImage(_selectedImage!);
                            if (uploadedUrl != null) {
                              imageUrl = uploadedUrl;
                            } else {
                              return; // Error handled in _uploadImage
                            }
                          }

                          try {
                            // Validate price first
                            double dzdPrice;
                            try {
                              dzdPrice = double.parse(priceController.text);
                              if (dzdPrice <= 0) {
                                throw Exception('Price must be greater than 0');
                              }
                            } catch (priceError) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(priceError.toString()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }

                            final data = {
                              'name': nameController.text,
                              'price': dzdPrice, // Save directly as DZD
                              'description': descController.text,
                              'category': categoryController.text,
                              'category_id': categoryController.text
                                      .toLowerCase()
                                      .contains('luxury')
                                  ? 2
                                  : categoryController.text
                                      .toLowerCase()
                                      .contains('fitness')
                                  ? 3
                                  : 1,
                              'image': imageUrl,
                            };

                            if (isEditing) {
                              await _supabase
                                  .from('products')
                                  .update(data)
                                  .eq('id', product.id);
                            } else {
                              await _supabase.from('products').insert(data);
                            }
                            
                            if (mounted) {
                              Navigator.pop(context);
                              _fetchProducts();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Error saving: $e')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      appBar: AppBar(
        title: const Text(
          'Manage Products',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(product.image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              CurrencyService.formatPrice(product.price),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showAddEditProductDialog(product: product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppTheme.cardColor,
                              title: const Text('Delete Product',
                                  style: TextStyle(color: Colors.white)),
                              content: const Text('Are you sure?',
                                  style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel',
                                      style: TextStyle(color: Colors.white54)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteProduct(product.id);
                                  },
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditProductDialog(),
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
