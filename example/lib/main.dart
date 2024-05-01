import 'package:example/classic.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
    //   Navigator.of(context)
    //       .push(CupertinoPageRoute(builder: (_) => const ClassicPage()));
    // });
    return Scaffold(
        appBar: const CupertinoNavigationBar(middle: Text('home')),
        body: ListView(
          children: [const ClassicPage()]
              .map((e) => ListTile(
                    title: Text(e.toString()),
                    onTap: () => Navigator.of(context)
                        .push(CupertinoPageRoute(builder: (_) => e)),
                  ))
              .toList(),
        ));
  }
}
