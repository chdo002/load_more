import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:load_more/load_more.dart';

class ClassicPage extends StatefulWidget {
  const ClassicPage({super.key});

  @override
  State<ClassicPage> createState() => _ClassicPageState();
}

class _ClassicPageState extends State<ClassicPage> {
  late ValueNotifier<int> _count;
  static const int initialCount = 4;

  @override
  void initState() {
    _count = ValueNotifier(initialCount);
    super.initState();
  }

  Future<void> refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    _count.value = initialCount;
  }

  Future<void> loadMore() async {
    await Future.delayed(const Duration(seconds: 1));
    _count.value = _count.value + 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CupertinoNavigationBar(middle: Text('classic')),
        body: CustomScrollView(slivers: [
          CupertinoSliverRefreshControl(onRefresh: refresh),
          ValueListenableBuilder(
              valueListenable: _count,
              builder: (c, value, _) {
                return SliverList(
                    delegate: SliverChildListDelegate([
                  ...List.generate(value, (index) => '$index')
                      .map((e) => Container(
                            height: 40,
                            color: Colors.blue,
                            child: Text(e),
                          ))
                ]));
              }),
          MyLoadMoreController(
              onRefresh: loadMore,
              autoRefresh: false,
              builder: (context, refreshState, pulledExtent,
                  refreshTriggerPullDistance, refreshIndicatorExtent) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                      height: 40,
                      color: Colors.deepPurpleAccent,
                      child: const CupertinoActivityIndicator(radius: 20)),
                );
              })
        ]));
  }
}
