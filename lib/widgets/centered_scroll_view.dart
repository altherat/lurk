import 'package:flutter/material.dart';

class CenteredScrollView extends StatelessWidget {

  final Widget child;

  const CenteredScrollView({
    super.key,
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}