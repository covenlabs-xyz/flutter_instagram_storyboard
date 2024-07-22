import 'package:flutter/material.dart';
import 'package:flutter_instagram_storyboard/flutter_instagram_storyboard.dart';

class StoryListView extends StatefulWidget {
  final List<StoryButtonData> buttonDatas;
  final double buttonSpacing;
  final double paddingLeft;
  final double paddingRight;
  final double paddingTop;
  final double paddingBottom;
  final ScrollPhysics? physics;
  final IStoryPageTransform? pageTransform;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final double listHeight;
  final double buttonWidth;
  final ScrollController scrollController;
  final bool allStoryUploaded;
  final Widget? indicator;
  final Widget? newStoryIcon;
  final Function()? newStoryOnTap;
  final Widget? newStoryTitle;
  final Widget? bottomBar;
  final double bottomSafeHeight;
  final Function(int? currentSegmentIndex, int? currentIndex)? fingerSwipeUp;

  const StoryListView({
    Key? key,
    required this.buttonDatas,
    this.buttonSpacing = 14,
    this.paddingLeft = 16.0,
    this.listHeight = 110.0,
    this.paddingRight = 16.0,
    this.paddingTop = 0,
    this.paddingBottom = 0.0,
    this.physics,
    this.pageTransform,
    this.buttonWidth = 57.0,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    required this.scrollController,
    this.allStoryUploaded = true,
    this.indicator,
    this.newStoryIcon,
    this.newStoryOnTap,
    this.newStoryTitle,
    this.bottomBar,
    required this.bottomSafeHeight,
    this.fingerSwipeUp,
  }) : super(key: key);

  @override
  State<StoryListView> createState() => _StoryListViewState();
}

class _StoryListViewState extends State<StoryListView> {
  @override
  void initState() {
    super.initState();
  }

  void _onButtonPressed(StoryButtonData buttonData) {
    Navigator.of(context).push(
      StoryRoute(
        storyContainerSettings: StoryContainerSettings(
          buttonData: buttonData,
          tapPosition: buttonData.buttonCenterPosition!,
          curve: buttonData.pageAnimationCurve,
          allButtonDatas: widget.buttonDatas,
          pageTransform: widget.pageTransform,
          storyListScrollController: widget.scrollController,
          bottomSafeHeight: widget.bottomSafeHeight,
          fingerSwipeUp: (currentSegmentIndex, currentIndex) =>
              widget.fingerSwipeUp != null ? widget.fingerSwipeUp!(currentSegmentIndex, currentIndex) : null,
        ),
        duration: buttonData.pageAnimationDuration,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonDatas = widget.buttonDatas.where((b) {
      return b.isVisibleCallback();
    }).toList();
    if (buttonDatas.isEmpty) {
      return SizedBox(
        height: widget.listHeight,
        child: Padding(
          padding: EdgeInsets.only(
            top: widget.paddingTop,
            bottom: widget.paddingBottom,
            left: widget.paddingLeft,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => widget.newStoryOnTap!(),
              child: Column(
                children: [
                  Container(
                    width: widget.buttonWidth,
                    height: widget.buttonWidth,
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF641F8F),
                          Color(0xFFA046D9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(widget.buttonWidth),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: Colors.white,
                        child: Center(
                          child: widget.newStoryIcon != null
                              ? widget.newStoryIcon
                              : Icon(Icons.add_a_photo_outlined, size: 24),
                        ),
                      ),
                    ),
                  ),
                  if (widget.newStoryTitle != null) widget.newStoryTitle!
                ],
              ),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: widget.listHeight,
      child: Padding(
        padding: EdgeInsets.only(
          top: widget.paddingTop,
          bottom: widget.paddingBottom,
        ),
        child: ListView.builder(
          controller: widget.scrollController,
          physics: widget.physics,
          scrollDirection: Axis.horizontal,
          itemBuilder: (c, int index) {
            final isLast = index == buttonDatas.length - 1;
            final isFirst = index == 0;
            if (index < buttonDatas.length + (widget.newStoryOnTap != null ? 1 : 0)) {
              if (isFirst && widget.newStoryOnTap != null) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: widget.paddingLeft,
                    right: isLast ? widget.paddingRight : widget.buttonSpacing,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => widget.newStoryOnTap!(),
                      child: Column(
                        children: [
                          Container(
                            child: widget.newStoryIcon != null
                                ? widget.newStoryIcon
                                : Icon(Icons.add_a_photo_outlined, size: 24),
                          ),
                          if (widget.newStoryTitle != null) widget.newStoryTitle!
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                final buttonData = buttonDatas[index - (widget.newStoryOnTap != null ? 1 : 0)];

                return Padding(
                  padding: EdgeInsets.only(
                    left: isFirst ? widget.paddingLeft : 0,
                    right: isLast ? widget.paddingRight : widget.buttonSpacing,
                  ),
                  child: SizedBox(
                    width: widget.buttonWidth,
                    child: StoryButton(
                      buttonData: buttonData,
                      allButtonDatas: buttonDatas,
                      pageTransform: widget.pageTransform,
                      storyListViewController: widget.scrollController,
                      onPressed: _onButtonPressed,
                    ),
                  ),
                );
              }
            } else {
              return widget.allStoryUploaded
                  ? widget.indicator == null
                      ? Padding(
                          padding: EdgeInsets.all(16),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                backgroundColor: Colors.transparent,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        )
                      : widget.indicator
                  : SizedBox();
            }
          },
          itemCount: buttonDatas.length + (widget.newStoryOnTap != null ? 2 : 1),
        ),
      ),
    );
  }
}
