// // Unsued: videos from Reddit randomly skip, cannot seem to fix

// import 'dart:async';
// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:lurk/app.dart';
// import 'package:lurk/core/constants.dart';
// import 'package:lurk/core/enums.dart';
// import 'package:lurk/models/post.dart';
// import 'package:lurk/services/settings.dart';
// import 'package:lurk/widgets/media_scaffold.dart';
// import 'package:media_kit/media_kit.dart';
// import 'package:media_kit_video/media_kit_video.dart';
// import 'package:lurk/widgets/centered_large_circular_progress_indicator.dart';

// const hideControlsAfterDuration = Duration(seconds: 2);
// const List<double> playbackSpeeds = [0.5, 1, 1.25, 1.5, 2];

// class VideoPlayerScreen extends StatefulWidget {

//   final Platform platform;
//   final String url;
//   final String? audioUrl;
//   final Post? post;

//   const VideoPlayerScreen({
//     super.key,
//     required this.platform,
//     required this.url,
//     this.audioUrl,
//     this.post
//   });

//   @override
//   State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();

// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> with RouteAware {

//   final Player _player = Player();
//   late final VideoController _controller = VideoController(_player);
//   final ValueNotifier<double> _sliderNotifier = ValueNotifier(0);
//   StreamSubscription? _playerStreamSubscription;
//   bool _isInitialized = false;
//   bool _isDragging = false;
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
//     _player.dispose();
//     _sliderNotifier.dispose();
//     _playerStreamSubscription?.cancel();
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
//     _player.pause();
//     super.didPop();
//   }

//   Future<void> _init() async {
//     debugPrint(widget.url);
//     if (_player.platform is NativePlayer) {
//       final platform = _player.platform as NativePlayer;
//       await platform.setProperty('user-agent', Settings.userAgent.value);
//       await platform.setProperty('hwdec', 'no');
//       await platform.setProperty('video-sync', 'audio');
//       await platform.setProperty('ao', 'audiotrack,opensles');
//       await platform.setProperty('correct-pts', 'no');
//     }

//     await _player.open(
//       Media(
//         widget.url,
//         httpHeaders: {'User-Agent': Settings.userAgent.value},
//       ),
//       play: false,
//     );

//     if (widget.audioUrl != null && _player.platform is NativePlayer) {
//       final platform = _player.platform as NativePlayer;
//       await platform.command(['audio-add', widget.audioUrl!, 'auto']);
//       await platform.setProperty('aid', '1');
      
//       // audio skips without this (maybe resolved?)
//       // await _player.stream.buffer
//       //     .firstWhere((b) => b > Duration.zero)
//       //     .timeout(const Duration(seconds: 2));
//       // await _player.seek(Duration.zero);
//     }

//     if (!mounted) return;

//     _playerStreamSubscription = _player.stream.position.listen((position) {
//       if (!_isDragging) {
//         _sliderNotifier.value = position.inMilliseconds.toDouble();
//       }
//     });

//     setState(() {
//       _isInitialized = true;
//     });

//     if (Settings.autoplayVideos.value) {
//       await _player.play();
//       _hideControlsTimer = Timer(const Duration(seconds: 3), () {
//         if (mounted && _showControls) {
//           setState(() => _showControls = false);
//         }
//       });
//     }

//   }

//   void _onControlsChanged(VoidCallback action) {
//     action();
//     _disposeHideControlsTimer();
//   }

