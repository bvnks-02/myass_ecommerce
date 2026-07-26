// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/security/rate_limiter.dart';
import '../../../../core/services/dialog_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';
import '../../../../services/api_service.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/providers/products_provider.dart';

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
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  static const int maxImages = 4;
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
        AppSnackBar.error(context, 'Could not load categories. Please try again.');
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
        AppSnackBar.error(context, 'Could not load products. Please try again.');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct(int id, String productName) async {
    try {
      final success = await ApiService.deleteProduct(id);
      if (mounted) {
        if (success) {
          context.read<ProductsProvider>().forceRefresh();
          AppSnackBar.success(context, '"$productName" has been removed from the store.');
        } else {
          AppSnackBar.error(context, 'Could not delete product. Please try again.');
        }
        _fetchProducts();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to delete product. Please check your connection.');
      }
    }
  }

  Future<String?> _uploadImage(XFile image) async {
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
        AppSnackBar.error(context, 'Image upload failed. Please try again.');
      }
      return null;
    }
  }

  // Helper to build image widget for selected images (works on all platforms)
  Widget _buildSelectedImage(XFile image, int index) {
    debugPrint('Building image widget for index $index, path: ${image.path}');
    return FutureBuilder<Uint8List>(
      future: image.readAsBytes().catchError((error) {
        debugPrint('Error reading image bytes at index $index: $error');
        return Uint8List(0);
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('Image $index: Loading bytes...');
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
            ),
          );
        }
        if (snapshot.hasError) {
          debugPrint('Image $index: Error loading - ${snapshot.error}');
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.red, size: 30),
          );
        }
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          debugPrint('Image $index: Loaded ${snapshot.data!.length} bytes');
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Image $index: Error displaying - $error');
              return const Center(child: Icon(Icons.image, color: Colors.white54));
            },
          );
        }
        debugPrint('Image $index: No data available');
        return const Center(child: Icon(Icons.image, color: Colors.white54));
      },
    );
  }

  Future<List<String>> _uploadImages(List<XFile> images) async {
    setState(() => _isUploading = true);
    final List<String> urls = [];
    try {
      for (final image in images) {
        final url = await _uploadImage(image);
        if (url != null) {
          urls.add(url);
        }
      }
      return urls;
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not upload images. Please try again.');
      }
      return urls;
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showAddEditProductDialog({ProductEntity? product}) {
    final isEditing = product != null;
    final productId = product?.id;
    _selectedImages = []; // Reset selection
    final nameController = TextEditingController(text: product?.name ?? '');

    // Display price directly (stored as DZD)
    final priceController = TextEditingController(text: product?.price.round().toString() ?? '');

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
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                    // Image Gallery Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Images (${_selectedImages.length + (isEditing && product.image.isNotEmpty ? 1 : 0)}/$maxImages)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_selectedImages.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      _selectedImages.clear();
                                    });
                                  },
                                  child: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Show existing image when editing
                          if (isEditing && product.image.isNotEmpty && _selectedImages.isEmpty)
                            Container(
                              height: 100,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withOpacity(0.05),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  product.image,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(child: Icon(Icons.image, color: Colors.white54, size: 40)),
                                ),
                              ),
                            ),
                          // Selected Images Grid
                          if (_selectedImages.isNotEmpty)
                            Container(
                              height: 100,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  final image = _selectedImages[index];
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        margin: const EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: _buildSelectedImage(image, index),
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 14,
                                        child: GestureDetector(
                                          onTap: () {
                                            setDialogState(() {
                                              _selectedImages.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      // Show image number badge
                                      Positioned(
                                        bottom: 2,
                                        left: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 12),
                          // Add Image Button
                          if (_selectedImages.length < maxImages)
                            OutlinedButton.icon(
                              onPressed: _isUploading
                                  ? null
                                  : () async {
                                      debugPrint('Picking images... Current count: ${_selectedImages.length}');
                                      try {
                                        final List<XFile>? images = await _picker.pickMultiImage();
                                        debugPrint('Picked ${images?.length ?? 0} images');
                                        if (images != null && images.isNotEmpty) {
                                          setDialogState(() {
                                            // Add images up to the max limit
                                            final int slotsAvailable = maxImages - _selectedImages.length;
                                            final int imagesToAdd = images.length > slotsAvailable ? slotsAvailable : images.length;
                                            _selectedImages.addAll(images.sublist(0, imagesToAdd));
                                            debugPrint('Total images now: ${_selectedImages.length}');
                                          });
                                        }
                                      } catch (e) {
                                        debugPrint('Error picking images: $e');
                                      }
                                    },
                              icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                              label: Text(
                                _selectedImages.isEmpty ? 'Select Images (up to $maxImages)' : 'Add More Images',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                          // Upload new images if any selected
                          List<String> uploadedUrls = [];
                          if (_selectedImages.isNotEmpty) {
                            setDialogState(() {}); // Trigger rebuild to show loading
                            uploadedUrls = await _uploadImages(_selectedImages);
                          }

                          try {
                            // Sanitize inputs
                            final sanitizedName = InputSanitizer.sanitizeString(nameController.text.trim(), maxLength: 200);
                            final sanitizedDescription = InputSanitizer.sanitizeString(descController.text.trim(), maxLength: 2000);
                            
                            // Validate inputs
                            if (sanitizedName.isEmpty || sanitizedName.length < 2) {
                              if (mounted) {
                                AppSnackBar.warning(context, 'Product name must be at least 2 characters');
                              }
                              return;
                            }
                            
                            if (_selectedCategory == null || _selectedCategory!.isEmpty) {
                              if (mounted) {
                                AppSnackBar.warning(context, 'Please select a category for this product');
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
                                AppSnackBar.warning(context, 'Please enter a valid price');
                              }
                              return;
                            }
                            
                            // Rate limiting check for admin operations
                            if (!RateLimiters.api.isAllowed('admin_product_save')) {
                              if (mounted) {
                                AppSnackBar.warning(context, 'Too many attempts. Please try again in a moment.');
                              }
                              return;
                            }

                            // Store price directly in DZD (no conversion needed)
                            final finalPrice = dzdPrice;

                            // Prepare image URLs - preserve existing gallery on text-only edits
                            List<String> allImages = [];
                            if (uploadedUrls.isNotEmpty) {
                              allImages = uploadedUrls;
                            } else if (isEditing) {
                              if (product.images.isNotEmpty) {
                                allImages = List<String>.from(product.images);
                              } else if (product.image.isNotEmpty) {
                                allImages = [product.image];
                              }
                            }

                            // Use first image as main image
                            String mainImageUrl = allImages.isNotEmpty ? allImages.first : '';

                            // Save or update product to Supabase
                            final bool success;
                            if (isEditing && productId != null) {
                              success = await ApiService.updateProduct(
                                id: productId,
                                name: sanitizedName,
                                description: sanitizedDescription,
                                price: finalPrice,
                                category: _selectedCategory!,
                                image: mainImageUrl.isNotEmpty ? mainImageUrl : null,
                                images: allImages.isNotEmpty ? allImages : null,
                                isAvailable: _isAvailable,
                              );
                            } else {
                              success = await ApiService.saveProduct(
                                name: sanitizedName,
                                description: sanitizedDescription,
                                price: finalPrice,
                                category: _selectedCategory!,
                                image: mainImageUrl,
                                images: allImages,
                                isAvailable: _isAvailable,
                              );
                            }
                            
                            if (mounted) {
                              if (success) {
                                // Bust storefront cache so customers see new prices/images.
                                context.read<ProductsProvider>().forceRefresh();
                                Navigator.pop(context);
                                AppSnackBar.success(context, 'Product has been saved successfully');
                                _fetchProducts();
                              } else {
                                AppSnackBar.error(context, 'Could not save product. Please try again.');
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              AppSnackBar.error(context, 'Something went wrong. Please try again.');
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
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: product.image.isNotEmpty
                              ? Image.network(
                                  product.image,
                                  fit: BoxFit.cover,
                                  width: 50,
                                  height: 50,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image, color: Colors.white54, size: 24),
                                )
                              : const Icon(Icons.image, color: Colors.white54, size: 24),
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
                          context.dialogs.showDeleteProductConfirmation(
                            productName: product.name,
                            onConfirm: () => _deleteProduct(product.id, product.name),
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
