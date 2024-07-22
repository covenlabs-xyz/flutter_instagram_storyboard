import 'package:flutter/material.dart';
import 'package:flutter_instagram_storyboard/flutter_instagram_storyboard.dart';
import 'package:flutter_instagram_storyboard/src/first_build_mixin.dart';
import 'package:flutter_instagram_storyboard/src/set_state_after_frame_mixin.dart';

class StoryButton extends StatefulWidget {
  final StoryButtonData buttonData;
  final ValueChanged<StoryButtonData> onPressed;

  /// [allButtonDatas] required to be able to page through
  /// all stories
  final List<StoryButtonData> allButtonDatas;
  final IStoryPageTransform? pageTransform;
  final ScrollController storyListViewController;

  const StoryButton({
    Key? key,
    required this.onPressed,
    required this.buttonData,
    required this.allButtonDatas,
    required this.storyListViewController,
    this.pageTransform,
  }) : super(key: key);

  @override
  State<StoryButton> createState() => _StoryButtonState();
}

class _StoryButtonState extends State<StoryButton>
    with SetStateAfterFrame, FirstBuildMixin
    implements IButtonPositionable, IWatchMarkable {
  double? _buttonWidth;

  @override
  void initState() {
    _updateDependencies();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant StoryButton oldWidget) {
    _updateDependencies();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didFirstBuildFinish(BuildContext context) {
    setState(() {
      _buttonWidth = context.size?.width;
    });
  }

  void _updateDependencies() {
    widget.buttonData._buttonPositionable = this;
    widget.buttonData._iWatchMarkable = this;
  }

  Widget _buildChild() {
    if (_buttonWidth == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _buttonWidth,
      child: widget.buttonData.child,
    );
  }

  @override
  Offset? get centerPosition {
    if (!mounted) {
      return null;
    }
    final renderBox = context.findRenderObject() as RenderBox;
    return renderBox.localToGlobal(
      Offset(
        renderBox.paintBounds.width * .5,
        renderBox.paintBounds.height * .5,
      ),
    );
  }

  @override
  Offset? get rightPosition {
    if (!mounted) {
      return null;
    }
    final renderBox = context.findRenderObject() as RenderBox;
    return renderBox.localToGlobal(
      Offset(
        renderBox.paintBounds.width,
        0.0,
      ),
    );
  }

  @override
  Offset? get leftPosition {
    if (!mounted) {
      return null;
    }
    final renderBox = context.findRenderObject() as RenderBox;
    return renderBox.localToGlobal(
      Offset.zero,
    );
  }

  void _onTap() {
    widget.onPressed.call(widget.buttonData);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: widget.buttonData.aspectRatio,
          child: Container(
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(
              gradient: widget.buttonData.allStoryWatched == true
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFA073FF),
                      ],
                    )
                  : null,
              color: widget.buttonData.allStoryWatched == false ? Color(0xFF2C2440) : null,
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(width: widget.buttonData.borderOffset, color: Color(0xFF130A29)),
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: widget.buttonData.buttonDecoration,
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      splashFactory: widget.buttonData.inkFeatureFactory ?? InkRipple.splashFactory,
                      onTap: _onTap,
                      child: const SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildChild(),
      ],
    );
  }

  @override
  void markAsWatched() {
    safeSetState(() {});
  }
}

const int kStoryTimerTickMillis = 50;

enum StoryWatchedContract {
  onStoryStart,
  onStoryEnd,
  onSegmentEnd,
}

typedef IsVisibleCallback = bool Function();

class StoryButtonData {
  static bool defaultIsVisibleCallback() {
    return true;
  }

  /// This affects a border around button
  /// after the story was watched
  /// the border will disappear
  void markAsWatched() {
    allStoryWatched = false;
    _iWatchMarkable?.markAsWatched();
  }

  IButtonPositionable? _buttonPositionable;
  IWatchMarkable? _iWatchMarkable;

