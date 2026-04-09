import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../html_pdf_widgets.dart';
import '../utils/app_assets.dart';

class _QuoteContainerContext extends FlexContext {
  /// Post-layout output: the spanning child's context saved AFTER layout.
  /// Used by restoreContext to derive the input for the next page.
  WidgetContext? spanningChildContext;

  /// Pre-layout input: the context to pass to child.restoreContext() at
  /// the START of layout.  Set by [QuoteContainer.restoreContext] and
  /// preserved in clone()/apply() so postProcess can replay the correct
  /// child state for each page segment.
  WidgetContext? spanningChildInputContext;

  bool isFirstSegment;
  bool contentRendered;

  _QuoteContainerContext({
    int firstChild = 0,
    int lastChild = 0,
    this.spanningChildContext,
    this.spanningChildInputContext,
    this.isFirstSegment = true,
    this.contentRendered = false,
  }) {
    this.firstChild = firstChild;
    this.lastChild = lastChild;
  }

  @override
  WidgetContext clone() {
    final ctx = _QuoteContainerContext(
      firstChild: firstChild,
      lastChild: lastChild,
      spanningChildContext: spanningChildContext?.clone(),
      spanningChildInputContext: spanningChildInputContext?.clone(),
      isFirstSegment: isFirstSegment,
      contentRendered: contentRendered,
    );
    return ctx;
  }

  @override
  void apply(covariant FlexContext other) {
    if (other is _QuoteContainerContext) {
      firstChild = other.firstChild;
      lastChild = other.lastChild;
      spanningChildContext = other.spanningChildContext?.clone();
      spanningChildInputContext = other.spanningChildInputContext?.clone();
      isFirstSegment = other.isFirstSegment;
      contentRendered = other.contentRendered;
    }
    // If other is a plain FlexContext (pdf package leak), don't copy
    // firstChild/lastChild — it would corrupt our progress tracking.
  }
}

