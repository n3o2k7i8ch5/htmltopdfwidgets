import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../html_pdf_widgets.dart';

/// Builds a list item widget: if the content is spannable, wraps in
/// [ListItemContainer] (enabling page breaks within the item).
/// Otherwise falls back to a simple [Row] layout.
Widget buildListItem({
  required Widget child,
  required Widget indicator,
  required double indicatorWidth,
}) {
  // Unwrap single-child Column to get the spannable RichText directly.
  Widget effective = child;
  if (child is MultiChildWidget) {
    final children = child.children;
    if (children.length == 1) effective = children.first;
  }

  if (effective is SpanningWidget && effective.canSpan) {
    return ListItemContainer(
      content: effective,
      indicator: indicator,
      indicatorWidth: indicatorWidth,
    );
  }

  return Container(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        Flexible(child: child),
      ],
    ),
  );
}

/// Spannable wrapper for list items: indicator on the left (first segment only),
/// content on the right, with spanning delegated to the content widget.
/// Extends FlexContext for compatibility with the pdf package's context leak.
class ListItemContainer extends Widget with SpanningWidget {
  ListItemContainer({
    required this.content,
    required this.indicator,
    required this.indicatorWidth,
  });

  final SpanningWidget content;
  final Widget indicator;
  final double indicatorWidth;

  bool _isFirstSegment = true;
  bool _contentRendered = false;
  WidgetContext? _initialContentContext;

  @override
  bool get canSpan => content.canSpan;

  @override
  bool get hasMoreWidgets => content.hasMoreWidgets;

  @override
  void layout(
    Context context,
    BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    final contentMaxWidth = math.max(0.0, constraints.maxWidth - indicatorWidth);
    final contentMaxHeight = math.max(0.0, constraints.maxHeight);

    // Capture initial content context on first encounter (for postProcess reset)
    if (_initialContentContext == null && content.canSpan) {
      _initialContentContext = content.cloneContext();
    }

    content.layout(
      context,
      BoxConstraints(maxWidth: contentMaxWidth, maxHeight: contentMaxHeight),
      parentUsesSize: parentUsesSize,
    );

    _contentRendered = content.box!.height > 0;

    if (!_contentRendered) {
      box = PdfRect(0, 0, constraints.maxWidth, 0);
      return;
    }

    if (_isFirstSegment) {
      indicator.layout(context, BoxConstraints(
        maxWidth: indicatorWidth,
        maxHeight: constraints.maxHeight,
      ));
    }

    box = PdfRect(0, 0, constraints.maxWidth, content.box!.height);
  }

  @override
  void paint(Context context) {
    super.paint(context);

    final mat = Matrix4.identity();
    mat.translateByDouble(box!.left, box!.bottom, 0, 1);
    context.canvas
      ..saveContext()
      ..setTransform(mat);

    if (_isFirstSegment && _contentRendered) {
      final indicatorMat = Matrix4.identity();
      indicatorMat.translateByDouble(
        0,
        box!.height - indicator.box!.height,
        0, 1,
      );
      context.canvas
        ..saveContext()
        ..setTransform(indicatorMat);
      indicator.paint(context);
      context.canvas.restoreContext();
    }

    final contentMat = Matrix4.identity();
    contentMat.translateByDouble(indicatorWidth, 0, 0, 1);
    context.canvas
      ..saveContext()
      ..setTransform(contentMat);
    content.paint(context);
    context.canvas.restoreContext();

    context.canvas.restoreContext();
  }

  @override
  WidgetContext saveContext() {
    return content.canSpan ? content.saveContext() : FlexContext();
  }

  @override
  void restoreContext(WidgetContext context) {
    _isFirstSegment = false;
    if (content.canSpan) {
      try {
        content.restoreContext(context);
      } catch (_) {
        // Foreign context type — reset content to initial state
        if (_initialContentContext != null) {
          try { content.applyContext(_initialContentContext!); } catch (_) {}
        }
        _isFirstSegment = true;
      }
    }
  }
}
