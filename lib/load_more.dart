library load_more;

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class _LoadMoreSliverWidget extends SingleChildRenderObjectWidget {
  const _LoadMoreSliverWidget({
    this.refreshIndicatorLayoutExtent = 0.0,
    this.hasLayoutExtent = false,
    this.autoRefresh = false,
    required this.onPreloadZone,
    super.child,
  }) : assert(refreshIndicatorLayoutExtent >= 0.0);

  final double refreshIndicatorLayoutExtent;

  final bool hasLayoutExtent;

  final bool autoRefresh;

  final VoidCallback onPreloadZone;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _LoadMoreSliver(
        refreshIndicatorExtent: refreshIndicatorLayoutExtent,
        hasLayoutExtent: hasLayoutExtent,
        autoRefresh: autoRefresh,
        onPreloadZone: onPreloadZone);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _LoadMoreSliver renderObject) {
    renderObject
      ..refreshIndicatorLayoutExtent = refreshIndicatorLayoutExtent
      ..hasLayoutExtent = hasLayoutExtent
      ..autoRefresh = autoRefresh
      ..onPreloadZone = onPreloadZone;
  }
}

class _LoadMoreSliver extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox> {
  _LoadMoreSliver({
    required double refreshIndicatorExtent,
    required bool hasLayoutExtent,
    required bool autoRefresh,
    required this.onPreloadZone,
    RenderBox? child,
  })  : assert(refreshIndicatorExtent >= 0.0),
        _refreshIndicatorExtent = refreshIndicatorExtent,
        _hasLayoutExtent = hasLayoutExtent,
        _autoRefresh = autoRefresh {
    this.child = child;
  }

  VoidCallback onPreloadZone;
  double _refreshIndicatorExtent;

  set refreshIndicatorLayoutExtent(double value) {
    assert(value >= 0.0);
    if (value == _refreshIndicatorExtent) {
      return;
    }
    _refreshIndicatorExtent = value;
    markNeedsLayout();
  }

  bool _hasLayoutExtent;

  set hasLayoutExtent(bool value) {
    if (value == _hasLayoutExtent) {
      return;
    }
    _hasLayoutExtent = value;
    markNeedsLayout();
  }

  bool _autoRefresh;

