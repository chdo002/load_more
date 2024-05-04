import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:load_more/cupertino_load_more.dart';

class ClassicHori extends StatefulWidget {
  const ClassicHori({super.key});

  @override
  State<ClassicHori> createState() => _ClassicState();
}

class _ClassicState extends State<ClassicHori> {
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
    _count.value = _count.value + 8;
  }

  @override
  Widget build(BuildContext context) {
    var customScrollView = CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        slivers: [
          ValueListenableBuilder(
              valueListenable: _count,
              builder: (c, value, _) {
                return SliverList(
                    delegate: SliverChildListDelegate([
                      ...List.generate(value, (index) => '$index').map((e) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(e),
                        ),
                      ))
                    ]));
              }),
          LoadMoreController(onLoad: loadMore),
        ]);
    return Scaffold(
      appBar: const CupertinoNavigationBar(middle: Text('classic')),
      body: customScrollView,
    );
  }
}
