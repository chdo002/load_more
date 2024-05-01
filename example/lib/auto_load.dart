import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:load_more/load_more.dart';

class AutoLoad extends StatefulWidget {
  const AutoLoad({super.key});

  @override
  State<AutoLoad> createState() => _AutoLoadState();
}

class _AutoLoadState extends State<AutoLoad> {
  late ValueNotifier<int> _count;
  late ValueNotifier<bool> _hasMore;
  static const int initialCount = 4;

  @override
  void initState() {
    _count = ValueNotifier(initialCount);
    _hasMore = ValueNotifier(true);
    super.initState();
  }

  Future<void> refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    _count.value = initialCount;
    _hasMore.value = true;
  }

  Future<void> loadMore() async {
    await Future.delayed(const Duration(seconds: 1));
    _count.value = _count.value + 8;
    _hasMore.value = _count.value < 50;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CupertinoNavigationBar(middle: Text('auto load')),
        floatingActionButton: ValueListenableBuilder(
            valueListenable: _count,
            builder: (c, value, _) {
              return Text('childCount:$value');
            }),
        body: CustomScrollView(cacheExtent: 500, slivers: [
          CupertinoSliverRefreshControl(onRefresh: refresh),
          ValueListenableBuilder(
              valueListenable: _count,
              builder: (c, value, _) {
                return SliverList(
                    delegate: SliverChildListDelegate([
                  ...List.generate(value, (index) => '$index').map((e) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(38.0),
                          child: Text(e),
                        ),
                      ))
                ]));
              }),
          ValueListenableBuilder(
              valueListenable: _hasMore,
              builder: (c, value, _) {
                if (!value) {
                  return const SliverToBoxAdapter(child: SizedBox());
                }
                return LoadMoreController(
                  onLoad: loadMore,
                  autoLoad: true,
                );
              }),
        ]));
  }
}
