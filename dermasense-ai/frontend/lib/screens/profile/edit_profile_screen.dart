import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  final List<String> _skinTypes = ['Normal', 'Dry', 'Oily', 'Combination', 'Sensitive'];
  final List<String> _availableConcerns = ['Acne', 'Pigmentation', 'Hydration', 'Wrinkles', 'Pores', 'Redness'];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _emailController = TextEditingController(text: widget.profile.email);
    _ageController = TextEditingController(text: widget.profile.age?.toString() ?? '');
    _locationController = TextEditingController(text: widget.profile.location ?? '');
    _budgetController = TextEditingController(text: widget.profile.budget?.toString() ?? '');
    
    _selectedSkinType = widget.profile.skinType;
    if (!_skinTypes.contains(_selectedSkinType)) {
      _selectedSkinType = null;
    }
    
    _selectedConcerns = List.from(widget.profile.skinConcerns);
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
    );

    final provider = Provider.of<SkinProfileProvider>(context, listen: false);
    final success = await provider.updateProfile(updatedProfile);

    setState(() {
      _isSaving = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Personal Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                  validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (val) => val == null || val.isEmpty ? "Email is required" : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Age"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(labelText: "Location"),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                const Text("Skin Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Skin Type"),
                  initialValue: _selectedSkinType,
                  items: _skinTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSkinType = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text("Skin Concerns (Select multiple)", style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _availableConcerns.map((concern) {
                    final isSelected = _selectedConcerns.contains(concern);
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
                      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      checkmarkColor: Theme.of(context).colorScheme.primary,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),
                const Text("Preferences", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
