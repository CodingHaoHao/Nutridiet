import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class LoggingPage extends StatefulWidget {
  const LoggingPage({super.key});

  @override
  State<LoggingPage> createState() => _LoggingPageState();
}

class _LoggingPageState extends State<LoggingPage> {
  final ImagePicker _picker = ImagePicker();
  final supabase = Supabase.instance.client;

  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> breakfast = [];
  List<Map<String, dynamic>> lunch = [];
  List<Map<String, dynamic>> dinner = [];

  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color pageBackground = Color(0xFFF9FBFF);
  DateTime _weekStart = DateTime.now();
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
    _loadLogsForDate(_selectedDate);
  }

  Future<void> _loadLogsForDate(DateTime date) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final iso = DateFormat('yyyy-MM-dd').format(date);
      final res = await supabase
          .from('calories_log')
          .select()
          .eq('user_id', user.id)
          .eq('log_date', iso)
          .order('created_at', ascending: true);

      breakfast.clear();
      lunch.clear();
      dinner.clear();

      for (final r in res) {
        final meal = (r['meal_type'] ?? '').toString().toLowerCase();
        final entry = {
          'id': r['id'],
          'name': r['name'],
          'calories': r['calories'],
          'carbs': r['carbs'],
          'protein': r['protein'],
          'fat': r['fat'],
          'imageUrl': r['image_url'],
          'time': r['created_at'],
        };

        if (meal == 'breakfast') {
          breakfast.add(entry);
        } else if (meal == 'lunch') {
          lunch.add(entry);
        } else {
          dinner.add(entry);
        }
      }
      setState(() {});
    } catch (e) {
      debugPrint('Load logs error (possible missing table): $e');
    }
  }

  Future<String?> _uploadImageToSupabase(File imageFile) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    final fileExt = imageFile.path.split('.').last;
    final fileName =
        'user_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'uploads/$fileName';
    try {
      await supabase.storage.from('assistant_page').uploadBinary(
            filePath,
            await imageFile.readAsBytes(),
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      final url = supabase.storage.from('assistant_page').getPublicUrl(filePath);
      return url;
    } catch (e) {
      debugPrint('upload error: $e');
      return null;
    }
  }

  Map<String, dynamic> _parseNutritionText(String text, {String fallbackName = 'Unknown'}) {
    String name = '';
    double calories = 0, carbs = 0, protein = 0, fat = 0;

    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (final line in lines) {
      final lower = line.toLowerCase();
      final numMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(line);
      final numVal = numMatch != null ? double.tryParse(numMatch.group(0)!) : null;

      if (lower.startsWith('food name')) name = line.split(':').last.trim();
      else if (lower.contains('calorie')) calories = numVal ?? calories;
      else if (lower.contains('carb')) carbs = numVal ?? carbs;
      else if (lower.contains('protein')) protein = numVal ?? protein;
      else if (lower.contains('fat')) fat = numVal ?? fat;
    }

    return {
      'name': name.isEmpty ? fallbackName : name,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
    };
  }

  Future<Map<String, String>?> _showManualFoodDialog() async {
    final nameController = TextEditingController();
    final portionController = TextEditingController();

    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Food Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Food name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Portion(grams)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty || portionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter food name and portion size.')),
                );
                return;
              }
              Navigator.pop(ctx, {
                'name': nameController.text.trim(),
                'portion': portionController.text.trim(),
              });
            },
            child: const Text('Analyze'),
          ),
        ],
      ),
    );
    return res;
  }

  Future<Map<String, dynamic>?> _analyzeManualFood(String foodName, String portion) async {
    final url = Uri.parse(dotenv.env['CHAT_BACKEND_URL'] ?? '');
    if (url.toString().isEmpty) return null;

    final prompt = """
    You are a nutrition expert. Estimate the **total nutrition** of this meal:
    Food: $foodName
    Portion: $portion grams

    Respond in this exact format (no explanations):
    Food name: [short descriptive name]
    Calories: [number] kcal
    Carbs: [number] g
    Protein: [number] g
    Fat: [number] g
    """;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY'] ?? ''}',
        },
        body: jsonEncode({'message': prompt}),
      );

      if (response.statusCode != 200) {
        debugPrint('AI error: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body);
      final text = (data['assistant'] ?? '').toString();

      return _parseNutritionText(text, fallbackName: foodName);
    } catch (e) {
      debugPrint('Manual analyze error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _analyzeImageWithAI(String? imageUrl, File? localFile, String userText) async {
    final url = Uri.parse(dotenv.env['CHAT_BACKEND_URL'] ?? '');
    if (url.toString().isEmpty) return null;

    String? base64Image;
    if (localFile != null) {
      final bytes = await localFile.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    final analysisPrompt = """
    You are a nutrition analysis expert. Analyze the entire meal shown in the image, including all visible food items (for example: rice, curry, egg, cucumber, side dishes, sauces, and any drink if visible). 
    Estimate the **total combined nutrition** of the full meal. 

    Respond strictly in this fixed format (no explanation text, no bullet points):
    Food name: [Short descriptive name of the whole meal]
    Calories: [number] kcal
    Carbs: [number] g
    Protein: [number] g
    Fat: [number] g
    """;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY'] ?? ''}',
        },
        body: jsonEncode({
          'message': analysisPrompt,
          'imageBase64': base64Image,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('AI backend returned ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body);
      final assistantText = (data['assistant'] ?? '').toString();
      final parsed = _parseNutritionText(assistantText, fallbackName: 'Scanned Food');

      return {
        ...parsed,
        'raw': assistantText,
        'imageUrl': imageUrl,
      };
    } catch (e) {
      debugPrint('AI analyze error: $e');
      return null;
    }
  }

  String _guessMealTypeByTime(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return 'breakfast';
    if (hour >= 12 && hour < 18) return 'lunch';
    return 'dinner';
  }

  Future<void> _pickAndScan({required String targetMeal}) async {
    final option = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Upload Image'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: const Text('Enter food name manually'),
                onTap: () => Navigator.pop(ctx, 'manual'),
              ),
            ],
          ),
        );
      },
    );

    if (option == null) return;

    if (option == 'manual') {
      final input = await _showManualFoodDialog();
      if (input == null) return;

      
      final aiResult = await _analyzeManualFood(input['name']!, input['portion']!);

      if (aiResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to analyze food.')),
        );
     
        return;
      }

      final entry = {
        'name': aiResult['name'],
        'calories': aiResult['calories'],
        'carbs': aiResult['carbs'],
        'protein': aiResult['protein'],
        'fat': aiResult['fat'],
        'imageUrl': null,
        'time': DateTime.now().toIso8601String(),
      };

      await _addEntryToMeal(targetMeal, entry, persist: true);
      
      return;
    }

    final source = option == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final uploadedUrl = await _uploadImageToSupabase(file);
    final aiResult = await _analyzeImageWithAI(uploadedUrl, file, '');

    if (aiResult == null) {
      final fallback = {
        'name': 'Scanned Food',
        'calories': 0,
        'carbs': 0,
        'protein': 0,
        'fat': 0,
        'imageUrl': uploadedUrl,
        'time': DateTime.now().toIso8601String(),
      };
      _addEntryToMeal(targetMeal, fallback, persist: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not analyze image — saved image only.')),
      );
      return;
    }

    final entry = {
      'name': aiResult['name'],
      'calories': aiResult['calories'],
      'carbs': aiResult['carbs'],
      'protein': aiResult['protein'],
      'fat': aiResult['fat'],
      'imageUrl': aiResult['imageUrl'],
      'time': DateTime.now().toIso8601String(),
    };

    await _addEntryToMeal(targetMeal, entry, persist: true);
    
  }

  Future<void> _addEntryToMeal(String mealType, Map<String, dynamic> entry, {bool persist = false}) async {
    setState(() {
      if (mealType == 'breakfast') {
        breakfast.insert(0, entry);
      } else if (mealType == 'lunch') {
        lunch.insert(0, entry);
      } else {
        dinner.insert(0, entry);
      }
    });

    if (!persist) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final logDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      await supabase.from('calories_log').insert({
        'user_id': user.id,
        'log_date': logDate,
        'meal_type': mealType,
        'name': entry['name'],
        'calories': entry['calories'],
        'carbs': entry['carbs'],
        'protein': entry['protein'],
        'fat': entry['fat'],
        'image_url': entry['imageUrl'],
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to persist food log: $e (table calories_log may not exist)');
    }
  }

  Widget _buildWeekSelector() {
    _weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
    if (_weekStart.weekday != DateTime.sunday) {
      _weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday));
    }

    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return Container(
      height: 78,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              final prevWeek = _weekStart.subtract(const Duration(days: 7));
              final firstDayOfMonth = DateTime(_today.year, _today.month - 1, 1);

              if (prevWeek.isAfter(firstDayOfMonth) ||
                  prevWeek.month == _weekStart.month - 1) {
                setState(() {
                  _weekStart = prevWeek;
                  _selectedDate = _weekStart;
                  _loadLogsForDate(_selectedDate);
                });
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(Icons.chevron_left, size: 20, color: primaryPurple),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: days.map((d) {
                  final isSelected = DateFormat('yyyy-MM-dd').format(d) ==
                      DateFormat('yyyy-MM-dd').format(_selectedDate);
                  final isFuture = d.isAfter(_today);

                  return GestureDetector(
                    onTap: isFuture
                        ? null
                        : () {
                            setState(() {
                              _selectedDate = d;
                              _loadLogsForDate(d);
                            });
                          },
                    child: Opacity(
                      opacity: isFuture ? 0.4 : 1.0,
                      child: Container(
                        width: 56, 
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryPurple.withOpacity(0.12) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? primaryPurple : Colors.transparent,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEE').format(d),
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? primaryPurple : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              DateFormat('d').format(d),
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected ? primaryPurple : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              DateFormat('MMM').format(d),
                              style: const TextStyle(fontSize: 9, color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          InkWell(
            onTap: () {
              final nextWeek = _weekStart.add(const Duration(days: 7));
              final thisWeekStart = _today.subtract(Duration(days: _today.weekday % 7));
              final thisWeekEnd = thisWeekStart.add(const Duration(days: 6));
              if (!nextWeek.isAfter(thisWeekEnd)) {
                setState(() {
                  _weekStart = nextWeek;
                  _selectedDate = _weekStart;
                  _loadLogsForDate(_selectedDate);
                });
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(Icons.chevron_right, size: 20, color: primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPanel(String title, List<Map<String, dynamic>> items, String mealKey) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0,4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
              const Spacer(),
              IconButton(
                onPressed: () => _pickAndScan(targetMeal: mealKey),
                icon: const Icon(Icons.add_circle_outline, size: 28, color: primaryPurple),
              )
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Expanded(child: Text('No items yet. Tap + to add or scan a meal.', style: TextStyle(color: Colors.black54))),
                ],
              ),
            )
          else
            Column(
              children: items.map((it) => _buildFoodRow(it)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodRow(Map<String, dynamic> it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 78,
              height: 78,
              color: Colors.grey.shade100,
              child: it['imageUrl'] != null
                  ? Image.network(it['imageUrl'], fit: BoxFit.cover, errorBuilder: (c,e,s)=> const Icon(Icons.broken_image))
                  : const Icon(Icons.fastfood_outlined, size: 36, color: Colors.black26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it['name'] ?? 'Food',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  ' • ${(it['calories'] ?? 0).toString()} kcal\n • ${(it['carbs'] ?? 0).toString()} g carbs\n • ${(it['protein'] ?? 0).toString()} g protein\n • ${(it['fat'] ?? 0).toString()} g fat',
                  style: const TextStyle(color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              onPressed: () => _removeEntry(it),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _removeEntry(Map<String, dynamic> item) async {
    try {
      final id = item['id'];
      if (id != null) {
        final res = await supabase.from('calories_log').delete().eq('id', id);
        debugPrint('Delete response: $res');
      }
      setState(() {
        breakfast.removeWhere((e) => e['id'] == item['id']);
        lunch.removeWhere((e) => e['id'] == item['id']);
        dinner.removeWhere((e) => e['id'] == item['id']);
      });
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadLogsForDate(_selectedDate);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete. Please try again.')),
      );
    }
  }

  Widget _buildNutrientOverview() {
  double totalCal = 0, totalCarb = 0, totalProtein = 0, totalFat = 0;
  final all = [...breakfast, ...lunch, ...dinner];
  for (final it in all) {
    totalCal += (it['calories'] ?? 0) as num;
    totalCarb += (it['carbs'] ?? 0) as num;
    totalProtein += (it['protein'] ?? 0) as num;
    totalFat += (it['fat'] ?? 0) as num;
  }

  return FutureBuilder(
    future: _fetchRecommendedCalories(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(color: primaryPurple),
          ),
        );
      }

      final recommended = snapshot.data ?? 2000.0;
      final progress = (totalCal / recommended).clamp(0.0, 1.0);
      final exceeded = totalCal > recommended;
      final progressColor = exceeded ? Colors.redAccent : primaryPurple;
      final calColor = exceeded ? Colors.redAccent : Colors.orangeAccent;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _smallStat('Calories', '${totalCal.toInt()} / ${recommended.toInt()} kcal', calColor),
                _smallStat('Carbs', '${totalCarb.toInt()}g', Colors.green),
                _smallStat('Protein', '${totalProtein.toInt()}g', Colors.blue),
                _smallStat('Fat', '${totalFat.toInt()}g', Colors.redAccent),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                exceeded
                    ? "Exceeded daily calories goal"
                    : "${(progress * 100).toStringAsFixed(0)}% of daily goal",
                style: TextStyle(
                  color: exceeded ? Colors.redAccent : Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<double?> _fetchRecommendedCalories() async {
    final user = supabase.auth.currentUser;
    if (user == null) return 2000; 

    try {
      final res = await supabase
          .from('account')
          .select('recommended_calories')
          .eq('user_id', user.id)
          .maybeSingle();

      if (res == null || res['recommended_calories'] == null) return 2000;
      return (res['recommended_calories'] as num).toDouble();
    } catch (e) {
      debugPrint('Error fetching recommended calories: $e');
      return 2000;
    }
  }

  Widget _smallStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
  final headerText = DateFormat('EEEE, MMM d, yyyy').format(_selectedDate);

  return Scaffold(
    backgroundColor: pageBackground,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Column(
        children: [
          const Text('Logging Page', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(headerText, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      actions: [
    IconButton(
      icon: const Icon(Icons.refresh, color: Colors.black87),
      tooltip: 'Reload Data',
      onPressed: () async {
        await _loadLogsForDate(_selectedDate);
        setState(() {}); 
      },
    ),
  ],
    ),
    body: SafeArea(
    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeekSelector(),
          _buildNutrientOverview(),
          _buildMealPanel('Breakfast', breakfast, 'breakfast'),
          _buildMealPanel('Lunch', lunch, 'lunch'),
          _buildMealPanel('Dinner', dinner, 'dinner'),
          const SizedBox(height: 80),
        ],
      ),
    ),
  ),

  floatingActionButton: FloatingActionButton.extended(
    backgroundColor: primaryPurple,
    onPressed: () => _pickAndScan(targetMeal: _guessMealTypeByTime(DateTime.now())),
    label: const Text('Scan Meal'),
    icon: const Icon(Icons.qr_code_scanner),
  ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
