import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class CustomInteractiveViewer extends StatefulWidget {

  final double minScale;
  final double maxScale;
  final Widget child;

  const CustomInteractiveViewer({
    super.key,
    this.minScale = 1,
    this.maxScale = 5,
    required this.child
  });

  @override
  State<CustomInteractiveViewer> createState() => _CustomInteractiveViewerState();

}

class _CustomInteractiveViewerState extends State<CustomInteractiveViewer> with SingleTickerProviderStateMixin {

  final TransformationController _transformationController = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;
  bool _isDoubleTapScaling = false;
  bool _fixToTop = false;
  Offset _doubleTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
      _transformationController.value = _animation!.value;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () {
        final currentMatrix = _transformationController.value;
        final currentScale = currentMatrix.getMaxScaleOnAxis();
        final targetScale = currentScale > 1.1 ? 1.0 : 3.0;
        late Matrix4 targetMatrix;
        if (targetScale == 1.0) {
          targetMatrix = Matrix4.identity();
        }
        else {
          final tapPosition = _doubleTapDetails!.localPosition;
          final x = -tapPosition.dx * (targetScale - 1);
          final y = -tapPosition.dy * (targetScale - 1);
          targetMatrix = Matrix4.compose(
            Vector3(x, y, 0),
            Quaternion.identity(),
            Vector3(targetScale, targetScale, 1.0),
          );
        }
        _animation = Matrix4Tween(
          begin: currentMatrix,
          end: targetMatrix,
        ).animate(CurvedAnimation(
          parent: _animationController, 
          curve: Curves.easeInOutCubicEmphasized,
        ));
        _animationController.forward(from: 0);
        _isDoubleTapScaling = false;
      },
      onDoubleTapDown: (details) {
        _doubleTapDetails = details;
        _doubleTapPosition = details.localPosition;
        _isDoubleTapScaling = true;
        _fixToTop = _transformationController.value.storage[13].abs() <= 0.01;
      },
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        child: widget.child,
        onInteractionUpdate: (details) {
          if (_isDoubleTapScaling && details.pointerCount == 1) {
            final currentMatrix = _transformationController.value;
            final currentScale = currentMatrix.getMaxScaleOnAxis();
            final scaleChange = (currentScale + (details.focalPointDelta.dy * 0.01)).clamp(widget.minScale, widget.maxScale) / currentScale;
            final pivot = _doubleTapPosition;
            final Matrix4 newMatrix = Matrix4.translationValues(pivot.dx, pivot.dy, 0.0) * Matrix4.diagonal3Values(scaleChange, scaleChange, 1.0) * Matrix4.translationValues(-pivot.dx, -pivot.dy, 0.0) * currentMatrix;
            if (_fixToTop && newMatrix.storage[13] < 0) {
              newMatrix.storage[13] = 0;
            }
            _transformationController.value = newMatrix;
          }
        },
        onInteractionEnd: (details) {
          _isDoubleTapScaling = false;
        },
      )
    );
  }

}