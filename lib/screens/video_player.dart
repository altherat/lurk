import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lurk/app.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/media_scaffold.dart';
import 'package:lurk/widgets/one_finger_zoom.dart';
import 'package:video_player/video_player.dart';
import 'package:lurk/widgets/large_circular_progress_indicator.dart';

const hideControlsAfterDuration = Duration(seconds: 2);
const List<double> playbackSpeeds = [0.5, 1, 1.25, 1.5, 2];

class VideoPlayerScreen extends StatefulWidget {

  final String url;
  final Community? community;
  final Post? post;

  const VideoPlayerScreen({
    super.key,
    required this.url,
    this.community,
    this.post
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();

}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with RouteAware {

  final TransformationController _transformationController = TransformationController();
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _transformationController.dispose();
    _controller.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPop() {
    _controller.pause();
    super.didPop();
  }

  Future<void> _init() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: Constants.userAgentHeader
    );
    await _controller.initialize();
    if (!mounted) {
      return;
    }
    setState(() => _initialized = true);
    if (Settings.autoplayVideos.value) {
      _controller.play();
      _startHideControlsTimer();
    }
  }

  void _onControlsChanged(VoidCallback action) {
    action();
    setState(() {});
    if (_controller.value.isPlaying) {
      _startHideControlsTimer();
    }
    else {
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(hideControlsAfterDuration, () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return MediaScaffold(
      url: widget.url,
      type: 'video',
      community: widget.community,
      post: widget.post,
      body: _initialized
          ? GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                  if (_showControls) {
                    _startHideControlsTimer();
                  }
                  else {
                    _hideControlsTimer?.cancel();
                  }
                });
              },
              child: Stack(
                children: [
                  OneFingerZoomGestureRecognizer(
                    transformationController: _transformationController,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, VideoPlayerValue value, child) => value.isBuffering ? const LargeCircularProgressIndicator() : const SizedBox.shrink(),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.black26],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _controller.value.volume > 0 ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                      onPressed: () => _onControlsChanged(() => _controller.setVolume(_controller.value.volume > 0 ? 0 : 1))
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon: Icon(
                                        Icons.replay_5_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                      onPressed: () => _onControlsChanged(() => _controller.seekTo(Duration(seconds: _controller.value.position.inSeconds - 5)))
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon: Icon(
                                        _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                      onPressed: () => _onControlsChanged(_controller.value.isPlaying ? _controller.pause : _controller.play)
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon: Icon(
                                        Icons.forward_5_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                      onPressed: () => _onControlsChanged(() => _controller.seekTo(Duration(seconds: _controller.value.position.inSeconds + 5)))
                                    ),
                                    const SizedBox(width: 20),
                                    PopupMenuButton<double>(
                                      initialValue: _controller.value.playbackSpeed,
                                      icon: const Icon(
                                        Icons.settings_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                      onSelected: _controller.setPlaybackSpeed,
                                      itemBuilder: (context) => playbackSpeeds.map((speed) {
                                        return PopupMenuItem<double>(
                                          value: speed,
                                          child: Text('${speed % 1 == 0 ? speed.toInt() : speed}x')
                                        );
                                      }).toList()
                                    )
                                  ],
                                ),
                                ValueListenableBuilder(
                                  valueListenable: _controller,
                                  builder: (context, value, child) {
                                    return Row(
                                      children: [
                                        Text(
                                          _formatDuration(value.position),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        Expanded(
                                          child: Slider(
                                            inactiveColor: Constants.primaryColor.withAlpha(100),
                                            value: value.position.inMilliseconds.toDouble(),
                                            max: value.duration.inMilliseconds.toDouble(),
                                            onChangeStart: (_) => _hideControlsTimer?.cancel(),
                                            onChangeEnd: (_) => _startHideControlsTimer(),
                                            onChanged: (value) {
                                              _controller.seekTo(Duration(milliseconds: value.toInt()));
                                            },
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(_controller.value.duration),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    );
                                  }
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const LargeCircularProgressIndicator(),
    );
  }

}