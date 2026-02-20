import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/custom_interactive_viewer.dart';
import 'package:lurk/widgets/media_scaffold.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

const hideControlsAfterDuration = Duration(seconds: 2);
const List<double> playbackSpeeds = [0.5, 1, 1.25, 1.5, 2];

class VideoViewerScreen extends StatefulWidget {

  final Community activeCommunity;
  final String url;
  final Post? post;

  const VideoViewerScreen({
    super.key,
    required this.activeCommunity,
    required this.url,
    this.post
  });

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();

}

class _VideoViewerScreenState extends State<VideoViewerScreen> {

  late VideoPlayerController _videoController;
  final ValueNotifier<double> _sliderNotifier = ValueNotifier(0);
  late final Uri _uri = Uri.parse(widget.url);
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isDragging = false;
  Timer? _hideControlsTimer;
  String? _dashManifest;

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
    if (_uri.host == 'v.redd.it') {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('${widget.url}/DASHPlaylist.mpd'));
      request.headers.set('User-Agent', widget.activeCommunity.platform.savedOrDefaultUserAgent);

      final response = await request.close();
      _dashManifest = await response.transform(utf8.decoder).join();
      _dashManifest = _dashManifest!.replaceFirstMapped(
        RegExp(r'(<MPD[^>]*>)'), 
        (match) => '${match.group(1)}<BaseURL>${widget.url}/</BaseURL>'
      );

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/manifest.mpd');
      await tempFile.writeAsString(_dashManifest!);
      _videoController = VideoPlayerController.file(tempFile);
    }
    else {
      _videoController = VideoPlayerController.networkUrl(
        _uri,
        httpHeaders: {
          'User-Agent': widget.activeCommunity.platform.savedOrDefaultUserAgent,
        },
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: false),
      );
    }

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

  void _onSave(BuildContext context) async {
    if (_dashManifest != null) {
      saveMedia(
        context: context,
        platform: widget.activeCommunity.platform,
        snackbarMediaTypeMessage: 'video',
        save: () async {

          String getBestUrl(String setContent) {
            final reps = RegExp(r'<Representation [^>]*bandwidth="(\d+)"[^>]*>.*?<BaseURL>(.*?)<\/BaseURL>', dotAll: true).allMatches(setContent);
            int maxBandwidth = -1;
            String? bestSegment;
            for (final match in reps) {
              final bandwidth = int.parse(match.group(1)!);
              if (bandwidth > maxBandwidth) {
                maxBandwidth = bandwidth;
                bestSegment = match.group(2);
              }
            }
            return '${widget.url}/$bestSegment';
          }

          final videoSet = RegExp(r'<AdaptationSet [^>]*contentType="video".*?<\/AdaptationSet>', dotAll: true).firstMatch(_dashManifest!)!.group(0)!;
          final audioSet = RegExp(r'<AdaptationSet [^>]*contentType="audio".*?<\/AdaptationSet>', dotAll: true).firstMatch(_dashManifest!)!.group(0)!;
          final bestVideoUrl = getBestUrl(videoSet);
          final bestAudioUrl = getBestUrl(audioSet);
          final userAgent = widget.activeCommunity.platform.savedOrDefaultUserAgent;
          final videoPath = await downloadMediaToTemp(bestVideoUrl, userAgent);
          final audioPath = await downloadMediaToTemp(bestAudioUrl, userAgent);
          final tempDir = await getTemporaryDirectory();
          final outputPath = '${tempDir.path}/${_uri.pathSegments.last}.mp4';
          final session = await FFmpegKit.executeWithArguments([
            '-y', 
            '-i', videoPath, 
            '-i', audioPath, 
            '-c', 'copy', 
            '-map', '0:v:0', 
            '-map', '1:a:0', 
            outputPath
          ]);
          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            Gal.putVideo(outputPath);
          }
          else {
            final stackTrace = await session.getFailStackTrace();
            // final logs = await session.getLogs();
            // final errorLog = logs.isNotEmpty ? logs.map((l) => l.getMessage()).join('\n') : "Unknown FFmpeg error";
            // dev.log('FFmpeg error Log:\n$errorLog');
            // dev.log(stackTrace.toString());
            throw Exception(stackTrace);
          }
        }
      );
    }
    else {
      saveVideo(
        context: context,
        platform: widget.activeCommunity.platform,
        url: widget.url,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaScaffold(
      activeCommunity: widget.activeCommunity,
      url: widget.url,
      type: 'video',
      post: widget.post,
      onSave: _onSave,
      body: Stack(
        children: [
          if (!_isInitialized)
            _ProgressIndicator(
              platform: widget.activeCommunity.platform,
              size: widget.post?.mediaSize,
            )
          else ...[
            Listener(
              onPointerUp: (event) {
                if (event.buttons == 0) { 
                  _onControlsChanged(() => setState(() => _showControls = !_showControls));
                }
              },
              child: GestureDetector(
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  showSimpleOptionsBottomSheet(
                    context: context,
                    options: MediaScaffold.getOptions(
                      context: context,
                      activeCommunity: widget.activeCommunity,
                      type: 'video',
                      url: widget.url,
                      onSave: _onSave
                    )
                  );
                },
                child: CustomInteractiveViewer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController)
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubicEmphasized,
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
                                  onSelected: (value) => _onControlsChanged(() => setState(() => _videoController.setPlaybackSpeed(value))),
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
                                          child: Slider(
                                            value: min(sliderValue, duration.inMilliseconds.toDouble()),
                                            max: duration.inMilliseconds.toDouble(),
                                            inactiveColor: Theme.of(context).colorScheme.primary.withAlpha(100),
                                            onChangeStart: (_) {
                                              _isDragging = true;
                                              _disposeHideControlsTimer();
                                            },
                                            onChanged: (value) => _sliderNotifier.value = value,
                                            onChangeEnd: (value) async {
                                              await _videoController.seekTo(Duration(milliseconds: value.toInt()));
                                              _isDragging = false;
                                            }
                                          )
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
                return value.isBuffering && !value.isCompleted
                    ? _ProgressIndicator(
                        platform: widget.activeCommunity.platform,
                        size: widget.post?.mediaSize,
                      )
                    : const SizedBox.shrink();
              },
            ),
          ]
        ],
      )
    );
  }

}

class _ProgressIndicator extends StatelessWidget {
  
  final Platform platform;
  final Size? size;

  const _ProgressIndicator({
    required this.platform,
    required this.size
  });

  @override
  Widget build(BuildContext context) {
    final progressIndicator = const LargeCenteredCircularProgressIndicator();
    if (size != null) {
      return AspectRatio(
        aspectRatio: size!.width / size!.height,
        child: progressIndicator
      );
    }
    return progressIndicator;
  }

}