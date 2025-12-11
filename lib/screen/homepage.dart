import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/user_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserService _userService = UserService();

  // User profile data
  String username = "";
  String profileImage = "";
  double height = 0;
  double weight = 0;
  double goalWeight = 0;
  String goalPeriod = "";
  double tdee = 0;
  double recommended = 2000;

  // Today's meal data
  double breakfastCal = 0;
  double lunchCal = 0;
  double dinnerCal = 0;
  double totalCal = 0;
  double totalCarb = 0;
  double totalProtein = 0;
  double totalFat = 0;

  // Weekly chart data
  List<double> weeklyPoints = List.filled(7, 0.0);

  // Recommended diet data
  final allergyController = TextEditingController();
  Map<String, dynamic>? recommendedDiet;
  bool _isGeneratingDiet = false;
  List<String> selectedConditions = [];
  
  final List<String> specialConditions = [
    'Vegetarian',
    'Vegan',
    'Halal',
    'Indian',
    'Diabetes',
    'High Blood Pressure',
    'High Cholesterol',
    'No Any'
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // Load all data on init
  Future<void> _loadAllData() async {
    await _loadProfile();
    await _loadTodayLogs();
    await _loadWeeklyPoints();
  }

  // Load user profile
  Future<void> _loadProfile() async {
    final profile = await _userService.loadProfile();
    if (profile != null && mounted) {
      setState(() {
        username = profile['username'];
        profileImage = profile['profile_image'];
        height = profile['height'];
        weight = profile['weight'];
        goalWeight = profile['goal_weight'];
        goalPeriod = "${profile['goal_period_days']} days";
        tdee = profile['tdee'];
        recommended = profile['recommended_calories'];
      });
    }
  }

  // Load today's meal logs
  Future<void> _loadTodayLogs() async {
    final logs = await _userService.loadTodayLogs();
    if (mounted) {
      setState(() {
        breakfastCal = logs['breakfast']!;
        lunchCal = logs['lunch']!;
        dinnerCal = logs['dinner']!;
        totalCal = logs['total_cal']!;
        totalCarb = logs['total_carb']!;
        totalProtein = logs['total_protein']!;
        totalFat = logs['total_fat']!;
      });
    }
  }

  // Load weekly calorie points
  Future<void> _loadWeeklyPoints() async {
    final points = await _userService.loadWeeklyPoints();
    if (mounted) {
      setState(() {
        weeklyPoints = points;
      });
    }
  }

  // Fetch recommended diet
  Future<void> _fetchRecommendedDiet() async {
    if (selectedConditions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one special condition")),
      );
      return;
    }

    setState(() {
      recommendedDiet = null;
      _isGeneratingDiet = true;
    });

    final result = await _userService.fetchRecommendedDiet(
      recommendedCalories: recommended.toInt(),
      specialConditions: selectedConditions,
      allergies: allergyController.text,
    );

    if (mounted) {
      setState(() {
        _isGeneratingDiet = false;
        if (result != null) {
          recommendedDiet = result;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Diet plan generated successfully!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to generate diet plan")),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (totalCal / recommended).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("Home", style: TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 20),
              _buildProfileSummary(),
              const SizedBox(height: 15),
              _buildTodaysMeals(),
              const SizedBox(height: 15),
              _buildCaloriesProgress(progress),
              const SizedBox(height: 25),
              _buildWeeklyChart(),
              const SizedBox(height: 25),
              _buildRecommendedDietSection(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // Welcome section widget
  Widget _buildWelcomeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, $username !", 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text("Complete your nutrition goal today", 
              style: TextStyle(color: Colors.black54, fontSize: 14)),
          ],
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black38, width: 1.4),
            image: DecorationImage(
              image: profileImage.isNotEmpty 
                  ? AssetImage(profileImage) 
                  : const AssetImage("assets/profile/male_profile1.jpg"),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  // Profile summary tiles
  Widget _buildProfileSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double itemWidth = (constraints.maxWidth - 24) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: itemWidth, child: _infoTile("Height", "$height cm")),
            SizedBox(width: itemWidth, child: _infoTile("Weight", "$weight kg")),
            SizedBox(width: itemWidth, child: _infoTile("Goal Weight", "$goalWeight kg")),
            SizedBox(width: itemWidth, child: _infoTile("Goal Period", goalPeriod)),
            SizedBox(width: itemWidth, child: _infoTile("TDEE", tdee.toStringAsFixed(0))),
            SizedBox(width: itemWidth, child: _infoTile("Recommended", "${recommended.toInt()} kcal")),
          ],
        );
      },
    );
  }

  // Today's meals section
  Widget _buildTodaysMeals() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Today's Meals", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAllData,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _mealBox("Breakfast", breakfastCal, Colors.orange)),
            const SizedBox(width: 10),
            Expanded(child: _mealBox("Lunch", lunchCal, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _mealBox("Dinner", dinnerCal, Colors.purple)),
          ],
        ),
      ],
    );
  }

  // Calories progress section
  Widget _buildCaloriesProgress(double progress) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 8, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        children: [
          Text("${totalCal.toInt()} / ${recommended.toInt()} kcal", 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation(Colors.purpleAccent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(children: [
                const Text("Carbs", style: TextStyle(color: Colors.black54)), 
                Text("${totalCarb.toInt()} g", 
                  style: const TextStyle(fontWeight: FontWeight.bold))
              ]),
              Column(children: [
                const Text("Protein", style: TextStyle(color: Colors.black54)), 
                Text("${totalProtein.toInt()} g", 
                  style: const TextStyle(fontWeight: FontWeight.bold))
              ]),
              Column(children: [
                const Text("Fat", style: TextStyle(color: Colors.black54)), 
                Text("${totalFat.toInt()} g", 
                  style: const TextStyle(fontWeight: FontWeight.bold))
              ]),
            ],
          ),
        ],
      ),
    );
  }

  // Weekly chart section
  Widget _buildWeeklyChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Weekly Calories Chart", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200, 
            child: _buildWeeklyCalChart(),
          ),
          const SizedBox(height: 12),
          _buildChartDescription(),
        ],
      ),
    );
  }

  // Build weekly calories chart
  Widget _buildWeeklyCalChart() {
    final spots = List<FlSpot>.generate(
      7,
      (i) => FlSpot((i + 1).toDouble(), weeklyPoints[i]),
    );

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: 7,
        minY: 0,
        maxY: 3500,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 500,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.12),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: 500,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), 
                  style: const TextStyle(fontSize: 12));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                final idx = value.toInt() - 1;
                return Text(labels[idx], style: const TextStyle(fontSize: 12));
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true, 
          border: Border.all(color: Colors.black26)
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            barWidth: 3,
            color: Colors.red,
            dotData: FlDotData(show: true),
          ),
          LineChartBarData(
            spots: [
              FlSpot(1, recommended.clamp(0, 3500)),
              FlSpot(7, recommended.clamp(0, 3500)),
            ],
            color: Colors.blue,
            barWidth: 2,
            isCurved: false,
            dotData: FlDotData(show: false),
            dashArray: [6, 4],
          ),
        ],
      ),
    );
  }

  // Chart description
  Widget _buildChartDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text("Recommended calories",
                style: TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text("Daily taken calories",
                style: TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  // Recommended diet section
  Widget _buildRecommendedDietSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Recommended Diet Plan",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          const Text("Special Conditions:",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, 
              color: Colors.black87)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specialConditions.map((condition) {
              final isSelected = selectedConditions.contains(condition);
              final isNoAny = condition == "No Any";
              final disable =
                  (isNoAny && selectedConditions.any((r) => r != "No Any")) ||
                  (!isNoAny && selectedConditions.contains("No Any"));

              return FilterChip(
                label: Text(condition),
                selected: isSelected,
                showCheckmark: false,
                onSelected: disable
                    ? null 
                    : (selected) {
                        setState(() {
                          if (selected) {
                            if (isNoAny) {
                              selectedConditions = ["No Any"];
                            } else {
                              selectedConditions.remove("No Any");
                              selectedConditions.add(condition);
                            }
                          } else {
                            selectedConditions.remove(condition);
                          }
                        });
                      },
                selectedColor: Colors.deepPurple.shade100,
                backgroundColor: Colors.grey.shade100,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.deepPurple.shade700 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                  width: 1,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),

          // Allergies input
          TextField(
            controller: allergyController,
            decoration: InputDecoration(
              labelText: "Allergies (if any)",
              hintText: "e.g., peanuts, seafood",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGeneratingDiet ? null : _fetchRecommendedDiet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: _isGeneratingDiet
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text("Generating...",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, 
                            color: Colors.white)),
                      ],
                    )
                  : const Text("Generate Diet Plan",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, 
                        color: Colors.white)),
            ),
          ),

          if (recommendedDiet != null) ...[
            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            _buildNutritionGoals(),
            const SizedBox(height: 20),
            _buildMealSuggestions(),
            const SizedBox(height: 20),
            _buildHealthSummary(),
          ],
        ],
      ),
    );
  }

  // Nutrition goals widget
  Widget _buildNutritionGoals() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Daily Nutritional Goals",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, 
              color: Colors.deepPurple)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _nutritionTile("Calories", 
                "${recommendedDiet!['daily_calories'] ?? '-'} kcal",
                Icons.local_fire_department, Colors.orange),
              _nutritionTile("Carbs", 
                "${recommendedDiet!['carbs'] ?? '-'} g",
                Icons.grain, Colors.brown),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _nutritionTile("Protein", 
                "${recommendedDiet!['protein'] ?? '-'} g",
                Icons.egg, Colors.red),
              _nutritionTile("Fat", 
                "${recommendedDiet!['fat'] ?? '-'} g",
                Icons.opacity, Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  // Meal suggestions widget
  Widget _buildMealSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Meal Suggestions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _mealCard("Breakfast", 
          recommendedDiet!['breakfast'] ?? 'No recommendation',
          Colors.orange.shade100, Colors.orange.shade700),
        const SizedBox(height: 12),
        _mealCard("Lunch", 
          recommendedDiet!['lunch'] ?? 'No recommendation',
          Colors.blue.shade100, Colors.blue.shade700),
        const SizedBox(height: 12),
        _mealCard("Dinner", 
          recommendedDiet!['dinner'] ?? 'No recommendation',
          Colors.purple.shade100, Colors.purple.shade700),
      ],
    );
  }

  // Health summary widget
  Widget _buildHealthSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text("Health Summary",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, 
                  color: Colors.green.shade700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(recommendedDiet!['summary'] ?? 'No summary available',
            style: TextStyle(fontSize: 14, height: 1.5, 
              color: Colors.green.shade900)),
        ],
      ),
    );
  }

  // Info tile widget
  Widget _infoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Meal box widget
  Widget _mealBox(String title, double kcal, Color color) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 8),
          Text("${kcal.toInt()} kcal",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
        ],
      ),
    );
  }

  // Nutrition tile widget
  Widget _nutritionTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 2),
            Text(value, 
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // Meal card widget
  Widget _mealCard(String title, String description, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 8),
          Text(description,
            style: TextStyle(fontSize: 14, height: 1.6, color: textColor.withOpacity(0.9))),
        ],
      ),
    );
  }
}