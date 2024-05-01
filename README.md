<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

a `CupertinoSliverRefreshControl` like load more sliver 

## Features

- support autoload and preload(only if cacheExtent > 0)
- similar to `CupertinoSliverRefreshControl` useage

## Getting started



## Usage

```dart
late ValueNotifier<int> _count;
Future<void> loadMore() async {
  await Future.delayed(const Duration(seconds: 1));
  _count.value = _count.value + 8;
}
CustomScrollView(slivers: [
  ValueListenableBuilder(
      valueListenable: _count,
      builder: (c, value, _) {
        return SliverList(
            ...
        ]));
      }),
  LoadMoreController(onLoad: loadMore),
]);
```

## Additional information
```dart
CustomScrollView(
  cacheExtent: 500,
  slivers: [
    LoadMoreController(
      onLoad: loadMore,
      autoLoad: true,
    )
  ],
);
```
if the `autoLoad` argument be true:
* `onLoad` will be called when viewport not filled
* `onLoad` will be called when the `LoadMoreController`
 reach the `cacheExtent` of the viewport, `cacheExtent` can be modified to control the preloading timing
