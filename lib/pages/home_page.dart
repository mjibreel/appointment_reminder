import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scheduling.dart';
import 'ProfileSetupPage.dart';
import 'ProfileDisplayPage.dart';
import 'auth/signin_page.dart';
import 'auth/signup_page.dart';
import 'dart:convert'; // For Base64 decoding
import 'package:url_launcher/url_launcher.dart';
import 'health_page.dart';
import 'checkup_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Determine which profile page to show
  Future<Widget> _getProfilePage() async {
    final user = FirebaseAuth.instance.currentUser;

    // If no user is signed in, redirect to SignInPage
    if (user == null) {
      return const SignInPage();
    }

    // Check if the profile exists in Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      return const ProfileDisplayPage();
    } else {
      return const ProfileSetupPage();
    }
  }

  // Navigation pages list
  final List<Widget> _pages = [
    const _HomeContentPage(), // Home Content
    const MedicationTrackerPage(), // Appointment Scheduling
    Container(), // Placeholder for dynamic Profile Page
    const SignUpPage(), // Sign Up Page
    const SignInPage(), // Sign In Page
  ];

  // Change selected tab
  void _onItemTapped(int index) async {
    if (index == 2) {  // Profile tab
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _selectedIndex = index;
          _pages[2] = const SignInPage();  // Show sign in page if not authenticated
        });
      } else {
        // Profile tab logic for authenticated users
        final profilePage = await _getProfilePage();
        setState(() {
          _pages[2] = profilePage;
          _selectedIndex = index;
        });
      }
    } else if (index == 1) {  // Scheduling tab
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Show login dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Login Required'),
              content: const Text('Please login or sign up to access scheduling.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedIndex = 4;  // Go to Sign In tab
                    });
                  },
                  child: const Text('Login'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedIndex = 3;  // Go to Sign Up tab
                    });
                  },
                  child: const Text('Sign Up'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      } else {
        setState(() {
          _selectedIndex = index;
        });
      }
    } else {
      // For Home, Sign Up, and Sign In tabs, allow access without authentication
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
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

// Rest of the code remains the same...

// Home Content Page
class _HomeContentPage extends StatelessWidget {
  const _HomeContentPage();

  // Fetch profile data from Firestore
  Future<Map<String, dynamic>> _fetchProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        return doc.data()!;
      }
    }
    return {};
  }

  // Call the doctor's number
  Future<void> _callDoctor(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Show login dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Login Required'),
            content: const Text('Please login or sign up to call your doctor.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                  );
                },
                child: const Text('Login'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                child: const Text('Sign Up'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
      return; // Return here after showing dialog
    }

    // Existing doctor call logic
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid) // Use safe call operator
        .get();

    if (doc.exists) {
      final doctorNumber = doc.data()?['doctorNumber'];
      if (doctorNumber != null && doctorNumber.isNotEmpty) {
        final uri = 'tel:$doctorNumber';
        if (await canLaunch(uri)) {
          await launch(uri);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to call the doctor.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor\'s number not available.')),
        );
      }
    }
  }


  // Build the task list
  Widget _buildTaskList() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No tasks available.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No tasks available.'));
        }

        final tasks = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index].data() as Map<String, dynamic>;
            final bool isCompleted = task['completed'] ?? false;

            return Dismissible(
              key: Key(tasks[index].id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) async {
                await tasks[index].reference.delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: ListTile(
                leading: Icon(Icons.task, color: Colors.blue.shade300),
                title: Text(
                  task['task'] ?? 'Unnamed Task',
                  style: TextStyle(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : null,
                  ),
                ),
                trailing: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween(begin: 0, end: isCompleted ? 1 : 0),
                  builder: (context, value, child) {
                    return IconButton(
                      icon: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Color.lerp(Colors.grey, Colors.green, value),
                          ),
                          if (value > 0)
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.withOpacity(value),
                            ),
                        ],
                      ),
                      onPressed: () async {
                        // Update completion status in Firestore
                        await tasks[index].reference.update({
                          'completed': !isCompleted,
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isCompleted ? 'Task uncompleted' : 'Task completed!',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF), // Light blue-gray background
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF4A55A2),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (FirebaseAuth.instance.currentUser != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: GestureDetector(
                        onTap: () async {
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Logout',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (shouldLogout == true) {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          }
                        },
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  const Text(
                    'Health App',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF4A55A2),
                      Color(0xFF7895CB),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user != null) ...[
                    // Profile Section
                    FutureBuilder<Map<String, dynamic>>(
                      future: _fetchProfileData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final profileData = snapshot.data ?? {};
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7895CB), Color(0xFF9EB8D9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundImage: profileData['photoBase64'] != null
                                      ? MemoryImage(
                                          base64Decode(profileData['photoBase64']),
                                        )
                                      : const AssetImage('assets/placeholder.png')
                                          as ImageProvider,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profileData['name'] ?? 'No Name',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Age: ${profileData['age'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
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
                  ] else ...[
                    // Welcome Section for non-authenticated users
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 600,
                        ),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7895CB), Color(0xFF9EB8D9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.health_and_safety,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Welcome to Health App',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Track your health, appointments, and medications',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Quick Actions Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A55A2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildQuickActionCard(
                              context: context,
                              color: const Color(0xFF2196F3),
                              icon: Icons.favorite,
                              label: 'Health',
                            ),
                            _buildQuickActionCard(
                              context: context,
                              color: const Color(0xFF9C27B0),
                              icon: Icons.medical_services,
                              label: 'Check Up',
                            ),
                            _buildQuickActionCard(
                              context: context,
                              color: const Color(0xFFFF5722),
                              icon: Icons.medication_liquid,
                              label: 'Medication',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Call Doctor Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: () => _callDoctor(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A55A2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Call My Doctor',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (user != null) ...[
                    const SizedBox(height: 24),
                    // Tasks Section
                    Container(
                      padding: const EdgeInsets.all(20),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Today's Tasks",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A55A2),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: const Color(0xFF4A55A2),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/create_task');
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTaskList(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text('Login Required'),
                content: const Text('Please login or sign up to use this feature.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignInPage()),
                      );
                    },
                    child: const Text('Login'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                      );
                    },
                    child: const Text('Sign Up'),
                  ),
                ],
              );
            },
          );
        } else {
          if (label == 'Health') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HealthPage()),
            );
          } else if (label == 'Check Up') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CheckupPage()),
            );
          } else if (label == 'Medication') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MedicationTrackerPage()),
            );
          }
        }
      },
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
