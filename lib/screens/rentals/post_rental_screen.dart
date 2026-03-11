import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../models/rental_item_model.dart';

class PostRentalScreen extends StatefulWidget {
  final RentalItemModel? itemToEdit;

  const PostRentalScreen({super.key, this.itemToEdit});

  @override
  State<PostRentalScreen> createState() => _PostRentalScreenState();
}

class _PostRentalScreenState extends State<PostRentalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _depositController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = '';
  String _selectedCondition = 'Like New (95%+)';
  final List<File> _images = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'Camera',
    'Electronics',
    'Fashion',
    'Books',
    'Sports',
    'Music',
    'Others',
  ];

  final List<String> _conditions = [
    'Like New (95%+)',
    'Good',
    'Fair',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _itemNameController.text = item.itemName;
      _dailyRateController.text = item.dailyRate.toString();
      _depositController.text = item.deposit.toString();
      _descriptionController.text = item.description;
      _selectedCategory = item.category;
      _selectedCondition = item.condition;
      // We do not load existing remote images into _images which expects File
      // Handling remote images deletion/addition in edit mode can be complex,
      // so for now we either keep existing or replace entirely if new are picked.
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _dailyRateController.dispose();
    _depositController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final l = AppLocalizations.of(context);
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.tr('max_photos'))),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          if (_images.length < 5) {
            _images.add(File(file.path));
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submitRental() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.tr('select_category_required'))),
      );
      return;
    }

    if (_images.isEmpty && widget.itemToEdit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.tr('add_photo_at_least'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final cloudinaryService = CloudinaryService();
      final firestoreService = FirestoreService();

      List<String> imageUrls = [];
      
      if (_images.isNotEmpty) {
        // Upload images to Cloudinary
        imageUrls = await cloudinaryService.uploadMultipleImages(
          _images,
          'kaset_rentals',
        );
      } else if (widget.itemToEdit != null) {
        // Keep existing images if none were added
        imageUrls = widget.itemToEdit!.imageUrls;
      }

      if (widget.itemToEdit != null) {
        // Update existing item
        await firestoreService.updateRentalItem(widget.itemToEdit!.id, {
          'itemName': _itemNameController.text.trim(),
          'category': _selectedCategory,
          'condition': _selectedCondition,
          'dailyRate': double.parse(_dailyRateController.text),
          'deposit': double.parse(_depositController.text),
          'description': _descriptionController.text.trim(),
          if (_images.isNotEmpty) 'imageUrls': imageUrls, // only update if new images matching
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('อัพเดทโพสต์เรียบร้อยแล้ว'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Create rental item in Firestore
        final item = RentalItemModel(
          id: '',
          ownerId: authService.currentUser!.uid,
          itemName: _itemNameController.text.trim(),
          category: _selectedCategory,
          condition: _selectedCondition,
          dailyRate: double.parse(_dailyRateController.text),
          deposit: double.parse(_depositController.text),
          description: _descriptionController.text.trim(),
          imageUrls: imageUrls,
          createdAt: DateTime.now(),
        );

        await firestoreService.createRentalItem(item);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.tr('rental_posted')),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Category',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ..._categories.map((category) => ListTile(
                    title: Text(category),
                    trailing: _selectedCategory == category
                        ? const Icon(Icons.check, color: AppTheme.primaryTeal)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemToEdit != null ? 'แก้ไขโพสต์' : l.tr('post_rental_title')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Picker
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.divider,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: _images.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 48,
                            color: AppTheme.primaryTeal,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.itemToEdit != null 
                                ? 'ต้องการเปลี่ยนรูปภาพใหม่หรือไม่?' 
                                : '${l.tr('add_photos')} (${_images.length}/5)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.itemToEdit != null
                                ? 'หากเพิ่มรูปใหม่ รูปเก่าจะถูกแทนที่'
                                : l.tr('clear_photos_trust'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _images.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _images.length) {
                            // Add more button
                            return GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.accentMint.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: AppTheme.primaryTeal,
                                  size: 32,
                                ),
                              ),
                            );
                          }

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _images[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Item Name
            Text(
              l.tr('item_name'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _itemNameController,
              decoration: InputDecoration(
                hintText: l.tr('item_name_hint'),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l.tr('item_name_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Category
            Text(
              l.tr('category'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showCategoryPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory.isEmpty
                          ? l.tr('select_category')
                          : _selectedCategory,
                      style: TextStyle(
                        color: _selectedCategory.isEmpty
                            ? AppTheme.textHint
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Condition
            Text(
              l.tr('condition_label'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _conditions.map((condition) {
                final isSelected = _selectedCondition == condition;
                return ChoiceChip(
                  label: Text(condition),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCondition = condition;
                    });
                  },
                  selectedColor: AppTheme.primaryTeal,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Daily Rate and Deposit
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.tr('daily_rate'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dailyRateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l.tr('required');
                          }
                          if (double.tryParse(value) == null) {
                            return l.tr('invalid');
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.tr('deposit_label'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _depositController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l.tr('required');
                          }
                          if (double.tryParse(value) == null) {
                            return l.tr('invalid');
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description & Rules
            Text(
              l.tr('desc_and_rules'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: l.tr('desc_hint'),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l.tr('desc_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRental,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l.tr('post_btn')),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
