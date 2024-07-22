import 'dart:async';
import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_storyboard/flutter_instagram_storyboard.dart';
import 'package:flutter_instagram_storyboard/src/first_build_mixin.dart';
import 'package:native_video_player/native_video_player.dart';

class StoryPageContainerView extends StatefulWidget {
  final StoryButtonData buttonData;
  final Function(bool delete) onStoryComplete;
  final PageController? pageController;
  final VoidCallback? onClosePressed;
  final double bottomSafeHeight;
  final StoryTimelineController? storyTimelineController;
  final List<StoryButtonData> allButtonDatas;
  final int currentIndex;
  final Function(int? currentSegmentIndex, int? currentIndex) fingerSwipeUp;

  const StoryPageContainerView({
    Key? key,
    required this.buttonData,
    required this.onStoryComplete,
    this.pageController,
    this.onClosePressed,
    required this.bottomSafeHeight,
    required this.storyTimelineController,
    required this.allButtonDatas,
    required this.currentIndex,
    required this.fingerSwipeUp,
  }) : super(key: key);

  @override
  State<StoryPageContainerView> createState() => _StoryPageContainerViewState();
}

class _StoryPageContainerViewState extends State<StoryPageContainerView> with FirstBuildMixin {
  late StoryTimelineController _storyController;
  final Stopwatch _stopwatch = Stopwatch();
  Offset _pointerDownPosition = Offset.zero;
  int _pointerDownMillis = 0;
  double _pageValue = 0.0;
  double _offsetY = 0.0;
  NativeVideoPlayerController? nativeVideoPlayerController;

  @override
  void initState() {
    _storyController = widget.buttonData.storyController ?? StoryTimelineController();
    _stopwatch.start();
    _storyController.addListener(_onTimelineEvent);
    super.initState();
  }

  @override
  void didFirstBuildFinish(BuildContext context) async {
    widget.pageController?.addListener(_onPageControllerUpdate);
    widget.buttonData.isWatched?.call(_curSegmentIndex);
  }

  void _onPageControllerUpdate() {
    if (widget.pageController?.hasClients != true) {
      return;
    }
    _pageValue = widget.pageController?.page ?? 0.0;
    _storyController._setTimelineAvailable(_timelineAvailable);
  }

  bool get _timelineAvailable {
    return _pageValue % 1.0 == 0.0;
  }

  void _onTimelineEvent(StoryTimelineEvent event) async {
    if (event == StoryTimelineEvent.storyComplete) {
      widget.onStoryComplete.call(false);
    }
    if (event == StoryTimelineEvent.segmentComplete) {
      await loadVideoSource();
    }

    setState(() {});
  }

