import 'package:flutter/material.dart';

/// A comfortable measure for long-form text. Wider than this and lines get
/// tiring to read on a desktop window.
const double kReadableMaxWidth = 760;

/// Caps [child] at [kReadableMaxWidth] and centres it, leaving narrow screens
/// untouched.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kReadableMaxWidth),
        child: child,
      ),
    );
  }
}
