import 'package:example/auto_load.dart';
import 'package:example/classic.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
            return ListView(
              children: const [Classic(), AutoLoad()]
                  .map((e) => ListTile(
                        title: Text(e.toString()),
                        onTap: () => Navigator.of(context)
                            .push(CupertinoPageRoute(builder: (_) => e)),
                      ))
                  .toList(),
            );
          })),
    );
  }
}
