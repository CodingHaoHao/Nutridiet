import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'sign_in.dart';
import '../../services/auth_service.dart';
import '../../utils/calculation.dart';


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _birthday = TextEditingController();
  String? _gender;
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _goalWeight = TextEditingController();
  final _goalPeriod = TextEditingController(); 
  String? _activityLevel;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;
  final _auth = AuthService();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _birthday.dispose();
    _height.dispose();
    _weight.dispose();
    _goalWeight.dispose();
    _goalPeriod.dispose();
    super.dispose();
  }

  void _showMessage(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _onSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_password.text != _confirmPassword.text) {
      _showMessage('Passwords do not match');
      return;
    }
    setState(() => _loading = true);

  try {
    final birthdayDate = DateTime.parse(_birthday.text);
    final age = CalculationUtils.calculateAge(birthdayDate);
    final bmr = CalculationUtils.calculateBMR(
      gender: _gender!,
      weight: double.parse(_weight.text),
      height: double.parse(_height.text),
      age: age,
    );
    final tdee = CalculationUtils.calculateTDEE(bmr, _activityLevel!);
    final recommendedCalories = CalculationUtils.calculateRecommendedCalories(
      tdee: tdee,
      currentWeight: double.parse(_weight.text),
      goalWeight: double.parse(_goalWeight.text),
      periodDays: int.parse(_goalPeriod.text),
    );

    await _auth.signUpAndCreateProfile(
      username: _username.text,
      email: _email.text,
      password: _password.text,
      birthday: _birthday.text.isEmpty ? null : _birthday.text,
      gender: _gender,
      height: double.tryParse(_height.text),
      weight: double.tryParse(_weight.text),
      goalWeight: double.tryParse(_goalWeight.text),
      goalPeriodDays: int.tryParse(_goalPeriod.text),
      activityLevel: _activityLevel,
      bmr: bmr,
      tdee: tdee,
      recommendedCalories: recommendedCalories,
    );

    if (!mounted) return;
    _showMessage('Account created successfully! Sign in to start your journey now.');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignInPage()),
    );
  } catch (e) {
    String msg = e.toString();
    if (msg.contains('duplicate') || msg.toLowerCase().contains('unique')) {
      msg = 'Username or email already exists.';
    }
    _showMessage(msg.replaceFirst('Exception: ', ''));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username is required';
    if (v.length < 2) return 'Min 2 characters';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email required';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v);
    if (!ok) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password required';
    if (v.length < 6) return 'Min 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Confirm password required';
    if (v != _password.text) return 'Passwords do not match';
    return null;
  }

  String? _validateBirthday(String? v) {
    if (v == null || v.isEmpty) return 'Birthday required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _username,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateUsername,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _birthday,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Birthday',
                      prefixIcon: Icon(Icons.cake),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        initialDate: DateTime(2000),
                      );
                      if (date != null) {
                        _birthday.text =
                             "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                      }
                    },
                    validator: _validateBirthday,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.wc),
                      border: OutlineInputBorder(),
                    ),
                    value: _gender,
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged: (value) => setState(() => _gender = value),
                    validator: (value) =>
                        value == null ? 'Please select gender' : null,
                  ),
                  const SizedBox(height: 16),
    
                  TextFormField(
                    controller: _height,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      prefixIcon: Icon(Icons.height),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final selectedHeight = await showModalBottomSheet<int>(
                        context: context,
                        builder: (ctx) {
                          int tempHeight = int.tryParse(_height.text) ?? 170;
                          return Container(
                            height: 250,
                            child: Column(
                              children: [
                                Expanded(
                                  child: CupertinoPicker(
                                    itemExtent: 40,
                                    scrollController: FixedExtentScrollController(
                                      initialItem: tempHeight - 100,
                                    ),
                                    onSelectedItemChanged: (index) {
                                      tempHeight = 100 + index;
                                    },
                                    children: List.generate(
                                      121, 
                                      (index) => Center(
                                        child: Text('${100 + index} cm'),
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx), 
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, tempHeight),
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                      if (selectedHeight != null) {
                        setState(() => _height.text = selectedHeight.toString());
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weight,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      prefixIcon: Icon(Icons.monitor_weight),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final selectedWeight = await showModalBottomSheet<int>(
                        context: context,
                        builder: (ctx) {
                          int tempWeight = int.tryParse(_weight.text) ?? 70;

                          return Container(
                            height: 250,
                            child: Column(
                              children: [
                                Expanded(
                                  child: CupertinoPicker(
                                    itemExtent: 40,
                                    scrollController: FixedExtentScrollController(
                                      initialItem: tempWeight - 30,
                                    ),
                                    onSelectedItemChanged: (index) {
                                      tempWeight = 30 + index;
                                    },
                                    children: List.generate(
                                      121, 
                                      (index) => Center(
                                        child: Text('${30 + index} kg'),
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, tempWeight),
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                      if (selectedWeight != null) {
                        setState(() => _weight.text = selectedWeight.toString());
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                    TextFormField(
                    controller: _goalWeight,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Goal Weight (kg)',
                      prefixIcon: Icon(Icons.flag),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final selectedGoalWeight = await showModalBottomSheet<int>(
                        context: context,
                        builder: (ctx) {
                          int tempGoalWeight = int.tryParse(_goalWeight.text) ?? 70;

                          return Container(
                            height: 250,
                            child: Column(
                              children: [
                                Expanded(
                                  child: CupertinoPicker(
                                    itemExtent: 40,
                                    scrollController: FixedExtentScrollController(
                                      initialItem: (tempGoalWeight - 30).clamp(0, 120),
                                    ),
                                    onSelectedItemChanged: (index) {
                                      tempGoalWeight = 30 + index;
                                    },
                                    children: List.generate(
                                      121,
                                      (index) => Center(child: Text('${30 + index} kg')),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx), 
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, tempGoalWeight),
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                      if (selectedGoalWeight != null) {
                        setState(() => _goalWeight.text = selectedGoalWeight.toString());
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _goalPeriod,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Achieved Period (days)',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final selectedPeriod = await showModalBottomSheet<int>(
                        context: context,
                        builder: (ctx) {
                          int tempPeriod = int.tryParse(_goalPeriod.text) ?? 30;
                          if (tempPeriod < 30) tempPeriod = 30;
                          if (tempPeriod > 120) tempPeriod = 120;

                          final initialIndex = ((tempPeriod - 30) ~/ 10).clamp(0, 9);

                          return Container(
                            height: 250,
                            child: Column(
                              children: [
                                Expanded(
                                  child: CupertinoPicker(
                                    itemExtent: 40,
                                    scrollController: FixedExtentScrollController(
                                      initialItem: initialIndex,
                                    ),
                                    onSelectedItemChanged: (index) {
                                      tempPeriod = 30 + (index * 10);
                                    },
                                    children: List.generate(
                                      10,
                                      (index) => Center(child: Text('${30 + (index * 10)} days')),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, tempPeriod),
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                      if (selectedPeriod != null) {
                        setState(() => _goalPeriod.text = selectedPeriod.toString());
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Activity level',
                      prefixIcon: Icon(Icons.fitness_center),
                      border: OutlineInputBorder(),
                    ),
                    value: _activityLevel,
                    items: const [
                      DropdownMenuItem(value: 'Sedentary', child: Text('Sedentary (little or no exercise)')),
                      DropdownMenuItem(value: 'Lightly Active', child: Text('Lightly Active (1-3 days/wk)')),
                      DropdownMenuItem(value: 'Moderately Active', child: Text('Moderate (3-5 days/wk)')),
                      DropdownMenuItem(value: 'Very Active', child: Text('Very Active (6-7 days/wk)')),
                    ],
                    onChanged: (value) => setState(() => _activityLevel = value),
                    validator: (value) => value == null ? 'Please select activity level' : null,
                  ),
                  const SizedBox(height: 16),
              
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _loading ? null : _onSignUp,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () {
                             Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const SignInPage()),
                            );
                        },
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}