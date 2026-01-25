import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';

class SnackBarProgressContent extends StatefulWidget {

  final Platform platform;
  final String progressMessage;
  final String completedMessage;
  final String? subtext;
  final Future<void> Function() action;
  final VoidCallback onComplete;

  const SnackBarProgressContent({
    super.key,
    required this.platform,
    required this.progressMessage,
    required this.completedMessage,
    this.subtext,
    required this.action, 
    required this.onComplete,
  });

  @override
  State<SnackBarProgressContent> createState() => _SnackBarProgressContentState();

}

class _SnackBarProgressContentState extends State<SnackBarProgressContent> {

  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startAction();
  }

  Future<void> _startAction() async {
    await widget.action();
    if (mounted) {
      setState(() => _isComplete = true);
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
            },
            child: _isComplete
              ? Icon(
                  Icons.check_rounded,
                  color: widget.platform.color,
                  size: 48
                )
              : CustomCircularProgressIndicator(
                  platform: widget.platform,
                  strokeWidth: 5,
                ),
          ) 
        ),
        const SizedBox(height: 8),
        Text(_isComplete ? widget.completedMessage : widget.progressMessage),
        if (widget.subtext != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.subtext!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).disabledColor
              ),
            ),
          ),
      ],
    );
  }

}