  set autoRefresh(bool v) {
    if (v == _autoRefresh) {
      return;
    }
    _autoRefresh = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    // empty viewport will not show sliver, you should load data from refresher or a initializer
    bool invisible = constraints.precedingScrollExtent <= 0;
    //when user pull down, remainingPaintExtent can be this small, but sliver actually not visiable, maybe viewport`s bug
    invisible |= (constraints.remainingPaintExtent < 0.000000001);
    // this sliver not visible
    if (invisible && !_autoRefresh) {
      // not paint indicator
      geometry = SliverGeometry.zero;
      child!.layout(
        constraints.asBoxConstraints(maxExtent: 0),
        parentUsesSize: true,
      );
      return;
    } else if (invisible && _autoRefresh) {
      // not paint indicator
      geometry = SliverGeometry.zero;
      child!.layout(
        constraints.asBoxConstraints(maxExtent: 0),
        parentUsesSize: true,
      );

      // trigger preload
      if (parent is RenderViewport) {
        RenderViewport port = parent as RenderViewport;
        // slivers extent not scroll in viewport
        final remainScrollExtent = constraints.precedingScrollExtent -
            port.offset.pixels -
            constraints.viewportMainAxisExtent;

        if (remainScrollExtent <
                (port.cacheExtent ??
                    RenderAbstractViewport.defaultCacheExtent) &&
            remainScrollExtent > 0) {
          onPreloadZone();
        }
      }
      return;
    }

    double scrollOffsetOfAllSlivers = (parent as RenderViewport).offset.pixels;

    // precede slivers not fill viewport
    if (constraints.precedingScrollExtent <
        constraints.viewportMainAxisExtent) {
      if (_autoRefresh && scrollOffsetOfAllSlivers >= 0) {
        final scrollExtent = (constraints.viewportMainAxisExtent -
            constraints.precedingScrollExtent);
        geometry = SliverGeometry(
          scrollExtent: scrollExtent,
          paintExtent: scrollExtent,
          maxPaintExtent: scrollExtent,
        );
        child!.layout(
          constraints.asBoxConstraints(
              minExtent: 0,
              maxExtent: min(
                constraints.remainingPaintExtent,
                geometry!.maxPaintExtent,
              )),
          parentUsesSize: true,
        );
        return;
      }
      // user pulling down
      if (scrollOffsetOfAllSlivers < 0) {
        geometry = SliverGeometry.zero;
        child!.layout(
          constraints.asBoxConstraints(maxExtent: 0),
          parentUsesSize: true,
        );
        return;
      }

      if (_hasLayoutExtent) {
        var paintOrigin =
            constraints.remainingPaintExtent - scrollOffsetOfAllSlivers;
        var fix = paintOrigin +
            _refreshIndicatorExtent -
            constraints.remainingPaintExtent;
        if (fix > 0) {
          paintOrigin -= fix;
        }

        final painExtent = constraints.remainingPaintExtent - paintOrigin;
        geometry = SliverGeometry(
          scrollExtent: 0,
          paintOrigin: paintOrigin,
          paintExtent: painExtent,
          maxPaintExtent: painExtent,
        );
      } else {
        geometry = SliverGeometry(
          scrollExtent: 0,
          paintOrigin:
              constraints.remainingPaintExtent - scrollOffsetOfAllSlivers,
          paintExtent: scrollOffsetOfAllSlivers,
          maxPaintExtent: scrollOffsetOfAllSlivers,
        );
      }
      child!.layout(
        constraints.asBoxConstraints(
            maxExtent: min(
          constraints.remainingPaintExtent,
          geometry!.maxPaintExtent,
        )),
        parentUsesSize: true,
      );
      return;
    }

    //
    child!.layout(
      constraints.asBoxConstraints(maxExtent: constraints.remainingPaintExtent),
      parentUsesSize: true,
    );

    final double layoutExtent =
        (_hasLayoutExtent ? 1.0 : 0.0) * _refreshIndicatorExtent;
    geometry = SliverGeometry(
      scrollExtent: layoutExtent,
      paintExtent:
          min(_refreshIndicatorExtent, constraints.remainingPaintExtent),
      maxPaintExtent: _refreshIndicatorExtent,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child!.size.height > 0) {
      context.paintChild(child!, offset);
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}
}

/// A sliver widget implementing the iOS-style load more content control.
/// work like [CupertinoSliverRefreshControl] and support autoLoad & preload
class LoadMoreController extends StatefulWidget {
  ///  if the [autoLoad] argument be true:
  ///   * [onLoad] will be called when viewport not filled
  ///   * [onLoad] will be called when the sliver reach the cacheExtent of the viewport
  /// other arguments work like those of [CupertinoSliverRefreshControl]
  const LoadMoreController({
    super.key,
    required this.onLoad,
    this.refreshTriggerPullDistance = 76,
    this.refreshIndicatorExtent = 56,
    this.builder = CupertinoSliverRefreshControl.buildRefreshIndicator,
    this.autoLoad = false,
  })  : assert(refreshTriggerPullDistance > 0.0),
        assert(refreshIndicatorExtent >= 0.0),
        assert(
          refreshTriggerPullDistance >= refreshIndicatorExtent,
          'The refresh indicator cannot take more space in its final state '
          'than the amount initially created by overscrolling.',
        );

  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;
  final RefreshControlIndicatorBuilder? builder;
  final Future<void> Function()? onLoad;
  final bool autoLoad;

  @override
  State<LoadMoreController> createState() => _LoadMoreControllerState();
}

class _LoadMoreControllerState extends State<LoadMoreController> {
  static const double _inactiveResetOverscrollFraction = 0.1;
  late RefreshIndicatorMode refreshState;
  Future<void>? refreshTask;
  double latestIndicatorBoxExtent = 0.0;
  bool hasSliverLayoutExtent = false;

