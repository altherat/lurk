import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lurk/app.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/media_scaffold.dart';
import 'package:lurk/widgets/one_finger_zoom.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:lurk/widgets/large_circular_progress_indicator.dart';

const hideControlsAfterDuration = Duration(seconds: 2);
const List<double> playbackSpeeds = [0.5, 1, 1.25, 1.5, 2];

class VideoPlayerScreen extends StatefulWidget {

  final String url;
  final String? audioUrl;
  final Community? community;
  final Post? post;

  const VideoPlayerScreen({
    super.key,
    required this.url,
    this.audioUrl,
    this.community,
    this.post
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();

}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with RouteAware {

  final TransformationController _transformationController = TransformationController();
  final Player _player = Player();
  late final VideoController _controller = VideoController(_player);
  bool _isInitialized = false;
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
    _player.dispose();
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
    _player.pause();
    super.didPop();
  }

  Future<void> _init() async {
    if (_player.platform is NativePlayer) {
      await (_player.platform as NativePlayer).setProperty('user-agent', Settings.userAgent.value);
    }

    await _player.open(
      Media(
        widget.url,
        httpHeaders: {'User-Agent': Settings.userAgent.value},
      ),
      play: false,
    );

    if (widget.audioUrl != null && _player.platform is NativePlayer) {
      await (_player.platform as NativePlayer).command(['audio-add', widget.audioUrl!, 'select']);
      
      // audio skips without this
      await _player.stream.buffer
          .firstWhere((b) => b > Duration.zero)
          .timeout(const Duration(seconds: 2));
      await _player.seek(Duration.zero);
    }

    if (!mounted) return;

    setState(() {
      _isInitialized = true;
    });

    if (Settings.autoplayVideos.value) {
      await _player.play();
      _hideControlsTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _showControls) {
          setState(() => _showControls = false);
        }
      });
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
      community: widget.community,
      post: widget.post,
      body: GestureDetector(
        onTap: () => _onControlsChanged(() => setState(() => _showControls = !_showControls)),
        child: Stack(
          children: [
            Visibility(
              visible: _isInitialized,
              child: OneFingerZoomGestureRecognizer(
                transformationController: _transformationController,
                child: InteractiveViewer(
                  child: Video(
                    controller: _controller,
                    alignment: Alignment.topCenter,
                    controls: NoVideoControls,
                  ),
                ),
              ),
            ),
            if (!_isInitialized)
              const LargeCircularProgressIndicator()
            else ...[
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
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
                                  icon: StreamBuilder(
                                    stream: _player.stream.volume,
                                    builder: (context, snapshot) {
                                      return Icon(
                                        snapshot.data == null || snapshot.data! > 0 ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      );
                                    }
                                  ),
                                  onPressed: () => _onControlsChanged(() => _player.setVolume(_player.state.volume > 0 ? 0.0 : 100.0))
                                ),
                                const SizedBox(width: 20),
                                IconButton(
                                  icon: Icon(
                                    Icons.replay_5_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                  onPressed: () => _onControlsChanged(() => _player.seek(_player.state.position - const Duration(seconds: 5)))
                                ),
                                const SizedBox(width: 20),
                                IconButton(
                                  icon: StreamBuilder<bool>(
                                    stream: _player.stream.playing,
                                    builder: (context, snapshot) {
                                      return Icon(
                                        snapshot.data ?? _player.state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      );
                                    },
                                  ),
                                  onPressed: () => _onControlsChanged(() => _player.playOrPause()),
                                ),
                                const SizedBox(width: 20),
                                IconButton(
                                  icon: Icon(
                                    Icons.forward_5_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                  onPressed: () => _onControlsChanged(() => _player.seek(_player.state.position + const Duration(seconds: 5)))
                                ),
                                const SizedBox(width: 20),
                                PopupMenuButton<double>(
                                  initialValue: _player.state.rate,
                                  icon: const Icon(
                                    Icons.settings_rounded,
                                    color: Colors.white,
                                    size: 34
                                  ),
                                  onSelected: (value) => _onControlsChanged(() => _player.setRate(value)),
                                  itemBuilder: (context) => playbackSpeeds.map((speed) {
                                    return PopupMenuItem<double>(
                                      value: speed,
                                      child: Text('${speed % 1 == 0 ? speed.toInt() : speed}x'),
                                    );
                                  }).toList(),
                                )
                              ],
                            ),
                            StreamBuilder<Duration>(
                              stream: _player.stream.position,
                              builder: (context, snapshot) {
                                final position = snapshot.data ?? Duration.zero;
                                final total = _player.state.duration;
                                return Row(
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    Expanded(
                                      child: Slider(
                                        inactiveColor: Constants.primaryColor.withAlpha(100),
                                        value: position.inMilliseconds.toDouble(),
                                        max: total.inMilliseconds.toDouble(),
                                        onChangeStart: (_) => _disposeHideControlsTimer(),
                                        onChanged: (value) => _player.seek(Duration(milliseconds: value.toInt()))
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(total),
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
              StreamBuilder(
                stream: _player.stream.buffering,
                builder: (context, snapshot) => snapshot.data == true ? const LargeCircularProgressIndicator() : const SizedBox.shrink(),
              ),
            ]
          ],
        ),
      )
    );
  }

}