import 'package:flutter/cupertino.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';

class MaterialSliverRefreshControl extends StatelessWidget {

  final Platform platform;
  final RefreshCallback onRefresh;

  const MaterialSliverRefreshControl({
    super.key,
    required this.platform,
    required this.onRefresh
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      onRefresh: onRefresh,
      builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: OverflowBox(
            minHeight: refreshIndicatorExtent,
            maxHeight: refreshIndicatorExtent,
            child: Opacity(
              opacity: (pulledExtent / refreshIndicatorExtent).clamp(0.0, 1.0),
              child: CustomCircularProgressIndicator(
                size: 28,
                value: refreshState == RefreshIndicatorMode.drag || refreshState == RefreshIndicatorMode.done ? (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0) : null
              ),
            ),
          ),
        );
      },
    );
  }
  
}