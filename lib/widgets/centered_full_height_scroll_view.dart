import 'package:flutter/material.dart';

class FeedScreenCenteredErrorMessage extends StatelessWidget {

  final List<Widget>? headers;
  final Widget child;
  
  const FeedScreenCenteredErrorMessage({
    super.key,
    this.headers,
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        ...?headers?.map((header) => SliverToBoxAdapter(child: header)),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: child),
        )
      ]
    );
  }

}