class QuoteContainer extends Widget with SpanningWidget {
  QuoteContainer({
    required this.children,
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

  final List<Widget> children;
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
  /// Set during layout(), survives applyContext() in postProcess paint pass
  /// because applyContext only modifies _myContext fields, not this field.
  bool _isLastSegment = true;
  final _QuoteContainerContext _myContext = _QuoteContainerContext();

  /// Stores the initial (pre-layout) context of each spanning child,
  /// keyed by child index.  Used by postProcess to reset a child to
  /// its pristine state when no spanningChildInputContext is available.
  final Map<int, WidgetContext> _initialChildContexts = {};

  bool get _isFirstSegment => _myContext.isFirstSegment;

  double get _iconAreaWidth => iconSvg != null ? iconSize + iconGap : 0;
  double get _contentLeft => barWidth + padding.left + _iconAreaWidth;

  @override
  bool get canSpan => true;

  @override
  bool get hasMoreWidgets =>
      _myContext.lastChild < children.length ||
      _myContext.spanningChildContext != null ||
      !_myContext.contentRendered; // keeps spanning alive after 0-height segment

  @override
  void layout(
    Context context,
    BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    final topPad = _isFirstSegment ? padding.top : 0.0;
    final contentMaxWidth = math.max(0.0, constraints.maxWidth - _contentLeft - padding.right);
    var remainingHeight = math.max(0.0, constraints.maxHeight - topPad - padding.bottom);

    var contentHeight = 0.0;
    // If firstChild is out of range (context from a different widget), full reset
    if (_myContext.firstChild > children.length) {
      _resetContext();
    }
    int idx = _myContext.firstChild;
    // spanningChildInputContext holds the pre-layout context for the
    // spanning child on continuation pages.  It is set by restoreContext()
    // and preserved in clone()/apply() so postProcess can replay it.
    // We read it here but do NOT clear it — the clone taken by MultiPage
    // after layout must still contain it.
    final savedSpanningContext = _myContext.spanningChildInputContext;
    _myContext.spanningChildContext = null;

    while (idx < children.length && remainingHeight > 0) {
      final child = children[idx];

      if (child is SpanningWidget && child.canSpan) {
        if (savedSpanningContext != null && idx == _myContext.firstChild) {
          // Restore spanning child context from previous page
          try {
            child.restoreContext(savedSpanningContext);
          } catch (_) {}
        } else if (_initialChildContexts.containsKey(idx)) {
          // Reset child to pristine state — needed for postProcess replay
          // where a prior generate/postProcess iteration left dirty state.
          try {
            child.applyContext(_initialChildContexts[idx]!);
          } catch (_) {}
        }
      }

      // Capture the child's initial (pre-layout) context on first encounter.
      // This allows postProcess to reset the child to its pristine state.
      if (child is SpanningWidget && child.canSpan && !_initialChildContexts.containsKey(idx)) {
        _initialChildContexts[idx] = child.cloneContext();
      }

      // Layout child WITH maxHeight so spannable children know their limit
      final childMaxHeight = remainingHeight;
      child.layout(
        context,
        BoxConstraints(maxWidth: contentMaxWidth, maxHeight: childMaxHeight),
      );

      final childH = child.box!.height;

      // If this child doesn't fit and we already have content, stop before it.
      // If it's the first child, include it anyway (can't skip or nothing renders).
      if (childH > childMaxHeight && contentHeight > 0) {
        break;
      }

      contentHeight += childH;
      remainingHeight -= childH;
      idx++;

      // If child filled all the space it was given, it likely has more to render
      if (child is SpanningWidget && child.canSpan && childH >= childMaxHeight - 0.5) {
        _myContext.spanningChildContext = child.saveContext();
        break;
      }
    }

    _myContext.lastChild = idx;
    _myContext.contentRendered = contentHeight > 0;

    // If nothing fit, or too little to be meaningful (less than icon height),
    // render zero-height — let MultiPage push to next page.
    final hasMore = idx < children.length || _myContext.spanningChildContext != null;
    if (!_myContext.contentRendered || (contentHeight < iconSize && hasMore)) {
      _myContext.contentRendered = false;
      _myContext.lastChild = _myContext.firstChild;
      _myContext.spanningChildContext = null;
      _myContext.spanningChildInputContext = null;
      box = PdfRect(0, 0, constraints.maxWidth, 0);
      _icon = null;
      _isLastSegment = false;
      return;
    }

    // Position children top-to-bottom in PDF coordinates (y from bottom)
    var y = contentHeight;
    for (int i = _myContext.firstChild; i < _myContext.lastChild; i++) {
      final child = children[i];
      y -= child.box!.height;
      child.box = PdfRect(0, y, child.box!.width, child.box!.height);
    }

    box = PdfRect(
      0, 0,
      constraints.maxWidth,
      contentHeight + topPad + padding.bottom,
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

    // Content children
    final contentMat = Matrix4.identity();
    contentMat.translateByDouble(_contentLeft, padding.bottom, 0, 1);
    context.canvas
      ..saveContext()
      ..setTransform(contentMat);
    for (int i = _myContext.firstChild; i < _myContext.lastChild; i++) {
      children[i].paint(context);
    }
    context.canvas.restoreContext();

    context.canvas.restoreContext();
  }

  @override
  WidgetContext saveContext() {
    return _myContext;
  }

  void _resetContext() {
    _myContext.firstChild = 0;
    _myContext.lastChild = 0;
    _myContext.spanningChildContext = null;
    _myContext.spanningChildInputContext = null;
    _myContext.isFirstSegment = true;
    _myContext.contentRendered = false;
  }

  @override
  void restoreContext(FlexContext context) {
    _myContext.apply(context);
    if (context is _QuoteContainerContext && _myContext.lastChild <= children.length) {
      _myContext.firstChild = _myContext.lastChild;
      if (_myContext.spanningChildContext != null) {
        _myContext.firstChild = math.max(0, _myContext.firstChild - 1);
        // Derive the INPUT context for the next layout pass:
        // clone the post-layout output so the child will be restored
        // to start from where the previous page left off.
        _myContext.spanningChildInputContext =
            _myContext.spanningChildContext!.clone();
      }
      if (_myContext.contentRendered) {
        _myContext.isFirstSegment = false;
      }
    } else {
      _resetContext();
    }
  }
}

Widget buildQuoteWidget(List<Widget> children, {required HtmlTagStyle customStyles}) {
  final quoteColor = customStyles.quoteBarColor ?? PdfColors.grey600;
  return Padding(
    padding: EdgeInsets.symmetric(vertical: customStyles.blockSpacing),
    child: QuoteContainer(
      barColor: quoteColor,
      borderRadius: customStyles.borderRadius,
      iconSvg: AppAssets.quoteIcon,
      children: children,
    ),
  );
}
