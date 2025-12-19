import 'package:flutter/material.dart';

class JavaCourseScreen extends StatelessWidget {
  const JavaCourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Java Programming'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code_rounded,
              size: 64,
              color: Color(0xFF3366FF),
            ),
            SizedBox(height: 16),
            Text(
              'Java Programming',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Learn Java from basics to advanced',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

