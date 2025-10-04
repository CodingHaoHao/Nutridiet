import 'package:flutter/material.dart';
import 'auth/sign_in.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/calculation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _client = Supabase.instance.client;
  Map<String, dynamic>? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final res = await _client
        .from('account')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (mounted) {
      setState(() {
        profile = res;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('No profile data found')),
      );
    }

    // extract user information
    final username = profile!['username'] ?? '';
    final email = profile!['email'] ?? '';
    final gender = profile!['gender'] ?? 'Male';
    final height = (profile!['height'] as num?)?.toDouble() ?? 170;
    final weight = (profile!['weight'] as num?)?.toDouble() ?? 70;
    final goalWeight = (profile!['goal_weight'] as num?)?.toDouble() ?? weight;
    final period = (profile!['goal_period_days'] as int?) ?? 60;
    final activity = profile!['activity_level'] ?? 'Sedentary';
    final birthdayStr = profile!['birthday'] as String? ?? '2000-01-01';
    final birthday = DateTime.tryParse(birthdayStr) ?? DateTime(2000, 1, 1);

    // calculate recommended calories
    final age = CalculationUtils.calculateAge(birthday);
    final bmr = CalculationUtils.calculateBMR(
      gender: gender,
      weight: weight,
      height: height,
      age: age,
    ).floor();
    final tdee = CalculationUtils.calculateTDEE(bmr, activity).floor();
    final recommended = CalculationUtils.calculateRecommendedCalories(
      currentWeight: weight,
      goalWeight: goalWeight,
      periodDays: period,
      tdee: tdee,
    ).floor();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: const Text('NutriDiet'),
        actions: [
          IconButton(
            onPressed: () async {
              await AuthService().signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SignInPage()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text("👋 Welcome, $username!",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text("Email: $email"),
            Text("Gender: $gender"),
            Text("Age: $age years"),
            const Divider(height: 30, thickness: 1),

            // Card-style metrics
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📏 Height: ${height.toStringAsFixed(1)} cm"),
                    Text("⚖️ Weight: ${weight.toStringAsFixed(1)} kg"),
                    Text("🎯 Goal Weight: ${goalWeight.toStringAsFixed(1)} kg"),
                    Text("📅 Goal Period: $period days"),
                    Text("🏃 Activity Level: $activity"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Card(
              color: Colors.lightBlue.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🔥 BMR: $bmr kcal"),
                    Text("⚡ TDEE: $tdee kcal"),
                    Text("🥗 Recommended Daily Calories: $recommended kcal"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
