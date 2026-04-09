import '../../html_pdf_widgets.dart';
import 'list_item_container.dart';

class NumberListItemWidget extends StatelessWidget {
  final Widget child;
  final int index;
  final HtmlTagStyle customStyles;
  final bool withIndicator;
  final TextStyle baseTextStyle;

  NumberListItemWidget({
    required this.child,
    required this.index,
    required this.customStyles,
    this.withIndicator = true,
    required this.baseTextStyle
  });

  @override
  Widget build(Context context) {
    final indicator = withIndicator
        ? _NumberListIndicator(style: customStyles, index: index, baseTextStyle: baseTextStyle)
        : SizedBox(width: customStyles.listItemIndicatorWidth);

    // Unwrap single-child Column to get the spannable RichText directly
    Widget effectiveChild = child;
    if (child is MultiChildWidget && (child as MultiChildWidget).children.length == 1) {
      effectiveChild = (child as MultiChildWidget).children.first;
    }

    if (effectiveChild is SpanningWidget && effectiveChild.canSpan) {
      return ListItemContainer(
        content: effectiveChild,
        indicator: indicator,
        indicatorWidth: customStyles.listItemIndicatorWidth,
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
}

class _NumberListIndicator extends StatelessWidget {
  final HtmlTagStyle style;
  final int index;
  final TextStyle baseTextStyle;

  _NumberListIndicator({required this.style, required this.index, required this.baseTextStyle});

  @override
  Widget build(Context context) {
    return SizedBox(
      width: style.listItemIndicatorWidth,
      height: style.bulletListIconSize,
      child: Padding(
        padding: style.listItemIndicatorPadding,
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$index.',
            style: style.listIndexStyle??baseTextStyle,
          )
        ),
      ),
    );
  }
}
