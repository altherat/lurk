import 'package:flutter/material.dart';

class MediaError extends StatelessWidget {

  const MediaError({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_rounded, size: 80, color: Colors.grey),
          Text('Something went wrong', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

}