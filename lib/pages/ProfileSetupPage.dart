import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // For Base64 encoding
import 'ProfileDisplayPage.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _doctorNumberController = TextEditingController();
  final TextEditingController _diseaseController = TextEditingController();
  String _gender = 'Male';
  String _bloodType = 'A+';
  File? _image;
  int _selectedIndex = 3; // Set default to Profile tab

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  String _imageToBase64(File image) {
    final bytes = image.readAsBytesSync();
    return base64Encode(bytes);
  }

  Future<void> _saveProfileData() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Show a loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          // Convert image to Base64
          String? base64Image;
          if (_image != null) {
            base64Image = _imageToBase64(_image!);
          }

          // Save profile data to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'name': _nameController.text.trim(),
            'age': int.parse(_ageController.text.trim()),
            'gender': _gender,
            'bloodType': _bloodType,
            'disease': _diseaseController.text.trim(),
            'address': _addressController.text.trim(),
            'contact': _contactController.text.trim(),
            'doctorName': _doctorNameController.text.trim(),
            'doctorNumber': _doctorNumberController.text.trim(),
            'photoBase64': base64Image, // Save Base64 image
            'email': user.email,
          });

          // Dismiss the loading indicator
          if (!mounted) return;
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully!')),
          );

          // Navigate to the next page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileDisplayPage()),
          );
        } catch (e) {
          // Dismiss the loading indicator
          if (!mounted) return;
          Navigator.of(context).pop();

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
        }
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      
      case 1:
        Navigator.pushReplacementNamed(context, '/scheduling');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile_setup');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/signup');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/signin');
        break;
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF4A55A2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF4A55A2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4A55A2),
        title: const Text(
          'Setup Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF4A55A2),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage: _image != null
                                ? FileImage(_image!)
                                : null,
                            child: _image == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Color(0xFF4A55A2),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInputField(
                      controller: _nameController,
                      label: 'Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    _buildInputField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.cake,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your age';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    _buildDropdownField(
                      label: 'Gender',
                      value: _gender,
                      items: const ['Male', 'Female', 'Other'],
                      onChanged: (value) {
                        setState(() {
                          _gender = value!;
                        });
                      },
                      icon: Icons.people,
                    ),
                    _buildDropdownField(
                      label: 'Blood Type',
                      value: _bloodType,
                      items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                      onChanged: (value) {
                        setState(() {
                          _bloodType = value!;
                        });
                      },
                      icon: Icons.bloodtype,
                    ),
                    _buildInputField(
                      controller: _diseaseController,
                      label: 'Disease',
                      icon: Icons.medical_information,
                    ),
                    _buildInputField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on,
                      maxLines: 2,
                    ),
                    _buildInputField(
                      controller: _contactController,
                      label: 'Contact',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildInputField(
                      controller: _doctorNameController,
                      label: 'Doctor Name',
                      icon: Icons.medical_services,
                    ),
                    _buildInputField(
                      controller: _doctorNumberController,
                      label: 'Doctor Contact Number',
                      icon: Icons.local_hospital,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfileData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A55A2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Save Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Scheduling',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.app_registration),
            label: 'Sign Up',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: 'Sign In',
          ),
        ],
      ),
    );
  }
}