  Widget _buildCloseButton() {
    Widget closeButton;
    if (widget.buttonData.closeButton != null) {
      closeButton = widget.buttonData.closeButton!;
    } else {
      closeButton = Container(
        height: 40.0,
        width: 40.0,
        child: MaterialButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (widget.onClosePressed != null) {
              widget.onClosePressed!.call();
              _storyController.videoDispose();
            } else {
              Navigator.of(context).pop();
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              40.0,
            ),
          ),
          child: SizedBox(
            height: 40.0,
            width: 40.0,
            child: Icon(
              Icons.close,
              size: 28.0,
              color: widget.buttonData.defaultCloseButtonColor,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
          closeButton,
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Padding(
      padding: EdgeInsets.only(
        top: widget.buttonData.timlinePadding?.top ?? 16.0,
        left: widget.buttonData.timlinePadding?.left ?? 16.0,
        right: widget.buttonData.timlinePadding?.right ?? 16.0,
        bottom: widget.buttonData.timlinePadding?.bottom ?? 0.0,
      ),
      child: StoryTimeline(
        controller: _storyController,
        buttonData: widget.buttonData,
        allButtonDatas: widget.allButtonDatas,
        onStoryComplete: (bool delete) => widget.onStoryComplete(delete),
        currentIndex: widget.currentIndex,
      ),
    );
  }

  int get _curSegmentIndex {
    return widget.buttonData.currentSegmentIndex;
  }

  Widget _buildPageContent() {
    if (_offsetY == 0.0) _storyController.pause();

    return SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height - MediaQuery.of(context).viewPadding.top - widget.bottomSafeHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Builder(
            builder: (context) {
              if (widget.buttonData.mediaType?[_curSegmentIndex] == 'VIDEO') {
                return Builder(builder: (context) {
                  if (_offsetY == 0.0) _storyController.unpause();

                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      NativeVideoPlayerView(
                        onViewReady: (controller) async {
                          if (nativeVideoPlayerController == null) {
                            await Future.delayed(kThemeAnimationDuration);
                          }
                          nativeVideoPlayerController = controller;
                          _storyController._state?.nativeVideoPlayerController = nativeVideoPlayerController;
                          await nativeVideoPlayerController?.setVolume(1);
                          nativeVideoPlayerController?.play();
                          await loadVideoSource();
                        },
                      ),
                    ],
                  );
                });
              } else if (widget.buttonData.mediaType?[_curSegmentIndex] == "IMAGE") {
                return CachedNetworkImage(
                  errorWidget: (context, url, error) => Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: Center(
                      child: Icon(
                        Icons.no_photography_outlined,
                        weight: 150,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  imageUrl: widget.buttonData.backgroundImage[_curSegmentIndex],
                  imageBuilder: (context, imageProvider) {
                    if (_offsetY == 0.0) _storyController.unpause();

                    return Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                          ),
                        ),
                        widget.buttonData.storyPages[_curSegmentIndex],
                      ],
                    );
                  },
                  fadeOutDuration: const Duration(milliseconds: 150),
                  fadeInDuration: const Duration(milliseconds: 150),
                  progressIndicatorBuilder: (context, url, progress) {
                    return Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.black,
                        color: Colors.white,
                        value: progress.progress,
                      ),
                    );
                  },
                );
              } else {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                  child: Center(
                    child: Icon(
                      Icons.no_photography_outlined,
                      weight: 150,
                      color: Colors.white,
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: (widget.buttonData.bottomBar != null && widget.buttonData.bottomBar!.isNotEmpty) ? widget.buttonData.bottomBar![_curSegmentIndex] : SizedBox(height: widget.bottomSafeHeight),
    );
  }

  Widget _buildTopBar() {
    return widget.buttonData.topBar?[_curSegmentIndex] ?? SizedBox();
  }

  bool _isLeftPartOfStory(Offset position) {
    if (!mounted) {
      return false;
    }
    final storyWidth = context.size!.width;
    return position.dx <= (storyWidth * .499);
  }

  Widget _buildPageStructure() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Listener(
                onPointerDown: (PointerDownEvent event) {
                  if (_offsetY != 0.0) {
                    setState(() {
                      _offsetY = 0.0;
                    });
                  }
                  _pointerDownMillis = _stopwatch.elapsedMilliseconds;
                  _pointerDownPosition = event.position;
                  _storyController.pause();
                  if (widget.buttonData.mediaType?[_curSegmentIndex] == 'VIDEO') _storyController._state?.videoPause();
                },
                onPointerUp: (PointerUpEvent event) {
                  if (_offsetY > MediaQuery.of(context).size.height * 0.1) {
                    _storyController.videoDispose();
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      _offsetY = 0.0;
                    });
                  }
                  final pointerUpMillis = _stopwatch.elapsedMilliseconds;
                  final maxPressMillis = kPressTimeout.inMilliseconds * 2;
                  final diffMillis = pointerUpMillis - _pointerDownMillis;
                  if (diffMillis <= maxPressMillis && event.position.dy > (MediaQuery.of(context).padding.top + 70)) {
                    final position = event.position;
                    final distance = (position - _pointerDownPosition).distance;
                    if (distance < 5.0) {
                      final isLeft = _isLeftPartOfStory(position);
                      if (isLeft) {
                        _storyController.previousSegment();
                      } else {
                        _storyController.nextSegment();
                      }
                    }
                  }
                  if (_offsetY < MediaQuery.of(context).size.height * 0.1) {
                    _storyController.unpause();
                    if (widget.buttonData.mediaType?[_curSegmentIndex] == 'VIDEO') _storyController._state?.videoPlay();
                  }
                },
                onPointerMove: (PointerMoveEvent event) {
                  if (event.delta.dy > 0) {
                    setState(() {
                      _offsetY += event.delta.dy;
                    });
                  } else if (event.delta.dy < -10 && event.delta.dx == 0) {
                    widget.fingerSwipeUp(_curSegmentIndex, widget.currentIndex);
                    _storyController.pause();
                    if (widget.buttonData.mediaType?[_curSegmentIndex] == 'VIDEO') _storyController._state?.videoPause();
                  }
                },
                child: _buildPageContent(),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTimeline(),
                  _buildCloseButton(),
                ],
              ),
              _buildTopBar(),
              _bottomBar(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> loadVideoSource() async {
    try {
      final videoSource = await VideoSource.init(
        type: VideoSourceType.network,
        path: widget.buttonData.backgroundImage[_curSegmentIndex],
      );
      await nativeVideoPlayerController?.loadVideoSource(videoSource);

      nativeVideoPlayerController?.onPlaybackReady.addListener(() {
        nativeVideoPlayerController?.play();
      });

      nativeVideoPlayerController?.onPlaybackEnded.addListener(() {
        nativeVideoPlayerController?.stop();
      });
    } catch (e) {
      debugPrint('Düzenleme ekranını açarken bir hata oluştu $e');
    }
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_onPageControllerUpdate);
    _stopwatch.stop();
    _storyController.removeListener(_onTimelineEvent);
    // player.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Transform.translate(
          offset: Offset(0, _offsetY),
          child: _buildPageStructure(),
        ),
      ),
    );
  }
}

