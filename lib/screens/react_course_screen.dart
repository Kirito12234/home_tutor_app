import 'package:flutter/material.dart';

class ReactCourseScreen extends StatelessWidget {
  const ReactCourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('React Development'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.developer_mode_rounded,
              size: 64,
              color: Color(0xFF3366FF),
            ),
            SizedBox(height: 16),
            Text(
              'React Development',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Build modern web applications with React',
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

