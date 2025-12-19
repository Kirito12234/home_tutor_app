import 'package:flutter/material.dart';

class PaintingCourseScreen extends StatelessWidget {
  const PaintingCourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painting'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.palette_rounded,
              size: 64,
              color: Color(0xFF3366FF),
            ),
            SizedBox(height: 16),
            Text(
              'Painting',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Learn painting techniques and art',
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

