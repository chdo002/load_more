import 'package:example/auto_load.dart';
import 'package:example/auto_load_horizontal.dart';
import 'package:example/classic.dart';
import 'package:example/classic_horizontal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:example/tool/general.dart' as general;
import 'package:flutter/rendering.dart';

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
              return  Center(
                child:

                Column(mainAxisSize: MainAxisSize.min, children: [
                  if (general.isEnglish())
                  const Text('open this example using a browser on a mobile device.'),
                  if (general.isEnglish())
                  const Text('or switch to mobile mode in development tool.'),
                  if (!general.isEnglish())
                    const Text('该demo请在移动设备浏览器中打开，或者在开发工具中切换到移动端模式'),
                  if (!general.isEnglish())
                    const Text('flutter目前不支持PC端的触控信号转为手指拖动信号'),
                ]),
              );
            }
            return ListView(
              children: const [
                [Classic(), 'default classic'],
                [ClassicHori(), 'default classic horizontal'],
                [AutoLoad(), 'autoload and preload'],
                [AutoLoadHori(), 'autoload horizontal'],
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
