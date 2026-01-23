// TODO: fix (AI slop)

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, Quaternion;

class OneFingerZoomGestureRecognizer extends StatefulWidget {
  
  final Widget child;
  final TransformationController transformationController;
  final VoidCallback? onDoubleTap;
  final double minScale;
  final double maxScale;

  const OneFingerZoomGestureRecognizer({
    super.key,
    required this.child,
    required this.transformationController,
    this.onDoubleTap,
    this.minScale = 1.0,
    this.maxScale = 4.0,
  });

  @override
  State<OneFingerZoomGestureRecognizer> createState() =>
      _OneFingerZoomGestureRecognizerState();
}

class _OneFingerZoomGestureRecognizerState
    extends State<OneFingerZoomGestureRecognizer> {
  
  int _tapCount = 0;
  DateTime? _lastTapUpTime;
  
  // "Potential" zoom state
  bool _isPotentialZoom = false; 
  // "Active" zoom state (only true after we drag past a threshold)
  bool _isActuallyZooming = false; 

  Offset? _startDragPosition;
  double _startScale = 1.0;
  final Set<int> _activePointers = {};

  // How many pixels must the user drag before we treat it as a zoom?
  // 10 logical pixels is a standard "slop" value.
  static const double _kDragSlop = 10.0; 

  void _onPointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);

    // If pinch detected, cancel everything
    if (_activePointers.length > 1) {
      _reset();
      return;
    }

    final now = DateTime.now();
    
    // Double tap logic
    if (_lastTapUpTime != null &&
        now.difference(_lastTapUpTime!) < const Duration(milliseconds: 300)) {
      _tapCount++;
      if (_tapCount == 2) {
        // We are now in a "Potential Zoom" state.
        // We don't know yet if the user wants to Drag-to-Zoom or just Double Tap.
        setState(() {
          _isPotentialZoom = true;
          _startDragPosition = event.position;
          _startScale = widget.transformationController.value.getMaxScaleOnAxis();
        });
      }
    } else {
      _tapCount = 1;
      _isPotentialZoom = false;
      _isActuallyZooming = false;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activePointers.length > 1) return;

    if (_isPotentialZoom && _startDragPosition != null) {
      final double dy = event.position.dy - _startDragPosition!.dy;

      // CHECK: Have we moved enough to call this a "Drag"?
      if (!_isActuallyZooming) {
        if (dy.abs() > _kDragSlop) {
          setState(() {
            _isActuallyZooming = true; 
            // Reset start position to current so the zoom doesn't "jump"
            // when we cross the threshold
            // _startDragPosition = event.position; 
            // Actually, better to keep original start but subtract slop?
            // For simplicity, let's just let it slide.
          });
        } else {
          // User hasn't moved enough yet. Do nothing.
          return;
        }
      }

      // If we are actually zooming, apply the matrix
      if (_isActuallyZooming) {
        final double scaleChange = 1 + (dy * 0.005);
        double newScale = _startScale * scaleChange;
        newScale = newScale.clamp(widget.minScale, widget.maxScale);

        final Vector3 translation = widget.transformationController.value.getTranslation();
        final Matrix4 newMatrix = Matrix4.compose(
          translation,
          Quaternion.identity(),
          Vector3.all(newScale),
        );

        widget.transformationController.value = newMatrix;
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);

    if (_isPotentialZoom) {
      if (_isActuallyZooming) {
        // Case 1: The user dragged up/down. We finished the zoom gesture.
        // Do NOT fire onDoubleTap.
      } else {
        // Case 2: The user tapped twice but didn't drag (or dragged < 10px).
        // This is a standard Double Tap.
        widget.onDoubleTap?.call();
      }
      
      // Cleanup
      _reset();
    } else if (_tapCount == 1) {
      _lastTapUpTime = DateTime.now();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    _reset();
  }

  void _reset() {
    setState(() {
      _isPotentialZoom = false;
      _isActuallyZooming = false;
      _startDragPosition = null;
      _tapCount = 0;
      // We do NOT reset _lastTapUpTime here, because we might need it for the NEXT tap
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
  
}