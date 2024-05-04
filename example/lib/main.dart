import 'package:example/auto_load.dart';
import 'package:example/classic.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:example/tool/general.dart' as general;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
          appBar: const CupertinoNavigationBar(middle: Text('home')),
          body: Builder(builder: (context) {
            if (!general.isMobile()) {
              return const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('open this example using a browser on a mobile device.'),
                  Text('or switch to mobile mode in development tool.'),
                ]),
              );
            }
            return ListView(
              children: const [
                [Classic(), 'default classic'],
                [AutoLoad(), 'autoload and preload']
              ]
                  .map((e) => ListTile(
                        title: Text(e[1] as String),
                        onTap: () => Navigator.of(context).push(
                            CupertinoPageRoute(builder: (_) => e[0] as Widget)),
                      ))
                  .toList(),
            );
          })),
    );
  }
}
