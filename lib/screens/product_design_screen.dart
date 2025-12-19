import 'package:flutter/material.dart';

class ProductDesignScreen extends StatelessWidget {
  const ProductDesignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Design'),
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
              'Product Design',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Progress: 6/24 lessons completed',
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

