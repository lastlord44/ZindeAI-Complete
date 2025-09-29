import 'package:flutter/material.dart';

/// Ana ekranlarda kullanılacak responsive wrapper
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final bool useScrollView;
  final EdgeInsets? padding;

  const ResponsiveLayout({
    Key? key,
    required this.child,
    this.useScrollView = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    Widget content = child;

    // Padding ekle
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    // ScrollView ekle
    if (useScrollView) {
      content = SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                screenHeight - keyboardHeight - 100, // AppBar için alan bırak
          ),
          child: content,
        ),
      );
    }

    return SafeArea(
      child: content,
    );
  }
}
