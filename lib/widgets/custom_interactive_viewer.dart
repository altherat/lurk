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

  // void _onDoubleTap() {
  //   final currentMatrix = _transformationController.value;
  //   final currentScale = currentMatrix.getMaxScaleOnAxis();
  //   final targetScale = currentScale > 1.1 ? 1.0 : 3.0;
  //   late Matrix4 targetMatrix;
  //   if (targetScale == 1.0) {
  //     targetMatrix = Matrix4.identity();
  //   }
  //   else {
  //     final tapPosition = _doubleTapDetails!.localPosition;
  //     final double x = -tapPosition.dx * (targetScale - 1);
  //     final double y = -tapPosition.dy * (targetScale - 1);
  //     targetMatrix = Matrix4.compose(
  //       Vector3(x, y, 0),
  //       Quaternion.identity(),
  //       Vector3(targetScale, targetScale, 1.0),
  //     );
  //   }
  //   _animation = Matrix4Tween(
  //     begin: currentMatrix,
  //     end: targetMatrix,
  //   ).animate(CurvedAnimation(
  //     parent: _animationController, 
  //     curve: Curves.easeInOutCubicEmphasized,
  //   ));
  //   _animationController.forward(from: 0);
  // }

  // void _onVerticalDragUpdate(double dy) {
  //   const sensitivity = 0.01; 
  //   double newScale = _transformationController.value.getMaxScaleOnAxis() + (dy * sensitivity);
  //   newScale = newScale.clamp(widget.minScale, widget.maxScale);
  //   final tapPosition = _doubleTapPosition;
  //   final double x = -tapPosition.dx * (newScale - 1);
  //   final double y = -tapPosition.dy * (newScale - 1);
  //   _transformationController.value = Matrix4.compose(
  //     Vector3(x, y, 0),
  //     Quaternion.identity(),
  //     Vector3(newScale, newScale, 1),
  //   );
  // }

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
          final double x = -tapPosition.dx * (targetScale - 1);
          double y = -tapPosition.dy * (targetScale - 1);
          if (y < 0) y = 0;

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
      },
      onDoubleTapDown: (details) {
        _doubleTapDetails = details;
        _doubleTapPosition = details.localPosition;
        _isDoubleTapScaling = true;
      },
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        child: widget.child,
        onInteractionUpdate: (details) {
          if (_isDoubleTapScaling && details.pointerCount == 1) {
            double newScale = _transformationController.value.getMaxScaleOnAxis() + (details.focalPointDelta.dy * 0.01);
            newScale = newScale.clamp(widget.minScale, widget.maxScale);
            final tapPosition = _doubleTapPosition;
            final double x = -tapPosition.dx * (newScale - 1);
            double y = -tapPosition.dy * (newScale - 1);
            if (y < 0) y = 0;
            _transformationController.value = Matrix4.compose(
              Vector3(x, y, 0),
              Quaternion.identity(),
              Vector3(newScale, newScale, 1),
            );
          }
          final matrix = _transformationController.value;
          final Offset translation = Offset(matrix.storage[12], matrix.storage[13]);
          if (translation.dy < 0) {
            matrix.setTranslationRaw(translation.dx, 0, 0);
          }
          _transformationController.value = matrix;
        },
        onInteractionEnd: (details) {
          _isDoubleTapScaling = false;
        },
      )
    );
  }

}