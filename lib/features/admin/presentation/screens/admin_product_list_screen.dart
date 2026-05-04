// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/security/rate_limiter.dart';
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
  List<String> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await ApiService.getCategories();
      debugPrint('Categories loaded: ${categories.length} - $categories');
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading categories: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isLoadingCategories = false);
      }
    }
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
      final success = await ApiService.deleteProduct(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete product'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    final productId = product?.id;
    _selectedImage = null; // Reset selection
    final nameController = TextEditingController(text: product?.name ?? '');

    // Display price as DZD directly without conversion
    final displayPrice = product != null
        ? CurrencyService.convertFromUSD(product.price).round().toString()
        : '';
    final priceController = TextEditingController(text: displayPrice);

    final descController =
        TextEditingController(text: product?.description ?? '');
    String? _selectedCategory = product?.category;
    bool _isAvailable = product?.isAvailable ?? true;

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
                    _buildCategoryDropdown(_selectedCategory, (value) {
                      setDialogState(() {
                        _selectedCategory = value;
                      });
                    }),
                    const SizedBox(height: 15),
                    // Availability Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isAvailable ? Icons.check_circle : Icons.cancel,
                                color: _isAvailable ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Available',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: (value) {
                              setDialogState(() {
                                _isAvailable = value;
                              });
                            },
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                          ),
                        ],
                      ),
                    ),
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
                          String? uploadedUrl;
                          if (_selectedImage != null) {
                            setDialogState(
                                () {}); // Trigger rebuild to show loading
                            uploadedUrl = await _uploadImage(_selectedImage!);
                            if (uploadedUrl == null) {
                              return; // Error handled in _uploadImage
                            }
                          }

                          try {
                            // Sanitize inputs
                            final sanitizedName = InputSanitizer.sanitizeString(nameController.text.trim(), maxLength: 200);
                            final sanitizedDescription = InputSanitizer.sanitizeString(descController.text.trim(), maxLength: 2000);
                            
                            // Validate inputs
                            if (sanitizedName.isEmpty || sanitizedName.length < 2) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Product name must be at least 2 characters'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }
                            
                            if (_selectedCategory == null || _selectedCategory!.isEmpty) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a category'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }
                            
                            // Validate price first
                            double dzdPrice;
                            try {
                              final sanitizedPrice = InputSanitizer.sanitizeNumeric(priceController.text.trim());
                              dzdPrice = double.parse(sanitizedPrice);
                              if (dzdPrice <= 0) {
                                throw Exception('Price must be greater than 0');
                              }
                              if (dzdPrice > 999999999) {
                                throw Exception('Price is too high');
                              }
                            } catch (priceError) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Invalid price: ${priceError.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }
                            
                            // Rate limiting check for admin operations
                            if (!RateLimiters.api.isAllowed('admin_product_save')) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Too many product operations. Please try again later.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              return;
                            }

                            // Convert DZD price to USD for storage
                            final usdPrice = CurrencyService.convertToUSD(dzdPrice);

                            // Prepare image URL
                            String imageUrl = product?.image ?? '';
                            if (_selectedImage != null && uploadedUrl != null) {
                              imageUrl = uploadedUrl;
                            }

                            // Save or update product to Supabase
                            final bool success;
                            if (isEditing && productId != null) {
                              success = await ApiService.updateProduct(
                                id: productId,
                                name: sanitizedName,
                                description: sanitizedDescription,
                                price: usdPrice,
                                category: _selectedCategory!,
                                image: imageUrl.isNotEmpty ? imageUrl : null,
                                isAvailable: _isAvailable,
                              );
                            } else {
                              success = await ApiService.saveProduct(
                                name: sanitizedName,
                                description: sanitizedDescription,
                                price: usdPrice,
                                category: _selectedCategory!,
                                image: imageUrl,
                                isAvailable: _isAvailable,
                              );
                            }
                            
                            if (mounted) {
                              if (success) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Product saved successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _fetchProducts();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to save product'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
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

  Widget _buildCategoryDropdown(String? selectedCategory, Function(String?) onChanged) {
    if (_isLoadingCategories) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading categories...',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: selectedCategory,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      dropdownColor: AppTheme.cardColor,
      decoration: InputDecoration(
        hintText: 'Select Category',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),
      items: _categories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(
            category,
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
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
