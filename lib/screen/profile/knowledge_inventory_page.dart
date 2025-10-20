import 'package:flutter/material.dart';

class KnowledgeInventoryPage extends StatelessWidget {
  const KnowledgeInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color pageBackground = Color(0xFFF9FBFF);

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text(
          'Knowledge Inventory',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Center(
                      child: Text(
                        'NutriDiet Knowledge Inventory',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'This page will provides the nutrition knowledges and calculations to count the recommended calories which helps you to reach your goal weight in estimate period.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 12),

                    Text(
                      '1. Basal Metabolic Rate (BMR)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '''BMR stands for 'Basal Metabolic Rate', it refers to the number of calories that your body needs to maintain basic functions such as breathing, blood circulation, and cell production.
                      \nIt represents the minimum amount of energy required to keep your body functioning.
                      \nFormulas used:\n• For Men: \nBMR = (10 × weight in kg) + (6.25 × height in cm) – (5 × age in years) + 5\n\n• For Women: \nBMR = (10 × weight in kg) + (6.25 × height in cm) – (5 × age in years) – 161\n''',
                      style: TextStyle(fontSize: 15, height: 1.6),
                      textAlign: TextAlign.justify,
                    ),

                    Text(
                      '2. Activity Level',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '''Activity level represents the amount and intensity of physical movement a person performs, classifying individuals from inactive to highly active based on their daily energy expenditure through bodily movement. It helps adjust your BMR to estimate your Total Daily Energy Expenditure (TDEE).
                      \nThe standard multipliers used are:\n• Sedentary: BMR × 1.2 \n→ Little or no exercise\n\n• Lightly Active: BMR × 1.375 \n→ Light exercise (1–3 days/week)\n\n• Moderately Active: BMR × 1.55 \n→ Moderate exercise (3–5 days/week)\n\n• Very Active: BMR × 1.725 \n→ Heavy exercise (6–7 days/week)\n''',
                      style: TextStyle(fontSize: 15, height: 1.6),
                      textAlign: TextAlign.justify,
                    ),

                    Text(
                      '3. Total Daily Energy Expenditure (TDEE)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '''TDEE stands for Total Daily Energy Expenditure. It estimates the total number of calories you burn per day, taking into account your BMR and activity level.\n\nFormula:\nTDEE = BMR × Activity Level\n\nThis value shows how many calories you need daily to maintain your current weight.\n''',
                      style: TextStyle(fontSize: 15, height: 1.6),
                      textAlign: TextAlign.justify,
                    ),

                    Text(
                      '4. Goal Calories Calculation',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '''Your goal calories depend on whether you want to lose or gain weight.\n\nSteps to calculate:\n1. Identify your goal (lose or gain weight)\n2. Find the weight difference (Current Weight − Goal Weight)\n3. Multiply each 1 kg by 7700 kcal to gain total calories (1kg = 7700 kcal)\n4. Divide total calories by your goal period (days) to get daily calories deficit.\n5. Substract the daily calories deficit from your daily total TDEE to get daily recommended calories.\n\nExample:\nCurrent Weight = 75 kg\nGoal Weight = 70 kg\nGoal Period = 60 days\nWeight Difference = 75kg - 70kg = 5 kg → 5 × 7700 = 38500 kcal\nDaily Deficit = 38500 kcal ÷ 60 days = 641.67 kcal/day\nTDEE = 2709 kcal\nRecommended Intake = 2709 − 641.67 = 2067.33 kcal/day\n\nIf you aim to gain weight, add the surplus instead of subtracting.\n ''',
                      style: TextStyle(fontSize: 15, height: 1.6),
                      textAlign: TextAlign.justify,
                    ),

                    Text(
                      '5. Important Notes',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '''• A calorie deficit leads to weight loss, while a surplus promotes weight gain.\n• Rapid weight loss or gain can be unhealthy, gradual changes are more sustainable.\n• A daily calorie deficit is recommended below 750 kcal/days for health reasons.\n• TDEE and calorie needs vary by metabolism, genetics, and lifestyle.''',
                      style: TextStyle(fontSize: 15, height: 1.6),
                      textAlign: TextAlign.justify,
                    ),

                    SizedBox(height: 30),
                    Center(
                      child: Text(
                        "Stay learning nutrition knowledge and make smarter health choices 💪",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
