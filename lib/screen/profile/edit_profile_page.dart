import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/calculation.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  final _heightController = TextEditingController();
  final _currentWeightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _goalPeriodController = TextEditingController();

  final List<String> _activityOptions = [
  "Sedentary",
  "Lightly Active",
  "Moderately Active",
  "Very Active", 
];

String? _activityLevel;

  final supabase = Supabase.instance.client;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await supabase
          .from('account')
          .select()
          .eq('user_id', user.id) 
          .maybeSingle();

      if (response != null) {
        setState(() {
          _usernameController.text = response['username'] ?? '';
          _dobController.text = response['birthday'] ?? ''; 
          _heightController.text = response['height']?.toString() ?? '';
          _currentWeightController.text = response['weight']?.toString() ?? '';
          _targetWeightController.text = response['goal_weight']?.toString() ?? '';
          _goalPeriodController.text = response['goal_period_days']?.toString() ?? '30';
          _activityLevel = response['activity_level'] ?? 'Moderately Active';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

Future<void> _saveChanges() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  setState(() => _isSaving = true);

  try {
    final profile = await supabase
        .from('account')
        .select('gender, birthday')
        .eq('user_id', user.id)
        .maybeSingle();

    if (profile == null) throw Exception("User profile not found");

    final gender = profile['gender'] ?? 'Male'; 
    final birthdayStr = _dobController.text.trim().isNotEmpty
        ? _dobController.text.trim()
        : profile['birthday'];
    final birthday = DateTime.tryParse(birthdayStr ?? '');
    final age = (birthday != null)
        ? CalculationUtils.calculateAge(birthday)
        : 25; 

    final height = double.tryParse(_heightController.text) ?? 0.0;
    final weight = double.tryParse(_currentWeightController.text) ?? 0.0;
    final goalWeight = double.tryParse(_targetWeightController.text) ?? 0.0;
    final periodDays = int.tryParse(_goalPeriodController.text) ?? 30;

    final bmr = CalculationUtils.calculateBMR(
      gender: gender,
      weight: weight,
      height: height,
      age: age,
    );
    final activityForCalc = (_activityLevel != null && _activityOptions.contains(_activityLevel))
        ? _activityLevel!
        : 'Sedentary';

    final tdee = CalculationUtils.calculateTDEE(bmr, activityForCalc);

    final recommendedCalories = CalculationUtils.calculateRecommendedCalories(
      tdee: tdee.toInt(),
      currentWeight: weight,
      goalWeight: goalWeight,
      periodDays: periodDays,
    );

    await supabase.from('account').update({
      'username': _usernameController.text.trim(),
      'birthday': birthdayStr,
      'height': height,
      'weight': weight,
      'goal_weight': double.tryParse(_targetWeightController.text),
      'goal_period_days': periodDays,
      'activity_level': _activityLevel,
      'bmr': bmr,
      'tdee': tdee,
      'recommended_calories': recommendedCalories,
    }).eq('user_id', user.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to update profile: $e")),
    );
  } finally {
    setState(() => _isSaving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);
    const Color pageBackground = Color(0xFFF9FBFF);

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildTextField("Username", _usernameController),
                  _buildDatePicker("Date of Birth", _dobController),
                  _buildTextField("Height (cm)", _heightController, keyboardType: TextInputType.number),
                  _buildTextField("Current Weight (kg)", _currentWeightController, keyboardType: TextInputType.number),
                  _buildTextField("Target Weight (kg)", _targetWeightController, keyboardType: TextInputType.number),
                  _buildTextField("Goal Period (days)", _goalPeriodController, keyboardType: TextInputType.number),
                  _buildDropdown("Activity Level"),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Save Changes",
                                  style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Cancel",
                              style: TextStyle(color: primaryColor, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
        ),
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: controller.text.isNotEmpty
                ? DateFormat('yyyy-MM-dd').parse(controller.text)
                : DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
          }
        },
      ),
    );
  }

  Widget _buildDropdown(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DropdownButtonFormField<String>(
         value: _activityLevel != null && _activityOptions.contains(_activityLevel)
      ? _activityLevel
      : null,
      items: _activityOptions
      .map((level) => DropdownMenuItem(value: level, child: Text(level)))
      .toList(),
        onChanged: (value) => setState(() => _activityLevel = value!),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
