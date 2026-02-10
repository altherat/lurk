import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';

const _indicatorSize = 32.0;

class SnackBarProgressContent extends StatefulWidget {

  final Platform platform;
  final String progressMessage;
  final String completeMessage;
  final String errorMessage;
  final Future<void> future;
  final VoidCallback onComplete;

  const SnackBarProgressContent({
    super.key,
    required this.platform,
    required this.progressMessage,
    required this.completeMessage,
    required this.errorMessage,
    required this.future, 
    required this.onComplete,
  });

  @override
  State<SnackBarProgressContent> createState() => _SnackBarProgressContentState();

}

class _SnackBarProgressContentState extends State<SnackBarProgressContent> {

  bool _isComplete = false;
  bool _isErrored = false;

  @override
  void initState() {
    super.initState();
    _waitForFuture();
  }

  Future<void> _waitForFuture() async {
    try {
      await widget.future;
      if (mounted) {
        setState(() => _isComplete = true);
      }
    }
    catch (e) {
      if (mounted) {
        setState(() => _isErrored = true);
      }
    }
    finally {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget prefix;
    final String message;
    if (_isErrored) {
      prefix = Icon(
        Icons.close_rounded,
        color: Colors.redAccent,
        size: _indicatorSize,
      );
      message = widget.errorMessage;
    }
    else if (_isComplete) {
      prefix = Icon(
        Icons.check_rounded,
        color: Colors.greenAccent,
        size: _indicatorSize,
      );
      message = widget.completeMessage;
    }
    else {
      prefix = CustomCircularProgressIndicator(
        platform: widget.platform,
        alignment: Alignment.center,
        size: 24,
        strokeWidth: 3,
      );
      message = widget.progressMessage;
    }
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        key: const ValueKey(2),
        children: [
          SizedBox(
            width: _indicatorSize,
            height: _indicatorSize,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child
                  )
                );
              },
              child: prefix
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

}