import 'package:flutter/material.dart';

class UpgradePlansPage extends StatelessWidget {
  const UpgradePlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);
    const Color pageBackground = Color(0xFFF9FBFF);

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text(
          'Upgrade Plans',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Choose the plan that fits your health goals ↓↓↓",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              _buildPlanCard(
                context,
                title: "Free Plan",
                price: "Current Plan",
                color: Colors.greenAccent,
                icon: Icons.emoji_events,
                features: const [
                  "Basic calorie tracking",
                  "AI food recognition",
                  "Health summary dashboard",
                  "Health AI assistant"
                ],
                buttonLabel: "Unlocked",
                highlight: true,
                isCurrent: true,
              ),

              _buildPlanCard(
                context,
                title: "Advanced Plan",
                price: "RM20 / month",
                color: Colors.orangeAccent,
                icon: Icons.trending_up,
                features: const [
                  "Basic calorie tracking",
                  "AI food recognition",
                  "Health summary dashboard",
                  "Health AI assistant",
                  "Daily food recommendation",
                  "Daily water intake logging",
                  "Health insights summary",
                  "Priority updates and support",
                ],
                buttonLabel: "Upgrade Now",
              ),

              _buildPlanCard(
                context,
                title: "Super Plan",
                price: "RM50 / month",
                color: Colors.purpleAccent,
                icon: Icons.star,
                features: const [
                  "Basic calorie tracking",
                  "AI food recognition",
                  "Health summary dashboard",
                  "Health AI assistant",
                  "Daily food recommendation",
                  "Daily water intake logging",
                  "Recipe suggestions for all foods",
                  "Personal AI Nutritionist",
                  "1 to 1 diet consultation access",
                ],
                buttonLabel: "Upgrade Now",
              ),

              const SizedBox(height:10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.info_outline, color: primaryColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You can cancel or change your plan anytime.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required Color color,
    required IconData icon,
    required List<String> features,
    required String buttonLabel,
    bool isCurrent = false,
    bool highlight = false,
  }) {
    const Color primaryColor = Color(0xFF6C63FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: highlight
            ? Border.all(color: primaryColor, width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.35),
            child: Icon(icon, color: primaryColor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontSize: 15,
              color: highlight ? primaryColor : Colors.black54,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: isCurrent
                ? null
                : () {
                    _showUpgradeDialog(context, title, price);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isCurrent ? Colors.grey.shade300 : primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              buttonLabel,
              style: TextStyle(
                color: isCurrent ? Colors.black54 : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, String plan, String price) {
    const Color primaryColor = Color(0xFF6C63FF);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.star, color: primaryColor),
            const SizedBox(width: 15),
            Text("$plan"),
          ],
        ),
        content: Text(
          "Unlock premium features for $price.\nWould you like to continue?",
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Further development in progress..."),
                  backgroundColor: Colors.black87,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
             child: const Text("Confirm",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
