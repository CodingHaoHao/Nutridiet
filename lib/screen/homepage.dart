import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  String username = "";
  String profileImage = "";
  double breakfastCal = 0;
  double lunchCal = 0;
  double dinnerCal = 0;
  double totalCal = 0;
  double totalCarb = 0;
  double totalProtein = 0;
  double totalFat = 0;
  double height = 0;
  double weight = 0;
  double goalWeight = 0;
  String goalPeriod = "";
  double tdee = 0;
  double recommended = 2000;


  List<double> weeklyPoints = List.filled(7, 0.0);
  double blueGoalLine = 0; // tdee - recommended

  @override
  void initState() {
    super.initState();
    _loadProfile().then((_) async {
      await _loadTodayLogs();
      await _loadWeeklyPoints();
    });
  }

  Future<void> _loadTodayLogs() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final today = DateFormat("yyyy-MM-dd").format(DateTime.now());

    try {
      final data = await supabase
          .from("calories_log")
          .select()
          .eq("user_id", user.id)
          .eq("log_date", today);

      breakfastCal = 0;
      lunchCal = 0;
      dinnerCal = 0;
      totalCal = 0;
      totalCarb = 0;
      totalProtein = 0;
      totalFat = 0;

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
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error fetching today's logs: $e");
    }
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase
          .from("account")
          .select()
          .eq("user_id", user.id)
          .maybeSingle();

      if (res != null) {
        username = res["username"] ?? "";
        profileImage = res["profile_image"] ?? "";
        height = (res["height"] ?? 0).toDouble();
        weight = (res["weight"] ?? 0).toDouble();
        goalWeight = (res["goal_weight"] ?? 0).toDouble();
        goalPeriod = "${res["goal_period_days"] ?? 0} days";
        tdee = (res["tdee"] ?? 0).toDouble();
        recommended = (res["recommended_calories"] ?? 2000).toDouble();
        blueGoalLine = (tdee - recommended);
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _loadWeeklyPoints() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

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

    // reorder → Mon to Sun
    weeklyPoints = [
      points[0], // Sun
      points[1], // Mon
      points[2], // Tue
      points[3], // Wed
      points[4], // Thu
      points[5], // Fri
      points[6], // Sat
    ];

    if (mounted) setState(() {});
  } catch (e) {
    debugPrint("Error loading weekly points: $e");
  }
}

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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _mealBox(String title, double kcal, Color color) {
    return Container(
      width: 110,
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
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 8),
          Text("${kcal.toInt()} kcal",
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15, color: color)),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalChart() {
    final spots = List<FlSpot>.generate(
      7,
      (i) => FlSpot((i + 1).toDouble(), weeklyPoints[i]),
    );

    final List<int> yLabels = [0, 500, 1000, 1500, 2000, 2500, 3000, 3500];

    SideTitles leftTitles = SideTitles(
      showTitles: true,
      reservedSize: 50,
      interval: 500, 
      getTitlesWidget: (value, meta) {
        if (yLabels.contains(value.toInt())) {
          return Text(
            value.toInt().toString(),
            style: const TextStyle(fontSize: 12),
          );
        }
        return const SizedBox.shrink();
      },
    );

    SideTitles bottomTitles = SideTitles(
      showTitles: true,
      interval: 1,
      getTitlesWidget: (value, meta) {
        const labels = ['Sun','Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        final idx = value.toInt() - 1;
        if (idx >= 0 && idx < labels.length) {
          return Text(labels[idx], style: const TextStyle(fontSize: 12));
        }
        return const SizedBox.shrink();
      },
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
          horizontalInterval: 500, // grid lines every 500
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.12),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: leftTitles),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: bottomTitles),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.black26),
        ),
        lineBarsData: [
          // RED = daily total calories
          LineChartBarData(
            spots: spots,
            isCurved: false,
            barWidth: 3,
            color: Colors.red,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, p, bar, index) =>
                  FlDotCirclePainter(radius: 4, color: Colors.black),
            ),
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
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((ts) {
                final y = ts.y.toInt();
                return LineTooltipItem('$y kcal', const TextStyle(color: Colors.black));
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChartDescription() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            const Text(
              "Recommended calories",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
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
            const Text(
              "Daily taken calories",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ],
    ),
  );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome, $username !",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Complete your nutrition goal today",
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
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
              ),
              const SizedBox(height: 20),

              LayoutBuilder(
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
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Meals",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      await _loadProfile();
                      await _loadTodayLogs();
                      await _loadWeeklyPoints();
                    },
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
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
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
                          Text("${totalCarb.toInt()} g", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                        Column(children: [
                          const Text("Protein", style: TextStyle(color: Colors.black54)),
                          Text("${totalProtein.toInt()} g", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                        Column(children: [
                          const Text("Fat", style: TextStyle(color: Colors.black54)),
                          Text("${totalFat.toInt()} g", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              const Text("Weekly Calories Chart", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
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
                    SizedBox(
                      height: 200, 
                      child: _buildWeeklyCalChart(),
                    ),
                    _buildChartDescription(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
