// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../services/api_service.dart';
import '../../../products/domain/entities/product_entity.dart';

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
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ApiService.getProducts();
      if (mounted) {
        setState(() {
          _products = products;
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
      // For mock data, we'll just show a message and refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully (mock)'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchProducts();
      }
    } catch (e) {
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
                          if (_selectedImage != null) {
                            setDialogState(
                                () {}); // Trigger rebuild to show loading
                            final uploadedUrl =
                                await _uploadImage(_selectedImage!);
                            if (uploadedUrl == null) {
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

                            // For mock data, just show success message
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Product saved successfully (mock)'),
                                  backgroundColor: Colors.green,
                                ),
                              );
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
            Navigator.pushReplacementNamed(context, '/home');
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
