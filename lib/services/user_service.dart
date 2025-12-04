// lib/services/user_service.dart
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  final supabase = Supabase.instance.client;

  // Load user profile from database
  Future<Map<String, dynamic>?> loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final res = await supabase
          .from("account")
          .select()
          .eq("user_id", user.id)
          .maybeSingle();

      if (res != null) {
        return {
          'username': res["username"] ?? "",
          'profile_image': res["profile_image"] ?? "",
          'height': (res["height"] ?? 0).toDouble(),
          'weight': (res["weight"] ?? 0).toDouble(),
          'goal_weight': (res["goal_weight"] ?? 0).toDouble(),
          'goal_period_days': res["goal_period_days"] ?? 0,
          'tdee': (res["tdee"] ?? 0).toDouble(),
          'recommended_calories': (res["recommended_calories"] ?? 2000).toDouble(),
        };
      }
      return null;
    } catch (e) {
      print("Error loading profile: $e");
      return null;
    }
  }

  // Load today's meal logs
  Future<Map<String, double>> loadTodayLogs() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return {
        'breakfast': 0.0,
        'lunch': 0.0,
        'dinner': 0.0,
        'total_cal': 0.0,
        'total_carb': 0.0,
        'total_protein': 0.0,
        'total_fat': 0.0,
      };
    }

    final today = DateFormat("yyyy-MM-dd").format(DateTime.now());
    
    try {
      final data = await supabase
          .from("calories_log")
          .select()
          .eq("user_id", user.id)
          .eq("log_date", today);

      double breakfastCal = 0;
      double lunchCal = 0;
      double dinnerCal = 0;
      double totalCal = 0;
      double totalCarb = 0;
      double totalProtein = 0;
      double totalFat = 0;

      for (var row in data) {
        final meal = (row["meal_type"] ?? "").toString();
        final cal = (row["calories"] ?? 0).toDouble();

        if (meal == "breakfast") breakfastCal += cal;
        if (meal == "lunch") lunchCal += cal;
        if (meal == "dinner") dinnerCal += cal;

        totalCal += cal;
        totalCarb += (row["carbs"] ?? 0).toDouble();
        totalProtein += (row["protein"] ?? 0).toDouble();
        totalFat += (row["fat"] ?? 0).toDouble();
      }

      return {
        'breakfast': breakfastCal,
        'lunch': lunchCal,
        'dinner': dinnerCal,
        'total_cal': totalCal,
        'total_carb': totalCarb,
        'total_protein': totalProtein,
        'total_fat': totalFat,
      };
    } catch (e) {
      print("Error fetching today's logs: $e");
      return {
        'breakfast': 0.0,
        'lunch': 0.0,
        'dinner': 0.0,
        'total_cal': 0.0,
        'total_carb': 0.0,
        'total_protein': 0.0,
        'total_fat': 0.0,
      };
    }
  }

  // Load weekly calorie points
  Future<List<double>> loadWeeklyPoints() async {
    final user = supabase.auth.currentUser;
    if (user == null) return List.filled(7, 0.0);

    final today = DateTime.now();
    final sunday = today.subtract(Duration(days: today.weekday % 7));

    List<double> points = List.filled(7, 0.0);

    try {
      for (int i = 0; i < 7; i++) {
        final day = sunday.add(Duration(days: i));
        final dayStr = DateFormat("yyyy-MM-dd").format(day);

        final rows = await supabase
            .from("calories_log")
            .select()
            .eq("user_id", user.id)
            .eq("log_date", dayStr);

        double dayTotal = 0;
        for (var r in rows) {
          dayTotal += (r["calories"] ?? 0).toDouble();
        }
        points[i] = dayTotal;
      }

      return points;
    } catch (e) {
      print("Error loading weekly points: $e");
      return List.filled(7, 0.0);
    }
  }

  // Fetch recommended diet from Edge Function
  Future<Map<String, dynamic>?> fetchRecommendedDiet({
    required int recommendedCalories,
    required List<String> specialConditions,
    required String allergies,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final body = {
      "recommended_calories": recommendedCalories,
      "special_conditions": specialConditions,
      "allergies": allergies.trim().isEmpty ? "none" : allergies.trim(),
    };

    final url = Uri.parse(dotenv.env['RECOMMENDED_URL']!);

    try {
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${dotenv.env['SUPABASE_ANON_KEY']}",
        },
        body: jsonEncode(body),
      );

      print("Response status: ${res.statusCode}");
      print("Response body: ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        print("Failed to fetch diet: ${res.body}");
        return null;
      }
    } catch (e) {
      print("Error calling recommended diet function: $e");
      return null;
    }
  }
}