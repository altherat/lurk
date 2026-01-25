import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/centered_large_circular_progress_indicator.dart';
import 'package:lurk/widgets/media_scaffold.dart';
import 'package:video_player/video_player.dart';

const hideControlsAfterDuration = Duration(seconds: 2);
const List<double> playbackSpeeds = [0.5, 1, 1.25, 1.5, 2];

class VideoPlayerScreen extends StatefulWidget {

  final Platform platform;
  final String url;
  final Post? post;

  const VideoPlayerScreen({
    super.key,
    required this.platform,
    required this.url,
    this.post
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();

}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {

  late VideoPlayerController _videoController;
  final ValueNotifier<double> _sliderNotifier = ValueNotifier(0);
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isDragging = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _sliderNotifier.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    debugPrint('_init: ${widget.url}');
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: {
        'User-Agent': Settings.userAgent.value,
      },
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: false),
    );

    _videoController.addListener(_videoListener);

    await _videoController.initialize();
    
    if (!mounted) return;

    setState(() {
      _isInitialized = true;
    });

    if (Settings.autoplayVideos.value) {
      _videoController.play();
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() => _showControls = false);
        }
      });
    }

  }

  void _videoListener() {
    if (mounted && !_isDragging) {
      _sliderNotifier.value = _videoController.value.position.inMilliseconds.toDouble();
    }
  }

  void _onControlsChanged(VoidCallback action) {
    action();
    _disposeHideControlsTimer();
  }

  void _disposeHideControlsTimer() {
    if (_hideControlsTimer != null) {
      _hideControlsTimer!.cancel();
      _hideControlsTimer = null;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return MediaScaffold(
      url: widget.url,
      type: 'video',
      post: widget.post,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onControlsChanged(() => setState(() => _showControls = !_showControls)),
        child: Stack(
          children: [
            if (_isInitialized)
              Align(
                alignment: Alignment.topCenter,
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController)
                ),
              ),
            if (!_isInitialized)
              CenteredLargeCircularProgressIndicator(platform: widget.platform)
            else ...[
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1 : 0,
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
                                    icon: ValueListenableBuilder(
                                      valueListenable: _videoController,
                                      builder: (context, value, child) {
                                        return Icon(
                                          value.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                          color: Colors.white,
                                          size: 34,
                                        );
                                      }
                                    ),
                                    onPressed: () => _onControlsChanged(() => _videoController.setVolume(_videoController.value.volume > 0 ? 0 : 1))
                                  ),
                                  const SizedBox(width: 20),
                                  IconButton(
                                    icon: Icon(
                                      Icons.replay_5_rounded,
                                      color: Colors.white,
                                      size: 34,
                                    ),
                                    onPressed: () => _onControlsChanged(() => _videoController.seekTo(_videoController.value.position - const Duration(seconds: 5)))
                                  ),
                                  const SizedBox(width: 20),
                                  IconButton(
                                    icon: ValueListenableBuilder(
                                      valueListenable: _videoController,
                                      builder: (context, value, child) {
                                        return Icon(
                                          value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 48,
                                        );
                                      },
                                    ),
                                    onPressed: () => _onControlsChanged(() => _videoController.value.isPlaying ? _videoController.pause() : _videoController.play()),
                                  ),
                                  const SizedBox(width: 20),
                                  IconButton(
                                    icon: Icon(
                                      Icons.forward_5_rounded,
                                      color: Colors.white,
                                      size: 34,
                                    ),
                                    onPressed: () => _onControlsChanged(() => _videoController.seekTo(_videoController.value.position + const Duration(seconds: 5)))
                                  ),
                                  const SizedBox(width: 20),
                                  PopupMenuButton<double>(
                                    initialValue: _videoController.value.playbackSpeed,
                                    icon: const Icon(
                                      Icons.settings_rounded,
                                      color: Colors.white,
                                      size: 34
                                    ),
                                    onSelected: (value) => _onControlsChanged(() => _videoController.setPlaybackSpeed(value)),
                                    itemBuilder: (context) => playbackSpeeds.map((speed) {
                                      return PopupMenuItem<double>(
                                        value: speed,
                                        child: Text('${speed % 1 == 0 ? speed.toInt() : speed}x'),
                                      );
                                    }).toList(),
                                  )
                                ],
                              ),
                              ValueListenableBuilder(
                                valueListenable: _videoController,
                                builder: (context, VideoPlayerValue playerValue, child) {
                                  return ValueListenableBuilder(
                                    valueListenable: _sliderNotifier,
                                    builder: (context, sliderValue, child) {
                                      final duration = playerValue.duration;
                                      return Row(
                                        children: [
                                          Text(
                                            _formatDuration(Duration(milliseconds: sliderValue.round())),
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          Expanded(
                                            child: ValueListenableBuilder(
                                              valueListenable: Settings.showMorePlatformColorAccents,
                                              builder: (context, showMorePlatformColorAccents, child) {
                                                final color = showMorePlatformColorAccents ? widget.post?.community.platform.color : null;
                                                return Slider(
                                                  thumbColor: color,
                                                  activeColor: color,
                                                  inactiveColor: (color ?? Constants.primaryColor).withAlpha(100),
                                                  value: min(sliderValue, duration.inMilliseconds.toDouble()),
                                                  max: duration.inMilliseconds.toDouble(),
                                                  onChangeStart: (_) {
                                                    _isDragging = true;
                                                    _disposeHideControlsTimer();
                                                  },
                                                  onChanged: (value) => _sliderNotifier.value = value,
                                                  onChangeEnd: (value) async {
                                                    await _videoController.seekTo(Duration(milliseconds: value.toInt()));
                                                    _isDragging = false;
                                                  }
                                                );
                                              }
                                            ),
                                          ),
                                          Text(
                                            _formatDuration(duration),
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      );
                                    }
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
              ),
              ValueListenableBuilder(
                valueListenable: _videoController,
                builder: (context, VideoPlayerValue value, child) {
                  return value.isBuffering
                      ? const CenteredLargeCircularProgressIndicator()
                      : const SizedBox.shrink();
                },
              )
            ]
          ],
        ),
      )
    );
  }

}