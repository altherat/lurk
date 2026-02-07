import 'package:flutter/cupertino.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';

class MaterialSliverRefreshControl extends StatelessWidget {

  final Platform platform;
  final RefreshCallback? onRefresh;

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
            child: CustomCircularProgressIndicator(
              platform: platform,
              size: 28,
              strokeWidth: 3.5,
              value: refreshState == RefreshIndicatorMode.refresh ? null : refreshState == RefreshIndicatorMode.armed ? 1 : (pulledExtent / refreshTriggerPullDistance).clamp(0, 1),
            ),
          )
        );
      },
    );
  }
  
}