//   void _disposeHideControlsTimer() {
//     if (_hideControlsTimer != null) {
//       _hideControlsTimer!.cancel();
//       _hideControlsTimer = null;
//     }
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MediaScaffold(
//       url: widget.url,
//       type: 'video',
//       post: widget.post,
//       onSave: () {

//       },
//       body: GestureDetector(
//         onTap: () => _onControlsChanged(() => setState(() => _showControls = !_showControls)),
//         child: Stack(
//           children: [
//             Visibility(
//               visible: _isInitialized,
//               child: InteractiveViewer(
//                 child: Video(
//                   controller: _controller,
//                   alignment: Alignment.topCenter,
//                   controls: NoVideoControls,
//                 ),
//               ),
//             ),
//             if (!_isInitialized)
//               CenteredLargeCircularProgressIndicator(platform: widget.platform)
//             else ...[
//               Positioned(
//                 bottom: 0,
//                 left: 0,
//                 right: 0,
//                 child: AnimatedOpacity(
//                   opacity: _showControls ? 1 : 0,
//                   duration: const Duration(milliseconds: 300),
//                   child: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(vertical: 10),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.bottomCenter,
//                         end: Alignment.topCenter,
//                         colors: [Colors.black87, Colors.black26],
//                       ),
//                     ),
//                     child: SafeArea(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 IconButton(
//                                   icon: StreamBuilder(
//                                     stream: _player.stream.volume,
//                                     builder: (context, snapshot) {
//                                       return Icon(
//                                         snapshot.data == null || snapshot.data! > 0 ? Icons.volume_up_rounded : Icons.volume_off_rounded,
//                                         color: Colors.white,
//                                         size: 34,
//                                       );
//                                     }
//                                   ),
//                                   onPressed: () => _onControlsChanged(() => _player.setVolume(_player.state.volume > 0 ? 0.0 : 100.0))
//                                 ),
//                                 const SizedBox(width: 20),
//                                 IconButton(
//                                   icon: Icon(
//                                     Icons.replay_5_rounded,
//                                     color: Colors.white,
//                                     size: 34,
//                                   ),
//                                   onPressed: () => _onControlsChanged(() => _player.seek(Duration(milliseconds: max(0, _player.state.position.inMilliseconds - 5000))))
//                                 ),
//                                 const SizedBox(width: 20),
//                                 IconButton(
//                                   icon: StreamBuilder<bool>(
//                                     stream: _player.stream.playing,
//                                     builder: (context, snapshot) {
//                                       return Icon(
//                                         snapshot.data ?? _player.state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
//                                         color: Colors.white,
//                                         size: 48,
//                                       );
//                                     },
//                                   ),
//                                   onPressed: () => _onControlsChanged(() => _player.playOrPause()),
//                                 ),
//                                 const SizedBox(width: 20),
//                                 IconButton(
//                                   icon: Icon(
//                                     Icons.forward_5_rounded,
//                                     color: Colors.white,
//                                     size: 34,
//                                   ),
//                                   onPressed: () => _onControlsChanged(() => _player.seek(Duration(milliseconds: min(_player.state.duration.inMilliseconds, _player.state.position.inMilliseconds + 5000))))
//                                 ),
//                                 const SizedBox(width: 20),
//                                 PopupMenuButton<double>(
//                                   initialValue: _player.state.rate,
//                                   icon: const Icon(
//                                     Icons.settings_rounded,
//                                     color: Colors.white,
//                                     size: 34
//                                   ),
//                                   onSelected: (value) => _onControlsChanged(() => _player.setRate(value)),
//                                   itemBuilder: (context) => playbackSpeeds.map((speed) {
//                                     return PopupMenuItem<double>(
//                                       value: speed,
//                                       child: Text('${speed % 1 == 0 ? speed.toInt() : speed}x'),
//                                     );
//                                   }).toList(),
//                                 )
//                               ],
//                             ),
//                             ValueListenableBuilder(
//                               valueListenable: _sliderNotifier,
//                               builder: (context, value, child) {
//                                 final duration = _player.state.duration;
//                                 return Row(
//                                   children: [
//                                     Text(
//                                       _formatDuration(Duration(milliseconds: value.round())),
//                                       style: const TextStyle(color: Colors.white),
//                                     ),
//                                     Expanded(
//                                       child: Slider(
//                                         inactiveColor: Constants.primaryColor.withAlpha(100),
//                                         value: min(value, duration.inMilliseconds.toDouble()),
//                                         max: duration.inMilliseconds.toDouble(),
//                                         onChangeStart: (_) {
//                                           _isDragging = true;
//                                           _disposeHideControlsTimer();
//                                         },
//                                         onChanged: (value) => _sliderNotifier.value = value,
//                                         onChangeEnd: (value) async {
//                                           await _player.seek(Duration(milliseconds: value.toInt()));
//                                           _isDragging = false;
//                                         }
//                                       ),
//                                     ),
//                                     Text(
//                                       _formatDuration(duration),
//                                       style: const TextStyle(color: Colors.white),
//                                     ),
//                                   ],
//                                 );
//                               }
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               StreamBuilder(
//                 stream: _player.stream.buffering,
//                 builder: (context, snapshot) => snapshot.data == true ? CenteredLargeCircularProgressIndicator(platform: widget.platform) : const SizedBox.shrink(),
//               ),
//             ]
//           ],
//         ),
//       )
//     );
//   }

// }

// // Minimalist video player used for testing
// // class VideoPlayerScreen extends StatefulWidget {

// //   final String url;
// //   final String? audioUrl;
// //   final Post? post;

// //   const VideoPlayerScreen({
// //     super.key,
// //     required this.url,
// //     this.audioUrl,
// //     this.post
// //   });

// //   @override
// //   State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();

// // }

// // class _VideoPlayerScreenState extends State<VideoPlayerScreen> {

// //   final Player _player = Player();
// //   late final VideoController _controller = VideoController(_player);

// //   @override
// //   void initState() {
// //     super.initState();
// //     _init();
// //   }

// //   @override
// //   void dispose() {
// //     _player.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _init() async {
// //     final dashUrl = 'https://v.redd.it/v0dzavvzo6fg1/DASHPlaylist.mpd';
// //     final videoUrl = 'https://v.redd.it/v0dzavvzo6fg1/CMAF_1080.mp4';
// //     final audioUrl = 'https://v.redd.it/v0dzavvzo6fg1/CMAF_AUDIO_128.mp4';
// //     if (_player.platform is NativePlayer) {
// //       final platform = _player.platform as NativePlayer;
// //     }

// //     await _player.open(
// //       Media(
// //         dashUrl
// //       ),
// //       play: true,
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Video(controller: _controller);
// //   }

// // }