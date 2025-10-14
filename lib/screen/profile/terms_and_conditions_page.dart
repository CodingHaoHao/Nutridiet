import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorPrimary = const Color(0xFF8BD3A3);
    final colorBackground = const Color(0xFFF9FBF9);

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); 
          },
        ),
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
                          'Privacy Policy for NutriDiet',
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
                        'Effective Date: October 4, 2025\n',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '''This Privacy Policy explains how we collect, use, disclose, and protect the personal information you provide or that we collect when you access or use our services when you use our mobile application ("NutriDiet"). It explains your privacy rights and choices, and how to contact us about our privacy practices. Please read this Policy carefully. By using our Platform, you consent to the data practices described in this Policy.''',
                        style: TextStyle(fontSize: 15, height: 1.5),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Entity and Contact Information',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'This Privacy Policy is published on behalf of an individual operator located in Selangor, Malaysia. Business names and registered addresses are not applicable in this case. All references to “I”, “me”, or “my” refer to the individual operator.\n\nIf you have questions or concerns, contact us at:',
                        style: TextStyle(fontSize: 15, height: 1.5),
                        textAlign: TextAlign.justify,
                      ),
                      Text(
                        'colinlowchenghao@gmail.com\n',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '1. Information We Collect',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '''We collect multiple types of information to operate effectively and provide you the best experience, including data you provide directly (name, email, age, gender, body information, etc.), automatically collected technical information and others. Payment, communication and aggregated data are also processed as described.\n''',
                        style: TextStyle(fontSize: 15, height: 1.5),
                        textAlign: TextAlign.justify,
                      ),
                      Text(
                        '2. How We Use Information',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '''We use information to operate and improve our services, authenticate users, manage accounts, process payments, prevent fraud, personalize user experience, perform analytics, and comply with legal obligations.\n''',
                        style: TextStyle(fontSize: 15, height: 1.5),
                        textAlign: TextAlign.justify,
                      ),
                      Text(
                        '3. Legal Bases for Processing',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '''Depending on jurisdiction, we may process data under Consent, Contractual Necessity, Legal Obligation, or Legitimate Interests.\n''',
                        style: TextStyle(fontSize: 15, height: 1.5),
                        textAlign: TextAlign.justify,
                      ),
                      Text(
                        '4. Cookies and Tracking Technologies',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '''We do not use cookies for tracking beyond essential technical cookies required to operate the service.\n''',
                        style: TextStyle(fontSize: 15, height: 1.5),
                        textAlign: TextAlign.justify,
                      ),
                      Text(
                        '5. Advertising and Analytics',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '''We do not display third-party ads or use third-party analytics for tracking purposes beyond internal diagnostics.\n''',
                        style: TextStyle(fontSize: 15, height: 1.5),
                        textAlign: TextAlign.justify,
                      ),
                      Text(
                        '6. Additional Clauses',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '''Remaining sections detail how we handle data transfers, security measures, user privacy, international data laws (GDPR, CCPA), your rights to access or delete data, and how NutriDiet responds to security incidents. We never sell your data and maintain strict confidentiality.\n\nFor full details, refer to the official NutriDiet Privacy Policy.\n\nPublisher: NutriDiet \n(Selangor, Malaysia)\nLast updated: October 4, 2025.''',
                        style: TextStyle(fontSize: 15, height: 1.6),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 30),
                      Center(
                        child: Text(
                          "Thank you for trusting NutriDiet 💚",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.green,
                              fontWeight: FontWeight.w600),
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