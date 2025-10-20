import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'auth/sign_in.dart';
import '../screen/profile/terms_and_conditions_page.dart';
import '../screen/profile/knowledge_inventory_page.dart';
import '../screen/profile/edit_profile_page.dart';
import '../screen/profile/settings_page.dart';
import '../screen/profile/upgrade_plans_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _client = Supabase.instance.client;
  Map<String, dynamic>? profile;
  bool loading = true;

  final List<String> _malePhotos = [
    'assets/profile/male_profile1.jpg',
    'assets/profile/male_profile2.jpg',
    'assets/profile/male_profile3.jpg',
    'assets/profile/male_profile4.jpg',
    'assets/profile/male_profile5.jpg',
    'assets/profile/male_profile6.jpg',
  ];

  final List<String> _femalePhotos = [
    'assets/profile/female_profile1.jpg',
    'assets/profile/female_profile2.jpg',
    'assets/profile/female_profile3.jpg',
    'assets/profile/female_profile4.jpg',
    'assets/profile/female_profile5.jpg',
    'assets/profile/female_profile6.jpg',
  ];

  String? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final res = await _client
          .from('account')
          .select('username, gender, profile_image')
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          profile = res;
          // load existing profile image from Supabase 
          _selectedPhoto = res?['profile_image'] as String?;
          loading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignInPage()),
    );
  }

  Future<void> _openImagePicker(String gender) async {
    final availablePhotos = gender == 'Female' ? _femalePhotos : _malePhotos;
    String? tempSelection = _selectedPhoto;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Choose Your Profile Photo",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      itemCount: availablePhotos.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        final imgPath = availablePhotos[index];
                        final isSelected = imgPath == tempSelection;

                        return GestureDetector(
                          onTap: () => setModalState(() {
                            tempSelection = imgPath;
                          }),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.green
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: AssetImage(imgPath),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Icon(Icons.check_circle,
                                      color: Colors.green, size: 22),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (tempSelection != null) {
                            final user = _client.auth.currentUser;
                            if (user != null) {
                              await _client.from('account').update({
                                'profile_image': tempSelection,
                              }).eq('user_id', user.id);

                              setState(() {
                                _selectedPhoto = tempSelection;
                              });
                            }
                          }
                          if (mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 138, 35, 107),
                        ),
                        child: const Text(
                          "OK",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final username = profile?['username'] ?? 'User';
    final gender = profile?['gender'] ?? 'Male';

    // Set default profile images
    final defaultMale = 'assets/profile/male_profile1.jpg';
    final defaultFemale = 'assets/profile/female_profile1.jpg';
    final profileImage = _selectedPhoto ??
        (gender == 'Female' ? defaultFemale : defaultMale);

    final colorBackground = const Color(0xFFF9FBF9);

  return Scaffold(
  backgroundColor: colorBackground,
  body: Stack(
    children: [
      Container(
        height: 320, 
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFC1B5FF),
              Color(0xFFAED8FF), 
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 25),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                colors: [Color(0xFF8E3DFF), Color(0xFF4F8DFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: AssetImage(profileImage),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _openImagePicker(gender),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Color(0xFF6A11CB),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          username,
                          style: const TextStyle(
                            color: Color(0xFF3B3B98),
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    color: Color(0xFFF9FBF9), 
                    padding: const EdgeInsets.only(top: 16, bottom: 32),
                    child: Column(
                      children: [
                        _buildMenuItem(context,
                            icon: Icons.person_outline,
                            text: "Edit Profile",
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfilePage()),
                              );
                              _loadProfile();
                            },
                          ),

                        _buildMenuItem(context,
                            icon: Icons.star_border,
                            text: "Upgrade Plans",
                            onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const UpgradePlansPage()),
                            );
                          },
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.book_outlined,
                          text: "Knowledge Inventory",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const KnowledgeInventoryPage()),
                            );
                          },
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.description_outlined,
                          text: "Terms & Conditions",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TermsAndConditionsPage()),
                            );
                          },
                        ),
                        _buildMenuItem(context,
                            icon: Icons.settings_outlined,
                            text: "Settings",
                             onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsPage()),
                            );
                          },
                        ),
                        _buildMenuItem(context,
                            icon: Icons.logout,
                            text: "Log Out",
                            textColor: Colors.red.shade700,
                            iconColor: Colors.red.shade700,
                            onTap: _logout),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String text,
      required VoidCallback onTap,
      Color? iconColor,
      Color? textColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.grey.shade700),
        title: Text(
          text,
          style: TextStyle(
            color: textColor ?? Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}