  @override
  void initState() {
    super.initState();
    refreshState = RefreshIndicatorMode.inactive;
  }

  double get triggerDistance {
    if (widget.autoLoad) {
      return widget.refreshIndicatorExtent - 1;
    }
    return widget.refreshTriggerPullDistance;
  }

  RefreshIndicatorMode transitionNextState() {
    RefreshIndicatorMode nextState;

    void goToDone() {
      nextState = RefreshIndicatorMode.done;
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        setState(() => hasSliverLayoutExtent = false);
      } else {
        SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
          setState(() => hasSliverLayoutExtent = false);
        }, debugLabel: 'Refresh.goToDone');
      }
    }

    switch (refreshState) {
      case RefreshIndicatorMode.inactive:
        if (latestIndicatorBoxExtent <= 0) {
          return RefreshIndicatorMode.inactive;
        } else {
          nextState = RefreshIndicatorMode.drag;
        }
        continue drag;
      drag:
      case RefreshIndicatorMode.drag:
        if (latestIndicatorBoxExtent == 0) {
          return RefreshIndicatorMode.inactive;
        } else if (latestIndicatorBoxExtent < triggerDistance) {
          return RefreshIndicatorMode.drag;
        } else {
          if (widget.onLoad != null) {
            HapticFeedback.mediumImpact();
            SchedulerBinding.instance.addPostFrameCallback(
                (Duration timestamp) {
              refreshTask = widget.onLoad!()
                ..whenComplete(() {
                  if (mounted) {
                    setState(() => refreshTask = null);
                    refreshState = transitionNextState();
                  }
                });
              setState(() => hasSliverLayoutExtent = true);
            }, debugLabel: 'Refresh.transition');
          }
          return RefreshIndicatorMode.armed;
        }
      case RefreshIndicatorMode.armed:
        if (refreshState == RefreshIndicatorMode.armed && refreshTask == null) {
          goToDone();
          continue done;
        }
        if (latestIndicatorBoxExtent > triggerDistance) {
          return RefreshIndicatorMode.armed;
        } else {
          nextState = RefreshIndicatorMode.refresh;
        }
        continue refresh;
      refresh:
      case RefreshIndicatorMode.refresh:
        if (refreshTask != null) {
          return RefreshIndicatorMode.refresh;
        } else {
          goToDone();
        }
        continue done;
      done:
      case RefreshIndicatorMode.done:
        if (latestIndicatorBoxExtent >
            widget.refreshTriggerPullDistance *
                _inactiveResetOverscrollFraction) {
          return RefreshIndicatorMode.done;
        } else {
          nextState = RefreshIndicatorMode.inactive;
        }
    }

    return nextState;
  }

  @override
  Widget build(BuildContext context) {
    return _LoadMoreSliverWidget(
        refreshIndicatorLayoutExtent: widget.refreshIndicatorExtent,
        hasLayoutExtent: hasSliverLayoutExtent,
        autoRefresh: widget.autoLoad,
        onPreloadZone: () {
          latestIndicatorBoxExtent = triggerDistance;
          refreshState = transitionNextState();
        },
        child: LayoutBuilder(builder: (c, constraints) {
          latestIndicatorBoxExtent = constraints.maxHeight;
          refreshState = transitionNextState();

          if (widget.builder != null && latestIndicatorBoxExtent > 0.0000001) {
            // if refreshState is RefreshIndicatorMode.done and still need build indicator, means viewport not filled
            if (refreshState == RefreshIndicatorMode.done && widget.autoLoad) {
              refreshState = RefreshIndicatorMode.drag;
              refreshState = transitionNextState();
            }
            return widget.builder!(
              context,
              refreshState,
              latestIndicatorBoxExtent,
              widget.refreshTriggerPullDistance,
              widget.refreshIndicatorExtent,
            );
          }
          return Container();
        }));
  }
}
