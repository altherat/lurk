import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/constants.dart';

const _threshold = 50.0;
const _tolerance = 0.25;

class SwipeToVote extends StatefulWidget {

  final void Function(bool upvote) onVote;
  final Widget child;

  const SwipeToVote({
    super.key, 
    required this.onVote,
    required this.child,
  });

  @override
  State<SwipeToVote> createState() => _SwipeToVoteState();

}

class _SwipeToVoteState extends State<SwipeToVote> with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double> _animation;
  double _dragOffset = 0.0;
  double _animationOffset = 0.0;
  bool _isArmed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Easing.emphasizedDecelerate
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final newOffset = (_dragOffset + details.delta.dx).clamp(-_threshold, _threshold);
    if (newOffset != _dragOffset) {
      setState(() {
        _dragOffset = newOffset;
      });
    }
    final offset = _dragOffset.abs();
    if (offset >= _threshold) {
      if (!_isArmed) {
        _isArmed = true;
        HapticFeedback.mediumImpact();
      }
    }
    else if (_isArmed && offset < _threshold * (1 - _tolerance)) {
        HapticFeedback.mediumImpact();
      _isArmed = false;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isArmed) {
      widget.onVote(_dragOffset > 0);
    }
    _isArmed = false;
    if (_dragOffset != 0) {
      _controller.duration = Duration(milliseconds: (200 + _dragOffset.abs()).round());
      _animationOffset = _dragOffset;
      _dragOffset = 0;
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final offset = _controller.isAnimating ? _animationOffset * (1 - _animation.value) : _dragOffset;
          final offsetAbs = offset.abs();
          final opacity = offsetAbs / _threshold / 2;
          return Stack(
            children: [
              Positioned(
                left: offset > 0 ? 0 : null,
                top: 0,
                right: offset < 0 ? 0 : null,
                bottom: 0,
                child: Container(
                  width: offsetAbs,
                  color: (offset >= 0 ? Constants.upvoteColor : Constants.downvoteColor).withValues(alpha: _isArmed ? 1 : opacity),
                  alignment: Alignment.center,
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            offset > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            // size: 16 + 16 * progress,
                            color: Colors.white.withValues(alpha: _isArmed ? 1 : opacity),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(offset, 0),
                child: widget.child,
              ),
            ],
          );
        }
      ),
    );
  }

}