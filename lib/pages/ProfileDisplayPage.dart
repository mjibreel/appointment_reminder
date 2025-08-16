import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'ProfileSetupPage.dart';

class ProfileDisplayPage extends StatelessWidget {
  const ProfileDisplayPage({super.key});

  Widget _buildProfileImage(String? base64Image) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF4A55A2),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 60,
        backgroundColor: const Color(0xFF4A55A2).withOpacity(0.1),
        backgroundImage: base64Image != null && base64Image.isNotEmpty
            ? MemoryImage(base64Decode(base64Image))
            : null,
        child: base64Image == null || base64Image.isEmpty
            ? const Icon(Icons.person, size: 60, color: Color(0xFF4A55A2))
            : null,
      ),
    );
  }

  Widget _buildInfoCard(String title, List<MapEntry<String, String>> items) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A55A2),
              ),
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A55A2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForField(item.key),
                        color: const Color(0xFF4A55A2),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.key,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getIconForField(String field) {
    switch (field.toLowerCase()) {
      case 'age':
        return Icons.cake;
      case 'gender':
        return Icons.person;
      case 'blood type':
        return Icons.bloodtype;
      case 'disease':
        return Icons.medical_information;
      case 'address':
        return Icons.location_on;
      case 'contact':
        return Icons.phone;
      case 'doctor name':
        return Icons.medical_services;
      case 'doctor number':
        return Icons.local_hospital;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4A55A2),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Color(0xFF4A55A2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No profile data found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/profile_setup');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A55A2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create Profile',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A55A2),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          Center(
                            child: _buildProfileImage(data['photoBase64']),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  data['name'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['email'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                      // Edit Profile Button
                      Positioned(
                        top: 20,
                        right: 20,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileSetupPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Color(0xFF4A55A2),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoCard(
                        'Personal Information',
                        [
                          MapEntry('Age', '${data['age'] ?? 'Not specified'}'),
                          MapEntry('Gender', data['gender'] ?? 'Not specified'),
                          MapEntry('Blood Type',
                              data['bloodType'] ?? 'Not specified'),
                          MapEntry('Disease', data['disease'] ?? 'Not specified'),
                        ],
                      ),
                      _buildInfoCard(
                        'Contact Information',
                        [
                          MapEntry('Address', data['address'] ?? 'Not specified'),
                          MapEntry('Contact', data['contact'] ?? 'Not specified'),
                        ],
                      ),
                      _buildInfoCard(
                        'Medical Information',
                        [
                          MapEntry(
                              'Doctor Name', data['doctorName'] ?? 'Not specified'),
                          MapEntry('Doctor Number',
                              data['doctorNumber'] ?? 'Not specified'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                                context, '/profile_setup');
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A55A2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
