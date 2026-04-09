import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../html_pdf_widgets.dart';
import '../utils/app_assets.dart';

class _QuoteContainerContext extends WidgetContext {
  WidgetContext? childContext;
  bool isFirstSegment;

  _QuoteContainerContext({this.childContext, this.isFirstSegment = true});

  @override
  WidgetContext clone() => _QuoteContainerContext(
    childContext: childContext?.clone(),
    isFirstSegment: isFirstSegment,
  );

  @override
  void apply(covariant _QuoteContainerContext other) {
    isFirstSegment = other.isFirstSegment;
    if (childContext != null && other.childContext != null) {
      childContext!.apply(other.childContext!);
    } else {
      childContext = other.childContext?.clone();
    }
  }
}

class QuoteContainer extends Widget with SpanningWidget {
  QuoteContainer({
    required this.content,
    required this.barColor,
    this.backgroundColor = PdfColors.grey100,
    this.barWidth = 3.0,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.fromLTRB(6, 8, 12, 8),
    this.iconSize = 16.0,
    this.iconGap = 6.0,
    this.iconTopOffset = 0.0,
    this.iconSvg,
  });

  final SpanningWidget content;
  final PdfColor barColor;
  final PdfColor backgroundColor;
  final double barWidth;
  final double borderRadius;
  final EdgeInsets padding;
  final double iconSize;
  final double iconGap;
  final double iconTopOffset;
  final String? iconSvg;

  Widget? _icon;
  bool _isLastSegment = true;
  final _QuoteContainerContext _myContext = _QuoteContainerContext();

  bool get _isFirstSegment => _myContext.isFirstSegment;

  double get _iconAreaWidth => iconSvg != null ? iconSize + iconGap : 0;
  double get _contentLeft => barWidth + padding.left + _iconAreaWidth;

  @override
  bool get canSpan => content.canSpan;

  @override
  bool get hasMoreWidgets {
    final ctx = content.saveContext();
    if (ctx is FlexContext && content is MultiChildWidget) {
      return ctx.lastChild < (content as MultiChildWidget).children.length;
    }
    return content.hasMoreWidgets;
  }

  @override
  void layout(
    Context context,
    BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    final topPad = _isFirstSegment ? padding.top : 0.0;
    final contentMaxWidth = math.max(0.0, constraints.maxWidth - _contentLeft - padding.right);
    final contentMaxHeight = math.max(0.0, constraints.maxHeight - topPad - padding.bottom);

    content.layout(
      context,
      BoxConstraints(maxWidth: contentMaxWidth, maxHeight: contentMaxHeight),
      parentUsesSize: parentUsesSize,
    );

    box = PdfRect(
      0, 0,
      constraints.maxWidth,
      content.box!.height + topPad + padding.bottom,
    );

    if (iconSvg != null && _isFirstSegment) {
      _icon = SvgImage(
        svg: iconSvg!,
        width: iconSize,
        height: iconSize,
        colorFilter: barColor,
      );
      _icon!.layout(context, BoxConstraints(
        minWidth: iconSize, maxWidth: iconSize,
        minHeight: iconSize, maxHeight: iconSize,
      ));
    } else {
      _icon = null;
    }

    _isLastSegment = !hasMoreWidgets;
  }

  static const double _kappa = 0.5522847498;

  void _drawSelectiveRRect(
    PdfGraphics canvas,
    double x, double y, double w, double h, double r, {
    required bool roundTop,
    required bool roundBottom,
  }) {
    if (roundBottom) {
      canvas.moveTo(x, y + r);
      canvas.curveTo(x, y + r - _kappa * r, x + r - _kappa * r, y, x + r, y);
    } else {
      canvas.moveTo(x, y);
    }

    if (roundBottom) {
      canvas.lineTo(x + w - r, y);
      canvas.curveTo(x + w - r + _kappa * r, y, x + w, y + r - _kappa * r, x + w, y + r);
    } else {
      canvas.lineTo(x + w, y);
    }

    if (roundTop) {
      canvas.lineTo(x + w, y + h - r);
      canvas.curveTo(x + w, y + h - r + _kappa * r, x + w - r + _kappa * r, y + h, x + w - r, y + h);
    } else {
      canvas.lineTo(x + w, y + h);
    }

    if (roundTop) {
      canvas.lineTo(x + r, y + h);
      canvas.curveTo(x + r - _kappa * r, y + h, x, y + h - r + _kappa * r, x, y + h - r);
    } else {
      canvas.lineTo(x, y + h);
    }
  }

  @override
  void paint(Context context) {
    super.paint(context);

    final topPad = _isFirstSegment ? padding.top : 0.0;

    final mat = Matrix4.identity();
    mat.translateByDouble(box!.left, box!.bottom, 0, 1);
    context.canvas
      ..saveContext()
      ..setTransform(mat);

    // Clipped background + border with rounded corners
    context.canvas.saveContext();
    _drawSelectiveRRect(
      context.canvas, 0, 0, box!.width, box!.height, borderRadius,
      roundTop: _isFirstSegment,
      roundBottom: _isLastSegment,
    );
    context.canvas.clipPath();

    context.canvas
      ..setFillColor(backgroundColor)
      ..drawRect(0, 0, box!.width, box!.height)
      ..fillPath();

    context.canvas
      ..setFillColor(barColor)
      ..drawRect(0, 0, barWidth, box!.height)
      ..fillPath();

    context.canvas.restoreContext();

    // Icon (first segment only)
    if (_icon != null) {
      final iconMat = Matrix4.identity();
      iconMat.translateByDouble(
        barWidth + padding.left,
        box!.height - topPad - iconTopOffset - iconSize,
        0, 1,
      );
      context.canvas
        ..saveContext()
        ..setTransform(iconMat);
      _icon!.paint(context);
      context.canvas.restoreContext();
    }

    // Content
    final contentMat = Matrix4.identity();
    contentMat.translateByDouble(_contentLeft, padding.bottom, 0, 1);
    context.canvas
      ..saveContext()
      ..setTransform(contentMat);
    content.paint(context);
    context.canvas.restoreContext();

    context.canvas.restoreContext();
  }

  @override
  WidgetContext saveContext() {
    _myContext.childContext = content.canSpan ? content.saveContext() : null;
    return _myContext;
  }

  @override
  void restoreContext(covariant _QuoteContainerContext context) {
    _myContext.apply(context);
    _myContext.isFirstSegment = false;
    if (content.canSpan && _myContext.childContext != null) {
      content.restoreContext(_myContext.childContext!);
    }
  }
}

Widget buildQuoteWidget(Widget child, {required HtmlTagStyle customStyles}) {
  final quoteColor = customStyles.quoteBarColor ?? PdfColors.grey600;
  return Padding(
    padding: EdgeInsets.symmetric(vertical: customStyles.blockSpacing),
    child: QuoteContainer(
      barColor: quoteColor,
      borderRadius: customStyles.borderRadius,
      iconSvg: AppAssets.quoteIcon,
      content: child as SpanningWidget,
    ),
  );
}