enum StoryTimelineEvent {
  storyComplete,
  segmentComplete,
}

typedef StoryTimelineCallback = Function(StoryTimelineEvent);

class StoryTimelineController {
  _StoryTimelineState? _state;

  final HashSet<StoryTimelineCallback> _listeners = HashSet<StoryTimelineCallback>();

  void addListener(StoryTimelineCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(StoryTimelineCallback callback) {
    _listeners.remove(callback);
  }

  void _onStoryComplete() {
    _notifyListeners(StoryTimelineEvent.storyComplete);
  }

  void _onSegmentComplete() {
    _notifyListeners(StoryTimelineEvent.segmentComplete);
  }

  void _notifyListeners(StoryTimelineEvent event) {
    for (var e in _listeners) {
      e.call(event);
    }
  }

  int currentIndex() => _state?.currentIndex() ?? 0;
  int currentSegmentIndex() => _state?.currentSegmentIndex() ?? 0;

  void deleteSegment(BuildContext context, int segmentCount) {
    if ((_state?._curSegmentIndex ?? 0) == 0) {
      if ((segmentCount - 1) == 0) {
        Navigator.pop(context);
        _state?.deleteStory();
      } else {
        _state?.deleteSegment();
        _state?.nextSegment();
      }
    } else {
      _state?.deleteSegment();
      _state?.previousSegment();
    }
  }

  void deleteStory() {
    _state?.deleteStory();
  }

  void nextStory() {
    _state?.nextStory();
  }

  void nextSegment() {
    _state?.nextSegment();
  }

  void previousSegment() {
    _state?.previousSegment();
  }

  void pause() {
    _state?.pause();
  }

  void keyboardOpened() {
    _state?.keyboardOpened();
  }

  void keyboardClosed() {
    _state?.keyboardClosed();
  }

  void _setTimelineAvailable(bool value) {
    _state?._setTimelineAvailable(value);
  }

  void unpause() {
    _state?.unpause();
  }

  void dispose() {
    _listeners.clear();
  }

  void videoPlay() {
    _state?.videoPlay();
  }

  void videoPause() {
    _state?.videoPause();
  }

  Future videoDispose() async {
    await _state?.videoDispose();
  }
}

class StoryTimeline extends StatefulWidget {
  final StoryTimelineController controller;
  final StoryButtonData buttonData;
  final List<StoryButtonData> allButtonDatas;
  final Function(bool delete) onStoryComplete;
  final int currentIndex;

  const StoryTimeline({
    Key? key,
    required this.controller,
    required this.buttonData,
    required this.allButtonDatas,
    required this.onStoryComplete,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<StoryTimeline> createState() => _StoryTimelineState();
}

class _StoryTimelineState extends State<StoryTimeline> {
  late Timer _timer;
  int _accumulatedTime = 0;
  int _maxAccumulator = 0;
  bool _isPaused = true;
  bool _isKeyboardOpened = false;
  bool _isTimelineAvailable = true;
  NativeVideoPlayerController? nativeVideoPlayerController;

  @override
  void initState() {
    super.initState();

    _maxAccumulator = widget.buttonData.segmentDuration[_curSegmentIndex].inMilliseconds;
    _timer = Timer.periodic(
      const Duration(
        milliseconds: kStoryTimerTickMillis,
      ),
      _onTimer,
    );
    widget.controller._state = this;
  }

  void _setTimelineAvailable(bool value) {
    _isTimelineAvailable = value;
  }

  void _onTimer(timer) {
    if (_isPaused || !_isTimelineAvailable || _isKeyboardOpened) {
      return;
    }
    if (_accumulatedTime + kStoryTimerTickMillis <= _maxAccumulator) {
      _accumulatedTime += kStoryTimerTickMillis;
      if (_accumulatedTime >= _maxAccumulator) {
        if (_isLastSegment) {
          _maxAccumulator = widget.buttonData.segmentDuration[_curSegmentIndex].inMilliseconds;
          _onStoryComplete();
        } else {
          _accumulatedTime = 0;
          _curSegmentIndex++;
          _maxAccumulator = widget.buttonData.segmentDuration[_curSegmentIndex].inMilliseconds;
          _onSegmentComplete();
        }
      }
      setState(() {});
    }
  }

  void _onStoryComplete() async {
    widget.buttonData.markAsWatched();
    widget.controller._onStoryComplete();
  }

  void _onSegmentComplete() async {
    if (widget.buttonData.storyWatchedContract == StoryWatchedContract.onSegmentEnd) {
      widget.buttonData.isWatched?.call(_curSegmentIndex);
    }

    widget.controller._onSegmentComplete();
  }

  bool get _isLastSegment {
    return _curSegmentIndex == _numSegments - 1;
  }

  int get _numSegments {
    return widget.buttonData.storyPages.length;
  }

  set _curSegmentIndex(int value) {
    if (value >= _numSegments) {
      value = _numSegments - 1;
    } else if (value < 0) {
      value = 0;
    }
    widget.buttonData.currentSegmentIndex = value;
  }

  int get _curSegmentIndex {
    return widget.buttonData.currentSegmentIndex;
  }

  int currentIndex() => widget.currentIndex;
  int currentSegmentIndex() => _curSegmentIndex;

  void deleteSegment() {
    if (_isKeyboardOpened) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      widget.buttonData.storyPages.removeAt(_curSegmentIndex);
    }
    setState(() {});
  }

  void deleteStory() {
    widget.onStoryComplete.call(true);
  }

  void nextStory() {
    if (_isKeyboardOpened) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      _accumulatedTime = _maxAccumulator;
      _onStoryComplete();
    }
  }

