library load_more;

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class _LoadMoreWidget extends SingleChildRenderObjectWidget {
  const _LoadMoreWidget({
    this.refreshIndicatorLayoutExtent = 0.0,
    this.hasLayoutExtent = false,
    this.autoRefresh = false,
    super.child,
  }) : assert(refreshIndicatorLayoutExtent >= 0.0);

  final double refreshIndicatorLayoutExtent;

  final bool hasLayoutExtent;

  final bool autoRefresh;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _LoadMoreSliver(
      refreshIndicatorExtent: refreshIndicatorLayoutExtent,
      hasLayoutExtent: hasLayoutExtent,
      autoRefresh: autoRefresh,
    );
  }

  @override
  void updateRenderObject(BuildContext context,
      covariant _LoadMoreSliver renderObject) {
    renderObject
      ..refreshIndicatorLayoutExtent = refreshIndicatorLayoutExtent
      ..hasLayoutExtent = hasLayoutExtent
      ..autoRefresh = autoRefresh;
  }
}

class _LoadMoreSliver extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox> {
  _LoadMoreSliver({
    required double refreshIndicatorExtent,
    required bool hasLayoutExtent,
    required bool autoRefresh,
    RenderBox? child,
  })
      : assert(refreshIndicatorExtent >= 0.0),
        _refreshIndicatorExtent = refreshIndicatorExtent,
        _hasLayoutExtent = hasLayoutExtent,
        _autoRefresh = autoRefresh {
    this.child = child;
  }

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
    // empty viewport or this sliver not visible
    if (constraints.remainingPaintExtent <=
        0.000000001 // sometimes remainingPaintExtent can be this small, but sliver actually not visiable, maybe viewport`s bug
        ||
        constraints.precedingScrollExtent <= 0) {
      geometry = SliverGeometry.zero;
      child!.layout(
        constraints.asBoxConstraints(maxExtent: 0),
        parentUsesSize: true,
      );
      return;
    }

    double scrolledExtent = constraints.precedingScrollExtent +
        constraints.remainingPaintExtent -
        constraints.viewportMainAxisExtent;

    // precede slivers not fill viewport
    if (constraints.precedingScrollExtent <
        constraints.viewportMainAxisExtent) {
      if (_autoRefresh && scrolledExtent >= 0) {
        final scrollExtent = (constraints.viewportMainAxisExtent -
            constraints.precedingScrollExtent);
        geometry = SliverGeometry(
          scrollExtent: scrollExtent,
          // paintOrigin: 0, //max(0, scrollExtent - _refreshIndicatorExtent),
          paintExtent: scrollExtent, //_refreshIndicatorExtent,
          maxPaintExtent: scrollExtent, //_refreshIndicatorExtent,
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
      // offset of first sliver

      // user pulling down
      if (scrolledExtent < 0) {
        geometry = SliverGeometry.zero;
        child!.layout(
          constraints.asBoxConstraints(maxExtent: 0),
          parentUsesSize: true,
        );
        return;
      }
      final remainViewPortExtent = constraints.viewportMainAxisExtent -
          constraints.precedingScrollExtent;
      if (_hasLayoutExtent) {
        var paintOrigin = constraints.remainingPaintExtent - scrolledExtent;
        var fix = paintOrigin + _refreshIndicatorExtent -
            constraints.remainingPaintExtent;
        if (fix > 0) {
          paintOrigin -= fix;
        }

        geometry = SliverGeometry(
          scrollExtent: 0,
          paintOrigin: paintOrigin,
          paintExtent: _refreshIndicatorExtent,
          maxPaintExtent: _refreshIndicatorExtent,
        );
      } else {
        geometry = SliverGeometry(
          scrollExtent: 0,
          paintOrigin: constraints.remainingPaintExtent -
              scrolledExtent,
          paintExtent: scrolledExtent,
          maxPaintExtent: scrolledExtent,
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

class MyLoadMoreController extends StatefulWidget {
  const MyLoadMoreController({
    super.key,
    this.refreshTriggerPullDistance = 60,
    this.refreshIndicatorExtent = 40,
    this.builder,
    this.onRefresh,
    this.autoRefresh = false,
  });

  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;
  final RefreshControlIndicatorBuilder? builder;
  final RefreshCallback? onRefresh;
  final bool autoRefresh;

  @override
  State<MyLoadMoreController> createState() => _MyLoadMoreControllerState();
}

class _MyLoadMoreControllerState extends State<MyLoadMoreController> {
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

    double triggerDistance = widget.refreshTriggerPullDistance;
    if (widget.autoRefresh) {
      triggerDistance = widget.refreshIndicatorExtent - 1;
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
          if (widget.onRefresh != null) {
            HapticFeedback.mediumImpact();
            SchedulerBinding.instance.addPostFrameCallback(
                    (Duration timestamp) {
                  refreshTask = widget.onRefresh!()
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
    return _LoadMoreWidget(
        refreshIndicatorLayoutExtent: widget.refreshIndicatorExtent,
        hasLayoutExtent: hasSliverLayoutExtent,
        autoRefresh: widget.autoRefresh,
        child: LayoutBuilder(builder: (c, constraints) {
          latestIndicatorBoxExtent = constraints.maxHeight;
          refreshState = transitionNextState();
          if (widget.builder != null && latestIndicatorBoxExtent > 0) {
            if (refreshState == RefreshIndicatorMode.done &&
                widget.autoRefresh) {
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

void pp(Object? a, [
  Object? b,
  Object? c,
  Object? d,
  Object? e,
  Object? f,
  Object? g,
  Object? h,
  Object? i,
  Object? j,
  Object? k,
  Object? l,
  Object? m,
  Object? n,
  Object? o,
  Object? p,
]) {
  final time = DateTime.now();
  String str = '$time-pp:  $a';
  add(Object? p) {
    if (p != null) str += ',  $p';
  }

  add(b);
  add(c);
  add(d);
  add(e);
  add(f);
  add(g);
  add(h);
  add(i);
  add(j);
  add(k);
  add(l);
  add(m);
  add(n);
  add(o);

  if (kDebugMode) {
    print(str);
  }
}
