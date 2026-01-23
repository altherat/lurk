import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';

const _size = 64.0;
const _strokeWidth = 6.0;

class LargeCircularProgressIndicator extends StatelessWidget {

  final Platform? platform;
  
  const LargeCircularProgressIndicator({
    super.key,
    this.platform
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _size,
        height: _size,
        child: CustomCircularProgressIndicator(
          platform: platform,
          strokeWidth: _strokeWidth,
        )
      )
    );
  }

}