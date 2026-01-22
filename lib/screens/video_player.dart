import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lurk/app.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/media_scaffold.dart';
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

  final Player _player = Player();
  late final VideoController _controller = VideoController(_player);
  final ValueNotifier<double> _sliderController = ValueNotifier(0);
  StreamSubscription? _playerStreamSubscription;
  bool _isInitialized = false;
  bool _isDragging = false;
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
    _player.dispose();
    _sliderController.dispose();
    _playerStreamSubscription?.cancel();
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
      final platform = _player.platform as NativePlayer;
      await platform.setProperty('ao', 'audiotrack,opensles');
      await platform.setProperty('user-agent', Settings.userAgent.value);
      await platform.setProperty('hwdec', 'no');
      await platform.setProperty('video-sync', 'audio');
      await platform.setProperty('correct-pts', 'no'); 
    }

    await _player.open(
      Media(
        widget.url,
        httpHeaders: {'User-Agent': Settings.userAgent.value},
      ),
      play: false,
    );

    if (widget.audioUrl != null && _player.platform is NativePlayer) {
      final platform = _player.platform as NativePlayer;
      await platform.command(['audio-add', widget.audioUrl!, 'auto']);
      await platform.setProperty('aid', '1');
      
      // audio skips without this (maybe resolved?)
      // await _player.stream.buffer
      //     .firstWhere((b) => b > Duration.zero)
      //     .timeout(const Duration(seconds: 2));
      // await _player.seek(Duration.zero);
    }

    if (!mounted) return;

    _playerStreamSubscription = _player.stream.position.listen((position) {
      if (!_isDragging) {
        _sliderController.value = position.inMilliseconds.toDouble();
      }
    });

    setState(() {
      _isInitialized = true;
    });

    if (Settings.autoplayVideos.value) {
      await _player.play();
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
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
              child: InteractiveViewer(
                child: Video(
                  controller: _controller,
                  alignment: Alignment.topCenter,
                  controls: NoVideoControls,
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
                                  onPressed: () => _onControlsChanged(() => _player.seek(Duration(milliseconds: max(0, _player.state.position.inMilliseconds - 5000))))
                                ),
                                const SizedBox(width: 20),
                                IconButton(
                                  icon: StreamBuilder<bool>(
                                    stream: _player.stream.playing,
                                    builder: (context, snapshot) {
                                      return Icon(
                                        snapshot.data ?? _player.state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 48,
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
                                  onPressed: () => _onControlsChanged(() => _player.seek(Duration(milliseconds: min(_player.state.duration.inMilliseconds, _player.state.position.inMilliseconds + 5000))))
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
                            ValueListenableBuilder(
                              valueListenable: _sliderController,
                              builder: (context, value, child) {
                                final duration = _player.state.duration;
                                return Row(
                                  children: [
                                    Text(
                                      _formatDuration(Duration(milliseconds: value.round())),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    Expanded(
                                      child: Slider(
                                        inactiveColor: Constants.primaryColor.withAlpha(100),
                                        value: min(value, duration.inMilliseconds.toDouble()),
                                        max: duration.inMilliseconds.toDouble(),
                                        onChangeStart: (_) {
                                          _isDragging = true;
                                          _disposeHideControlsTimer();
                                        },
                                        onChanged: (value) => _sliderController.value = value,
                                        onChangeEnd: (value) async {
                                          await _player.seek(Duration(milliseconds: value.toInt()));
                                          _isDragging = false;
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


// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:lurk/app.dart';
// import 'package:lurk/core/constants.dart';
// import 'package:lurk/models/community.dart';
// import 'package:lurk/models/post.dart';
// import 'package:lurk/services/settings.dart';
// import 'package:lurk/widgets/media_scaffold.dart';
// import 'package:lurk/widgets/one_finger_zoom.dart';
// import 'package:video_player/video_player.dart';
// import 'package:lurk/widgets/large_circular_progress_indicator.dart';

// const hideControlsAfterDuration = Duration(seconds: 2);
// const List<double> playbackSpeeds = [0.5, 1, 1.25, 1.5, 2];

// class VideoPlayerScreen extends StatefulWidget {

//   final String url;
//   final Community? community;
//   final Post? post;

//   const VideoPlayerScreen({
//     super.key,
//     required this.url,
//     this.community,
//     this.post
//   });

//   @override
//   State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();

// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> with RouteAware {

//   final TransformationController _transformationController = TransformationController();
//   late VideoPlayerController _controller;
//   bool _showControls = true;
//   Timer? _hideControlsTimer;

//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }

//   @override
//   void dispose() {
//     routeObserver.unsubscribe(this);
//     _transformationController.dispose();
//     _controller.dispose();
//     _hideControlsTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     routeObserver.subscribe(this, ModalRoute.of(context)!);
//   }

//   @override
//   void didPop() {
//     _controller.pause();
//     super.didPop();
//   }

//   Future<void> _init() async {
//     _controller = VideoPlayerController.networkUrl(
//       Uri.parse(widget.url),
//       httpHeaders: {
//         'User-Agent': Settings.userAgent.value
//       }
//     );
//     await _controller.initialize();
//     if (!mounted) {
//       return;
//     }
//     if (Settings.autoplayVideos.value) {
//       _controller.play();
//       _hideControlsTimer = Timer(hideControlsAfterDuration, () {
//         if (mounted && _showControls) {
//           setState(() {
//             _showControls = false;
//           });
//         }
//       });
//     }
//   }

//   void _onControlsChanged(VoidCallback action) {
//     setState(() {
//       action();
//     });
//     _disposeHideControlsTimer();
//   }

//   void _disposeHideControlsTimer() {
//     if (_hideControlsTimer != null) {
//       _hideControlsTimer!.cancel();
//       _hideControlsTimer = null;
//     }
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, "0");
//     return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MediaScaffold(
//       url: widget.url,
//       type: 'video',
//       community: widget.community,
//       post: widget.post,
//       body: _controller.value.isInitialized
//           ? GestureDetector(
//               onTap: () => _onControlsChanged(() => _showControls = !_showControls),
//               child: Stack(
//                 children: [
//                   InteractiveViewer(
//                     transformationController: _transformationController,
//                     child: Align(
//                       alignment: Alignment.topCenter,
//                       child: AspectRatio(
//                         aspectRatio: _controller.value.aspectRatio,
//                         child: VideoPlayer(_controller),
//                       ),
//                     ),
//                   ),
//                   ValueListenableBuilder(
//                     valueListenable: _controller,
//                     builder: (context, value, child) {
//                       if (value.isBuffering && !value.isCompleted) {
//                         return const LargeCircularProgressIndicator();
//                       }
//                       return const SizedBox.shrink();
//                     },
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     left: 0,
//                     right: 0,
//                     child: AnimatedOpacity(
//                       opacity: _showControls ? 1.0 : 0.0,
//                       duration: const Duration(milliseconds: 300),
//                       child: Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.symmetric(vertical: 10),
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.bottomCenter,
//                             end: Alignment.topCenter,
//                             colors: [Colors.black87, Colors.black26],
//                           ),
//                         ),
//                         child: SafeArea(
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     IconButton(
//                                       icon: Icon(
//                                         _controller.value.volume > 0 ? Icons.volume_up_rounded : Icons.volume_off_rounded,
//                                         color: Colors.white,
//                                         size: 34,
//                                       ),
//                                       onPressed: () => _onControlsChanged(() => _controller.setVolume(_controller.value.volume > 0 ? 0 : 1))
//                                     ),
//                                     const SizedBox(width: 20),
//                                     IconButton(
//                                       icon: Icon(
//                                         Icons.replay_5_rounded,
//                                         color: Colors.white,
//                                         size: 34,
//                                       ),
//                                       onPressed: () => _onControlsChanged(() => _controller.seekTo(Duration(seconds: _controller.value.position.inSeconds - 5)))
//                                     ),
//                                     const SizedBox(width: 20),
//                                     IconButton(
//                                       icon: Icon(
//                                         _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
//                                         color: Colors.white,
//                                         size: 34,
//                                       ),
//                                       onPressed: () => _onControlsChanged(_controller.value.isPlaying ? _controller.pause : _controller.play)
//                                     ),
//                                     const SizedBox(width: 20),
//                                     IconButton(
//                                       icon: Icon(
//                                         Icons.forward_5_rounded,
//                                         color: Colors.white,
//                                         size: 34,
//                                       ),
//                                       onPressed: () => _onControlsChanged(() => _controller.seekTo(Duration(seconds: _controller.value.position.inSeconds + 5)))
//                                     ),
//                                     const SizedBox(width: 20),
//                                     PopupMenuButton<double>(
//                                       initialValue: _controller.value.playbackSpeed,
//                                       icon: const Icon(
//                                         Icons.settings_rounded,
//                                         color: Colors.white,
//                                         size: 34,
//                                       ),
//                                       onSelected: _controller.setPlaybackSpeed,
//                                       itemBuilder: (context) => playbackSpeeds.map((speed) {
//                                         return PopupMenuItem<double>(
//                                           value: speed,
//                                           child: Text('${speed % 1 == 0 ? speed.toInt() : speed}x')
//                                         );
//                                       }).toList()
//                                     )
//                                   ],
//                                 ),
//                                 ValueListenableBuilder(
//                                   valueListenable: _controller,
//                                   builder: (context, value, child) {
//                                     return Row(
//                                       children: [
//                                         Text(
//                                           _formatDuration(value.position),
//                                           style: const TextStyle(color: Colors.white),
//                                         ),
//                                         Expanded(
//                                           child: Slider(
//                                             inactiveColor: Constants.primaryColor.withAlpha(100),
//                                             value: value.position.inMilliseconds.toDouble(),
//                                             max: value.duration.inMilliseconds.toDouble(),
//                                             onChangeStart: (_) => _disposeHideControlsTimer(),
//                                             onChanged: (value) {
//                                               _controller.seekTo(Duration(milliseconds: value.toInt()));
//                                             },
//                                           ),
//                                         ),
//                                         Text(
//                                           _formatDuration(_controller.value.duration),
//                                           style: const TextStyle(color: Colors.white),
//                                         ),
//                                       ],
//                                     );
//                                   }
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           : const LargeCircularProgressIndicator(),
//     );
//   }

// }