  final StoryTimelineController? storyController;
  final StoryWatchedContract storyWatchedContract;
  final Curve? pageAnimationCurve;
  final Duration? pageAnimationDuration;
  final double aspectRatio;
  final BoxDecoration buttonDecoration;
  final BoxDecoration borderDecoration;
  final BoxDecoration watchBorderDecoration;
  final double borderOffset;
  final InteractiveInkFeatureFactory? inkFeatureFactory;
  final Widget child;
  final List<Widget> storyPages;
  final List<Widget>? bottomBar;
  final List<Widget>? topBar;
  final Widget? closeButton;
  final List<Duration> segmentDuration;
  final BoxDecoration containerBackgroundDecoration;
  final Color timelineFillColor;
  final Color timelineBackgroundColor;
  final Color defaultCloseButtonColor;
  final double timelineThikness;
  final double timelineSpacing;
  final EdgeInsets? timlinePadding;
  final IsVisibleCallback isVisibleCallback;
  final Function(int storyIndex)? isWatched;
  final List<String> backgroundImage;
  final List<String>? mediaType;
  bool allStoryWatched;
  int currentSegmentIndex;

  /// Usualy this is required for the final story
  /// to pop it out to its button mosition
  Offset? get buttonCenterPosition {
    return _buttonPositionable?.centerPosition;
  }

  Offset? get buttonLeftPosition {
    return _buttonPositionable?.leftPosition;
  }

  Offset? get buttonRightPosition {
    return _buttonPositionable?.rightPosition;
  }

  /// [storyWatchedContract] When you want the story to be marked as
  /// watch [StoryWatchedContract.onStoryEnd] means it will be marked only
  /// when you watched the last segment of the story
  /// [StoryWatchedContract.onSegmentEnd] the story will be marked as
  /// read after you have watched at least one segment
  /// [StoryWatchedContract.onStoryStart] the story will be marked as read
  /// right when you open it
  /// [segmentDuration] Duration of each segment in this story
  /// [isVisibleCallback] if this callback returns false
  /// the button will not appear in button list. It might be necessary
  /// if you need to hide it for some reason
  StoryButtonData({
    this.bottomBar,
    this.topBar,
    this.allStoryWatched = false,
    this.currentSegmentIndex = 0,
    this.isWatched,
    required this.backgroundImage,
    this.mediaType,
    this.storyWatchedContract = StoryWatchedContract.onSegmentEnd,
    this.storyController,
    this.aspectRatio = 1.0,
    this.timelineThikness = 4,
    this.timelineSpacing = 11,
    this.timlinePadding,
    this.inkFeatureFactory,
    this.pageAnimationCurve,
    this.isVisibleCallback = defaultIsVisibleCallback,
    this.pageAnimationDuration,
    this.timelineFillColor = Colors.white,
    this.defaultCloseButtonColor = Colors.white,
    this.timelineBackgroundColor = const Color.fromARGB(255, 200, 200, 200),
    this.closeButton,
    required this.storyPages,
    required this.child,
    required this.segmentDuration,
    this.containerBackgroundDecoration = const BoxDecoration(
      color: Color.fromARGB(255, 0, 0, 0),
    ),
    this.buttonDecoration = const BoxDecoration(
      borderRadius: BorderRadius.all(
        Radius.circular(57.0),
      ),
      color: Color.fromARGB(255, 226, 226, 226),
    ),
    this.borderDecoration = const BoxDecoration(
      borderRadius: BorderRadius.all(
        Radius.circular(57.0),
      ),
      border: Border.fromBorderSide(
        BorderSide(
          color: Color(0xFF9530BD),
          width: 1,
        ),
      ),
    ),
    this.watchBorderDecoration = const BoxDecoration(
      borderRadius: BorderRadius.all(
        Radius.circular(57),
      ),
      border: Border.fromBorderSide(
        BorderSide(
          color: Color(0xFFD9D9D9),
          width: 1,
        ),
      ),
    ),
    this.borderOffset = 3.0,
  }) : assert(
          segmentDuration[currentSegmentIndex].inMilliseconds % kStoryTimerTickMillis == 0 &&
              segmentDuration[currentSegmentIndex].inMilliseconds >= 1000,
          'Segment duration in milliseconds must be a multiple of $kStoryTimerTickMillis and not less than 1000 milliseconds',
        );
}

abstract class IWatchMarkable {
  void markAsWatched();
}

abstract class IButtonPositionable {
  Offset? get centerPosition;
  Offset? get leftPosition;
  Offset? get rightPosition;
}