  void nextSegment() {
    if (_isKeyboardOpened) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      if (_isLastSegment) {
        _accumulatedTime = _maxAccumulator;
        _onStoryComplete();
      } else {
        _accumulatedTime = 0;
        _curSegmentIndex++;
        _onSegmentComplete();
      }
    }
  }

  void previousSegment() {
    if (_isKeyboardOpened) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      if (_accumulatedTime == _maxAccumulator) {
        _accumulatedTime = 0;
      } else {
        _accumulatedTime = 0;
        _curSegmentIndex--;
        _onSegmentComplete();
      }
    }
  }

  void videoPlay() {
    if (nativeVideoPlayerController != null) {
      nativeVideoPlayerController?.play();
    }
  }

  void videoPause() {
    if (nativeVideoPlayerController != null) {
      nativeVideoPlayerController?.pause();
    }
  }

  videoDispose() async {
    if (nativeVideoPlayerController != null) {
      nativeVideoPlayerController?.stop();
      nativeVideoPlayerController?.removeListener(() {
        setState(() {});
      });
    }
  }

  void pause() {
    _isPaused = true;
  }

  void unpause() {
    _isPaused = false;
  }

  void keyboardOpened() {
    _isKeyboardOpened = true;
  }

  void keyboardClosed() {
    _isKeyboardOpened = false;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2.0,
      width: double.infinity,
      child: CustomPaint(
        painter: _TimelinePainter(
          fillColor: widget.buttonData.timelineFillColor.withOpacity(0.5),
          backgroundColor: widget.buttonData.timelineBackgroundColor.withOpacity(0.3),
          curSegmentIndex: _curSegmentIndex,
          numSegments: _numSegments,
          percent: _accumulatedTime > kStoryTimerTickMillis ? _accumulatedTime / _maxAccumulator : 0,
          spacing: widget.buttonData.timelineSpacing,
          thikness: widget.buttonData.timelineThikness,
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final Color fillColor;
  final Color backgroundColor;
  final int curSegmentIndex;
  final int numSegments;
  final double percent;
  final double spacing;
  final double thikness;

  _TimelinePainter({
    required this.fillColor,
    required this.backgroundColor,
    required this.curSegmentIndex,
    required this.numSegments,
    required this.percent,
    required this.spacing,
    required this.thikness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thikness
      ..color = backgroundColor
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thikness
      ..color = fillColor
      ..style = PaintingStyle.stroke;

    final maxSpacing = (numSegments - 1) * spacing;
    final maxSegmentLength = (size.width - maxSpacing) / numSegments;

    for (var i = 0; i < numSegments; i++) {
      final start = Offset(
        ((maxSegmentLength + spacing) * i),
        0.0,
      );
      final end = Offset(
        start.dx + maxSegmentLength,
        0.0,
      );

      canvas.drawLine(
        start,
        end,
        bgPaint,
      );
    }

    for (var i = 0; i < numSegments; i++) {
      final start = Offset(
        ((maxSegmentLength + spacing) * i),
        0.0,
      );
      var endValue = start.dx;
      if (curSegmentIndex > i) {
        endValue = start.dx + maxSegmentLength;
      } else if (curSegmentIndex == i) {
        endValue = start.dx + (maxSegmentLength * percent);
      }
      final end = Offset(
        endValue,
        0.0,
      );
      if (endValue == start.dx) {
        continue;
      }
      canvas.drawLine(
        start,
        end,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
