import 'package:flutter/material.dart';
import 'capture_screen.dart';
import 'quiz_e2c_screen.dart';
import 'quiz_c2e_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Memorizer')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildMenuButton(
              context: context,
              icon: Icons.camera_alt,
              label: 'Capture Word',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CaptureScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
            buildMenuButton(
              context: context,
              icon: Icons.translate,
              label: 'English to Chinese',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuizE2CScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
            buildMenuButton(
              context: context,
              icon: Icons.edit_note,
              label: 'Chinese to English',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuizC2EScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenuButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 32),
        label: Text(label, style: const TextStyle(fontSize: 20)),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
