import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  
  const ResponsiveLayout({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ResponsiveColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  
  const ResponsiveColumn({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      ),
    );
  }
}

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  
  const ResponsiveCard({
    Key? key,
    required this.child,
    this.margin,
    this.padding,
    this.elevation,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? EdgeInsets.all(8),
      elevation: elevation ?? 2,
      child: Container(
        width: double.infinity,
        padding: padding ?? EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class OverflowSafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  
  const OverflowSafeText(
    this.text, {
    Key? key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          child: Text(
            text,
            style: style,
            maxLines: maxLines ?? 10,
            overflow: overflow ?? TextOverflow.ellipsis,
            textAlign: textAlign,
          ),
        );
      },
    );
  }
}