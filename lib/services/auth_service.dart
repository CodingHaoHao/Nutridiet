import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  //Sign In
  Future<User> signInWithUsernameOrEmail({
    required String input,
    required String password,
  }) async {
    final trimmed = input.trim();
    final isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(trimmed);
    String email;

    if (isEmail) {
      email = trimmed;
    } else {
      try {
        final lookup = await _client
            .from('account')
            .select('email')
            .eq('username', trimmed)
            .maybeSingle();

        if (lookup == null || lookup['email'] == null) {
          throw Exception('No account found for that username.');
        }
        email = lookup['email'] as String;
      } on PostgrestException catch (e) {
        throw Exception(e.message);
      } catch (e) {
        throw Exception('Failed to lookup username: $e');
      }
    }

    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password.trim(),
      );

      if (res.user == null) {
        throw Exception('Invalid email/username or password.');
      }
      return res.user!;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  //Sign Up
  Future<void> signUpAndCreateProfile({
      required String username,
      required String email,
      required String password,
      String? birthday,
      String? gender,
      double? height,
      double? weight,
      double? goalWeight,
      int? goalPeriodDays,
      String? activityLevel,
      int? bmr,
      int? tdee,
      int? calorieGoal, required int recommendedCalories,
    }) async {

      if (username.trim().isEmpty) {
        throw Exception('Username cannot be empty');
      }

      try {
        final authRes = await _client.auth.signUp(
          email: email.trim(),
          password: password.trim(),
        );

        if (authRes.user == null) {
          throw Exception('Unable to create user account. Please try again.');
        }

        final userId = authRes.user!.id;

        final inserted = await _client.from('account').insert({
          'user_id': userId,
          'username': username.trim(),
          'email': email.trim(),
          'birthday': birthday,
          'gender': gender,
          'height': height,
          'weight': weight,
          'goal_weight': goalWeight,
          'goal_period_days': goalPeriodDays,
          'activity_level': activityLevel,
          'bmr': bmr,
          'tdee': tdee,
          'recommended_calories': recommendedCalories,
        }).select().maybeSingle();

        if (inserted == null) {
          throw Exception('Failed to create profile row.');
        }
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          throw Exception('Username or email already exists.');
        }
        throw Exception(e.message);
      } catch (e) {
        throw Exception('Sign-up failed: $e');
      }
    }

    Future<void> signOut() async => _client.auth.signOut();
  }