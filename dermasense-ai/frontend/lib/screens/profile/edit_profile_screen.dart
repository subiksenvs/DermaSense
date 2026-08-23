import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';
import '../../providers/skin_profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;
  late TextEditingController _budgetController;

  String? _selectedSkinType;
  List<String> _selectedConcerns = [];
  String? _profileImageUrl;
  bool _isUploading = false;
  bool _isPickingImage = false;

  final List<String> _skinTypes = [
    'Normal',
    'Dry',
    'Oily',
    'Combination',
    'Sensitive',
  ];
  final List<String> _availableConcerns = [
    'Acne',
    'Pigmentation',
    'Hydration',
    'Wrinkles',
    'Pores',
    'Redness',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _emailController = TextEditingController(text: widget.profile.email);
    _ageController = TextEditingController(
      text: widget.profile.age?.toString() ?? '',
    );
    _locationController = TextEditingController(
      text: widget.profile.location ?? '',
    );
    _budgetController = TextEditingController(
      text: widget.profile.budget?.toString() ?? '',
    );

    _selectedSkinType = widget.profile.skinType;
    if (!_skinTypes.contains(_selectedSkinType)) {
      _selectedSkinType = null;
    }

    _selectedConcerns = List.from(widget.profile.skinConcerns);
    final profileProvider = Provider.of<SkinProfileProvider>(
      context,
      listen: false,
    );
    _profileImageUrl = profileProvider.profile.profileImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isPickingImage = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _isUploading = true);

        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) throw Exception("User not logged in");

        // Avoid CORS issues on Web by storing the image directly in Firestore as Base64
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64String';

        setState(() {
          _profileImageUrl = dataUrl;
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick or upload image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Change Profile Photo",
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 24),
                _buildOptionTile(
                  icon: Icons.camera_alt_rounded,
                  label: "Take a Photo",
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                _buildOptionTile(
                  icon: Icons.photo_library_rounded,
                  label: "Choose from Gallery",
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_profileImageUrl != null &&
                    _profileImageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildOptionTile(
                    icon: Icons.delete_rounded,
                    label: "Remove Photo",
                    color: Theme.of(context).colorScheme.error,
                    onTap: () {
                      Navigator.pop(context);
                      _removeImage();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  Future<void> _removeImage() async {
    setState(() {
      _profileImageUrl = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final updatedProfile = widget.profile.copyWith(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      location: _locationController.text.trim(),
      budget: double.tryParse(_budgetController.text.trim()),
      skinType: _selectedSkinType,
      skinConcerns: _selectedConcerns,
      profileImageUrl: _profileImageUrl,
    );

    final provider = Provider.of<SkinProfileProvider>(context, listen: false);
    final success = await provider.updateProfile(updatedProfile);

    setState(() {
      _isSaving = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasImage = _profileImageUrl != null && _profileImageUrl!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SafeArea(
        child: _isUploading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _isPickingImage
                                  ? null
                                  : _showImagePickerOptions,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: _isPickingImage
                                        ? CircleAvatar(
                                            radius: 57,
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                            child:
                                                const CircularProgressIndicator(),
                                          )
                                        : CircleAvatar(
                                            radius: 57,
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                            backgroundImage: hasImage
                                                ? (_profileImageUrl!.startsWith(
                                                        'data:image',
                                                      )
                                                      ? MemoryImage(
                                                          base64Decode(
                                                            _profileImageUrl!
                                                                .split(',')
                                                                .last,
                                                          ),
                                                        )
                                                      : NetworkImage(
                                                              _profileImageUrl!,
                                                            )
                                                            as ImageProvider)
                                                : null,
                                            child: (!hasImage)
                                                ? Icon(
                                                    Icons.person,
                                                    size: 56,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  )
                                                : null,
                                          ),
                                  ),
                                  // Camera badge
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surface,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Tap to change photo",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        "Personal Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? "Name is required"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: "Email"),
                        validator: (val) => val == null || val.isEmpty
                            ? "Email is required"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Age",
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: "Location",
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      const Text(
                        "Skin Profile",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Skin Type",
                        ),
                        initialValue: _selectedSkinType,
                        items: _skinTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSkinType = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Skin Concerns (Select multiple)",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _availableConcerns.map((concern) {
                          final isSelected = _selectedConcerns.contains(
                            concern,
                          );
                          return FilterChip(
                            label: Text(concern),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedConcerns.add(concern);
                                } else {
                                  _selectedConcerns.remove(concern);
                                }
                              });
                            },
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            checkmarkColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),
                      const Text(
                        "Preferences",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Monthly Skincare Budget (\$)",
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),

                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Save Changes"),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
