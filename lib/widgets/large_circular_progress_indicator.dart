import 'package:flutter/material.dart';

class LargeCircularProgressIndicator extends StatelessWidget {
  
  const LargeCircularProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 64,
        height: 64,
        child: CircularProgressIndicator.adaptive(strokeWidth: 6)
      )
    );
  }

}