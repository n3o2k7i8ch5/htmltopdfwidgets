import '../../html_pdf_widgets.dart';
import 'list_item_container.dart';

class BulletListItemWidget extends StatelessWidget {
  final Widget child;
  final HtmlTagStyle customStyles;
  final bool nestedList;
  final bool withIndicator;

  BulletListItemWidget({
    required this.child,
    required this.customStyles,
    required this.nestedList,
    this.withIndicator = true
  });

  @override
  Widget build(Context context) {
    final indicator = withIndicator
        ? _BulletedListIndicator(style: customStyles, nestedList: nestedList)
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


class _BulletedListIndicator extends StatelessWidget {

  final HtmlTagStyle style;
  final bool nestedList;

  _BulletedListIndicator({required this.style, required this.nestedList});

  @override
  Widget build(Context context) {
    return SizedBox(
      width: style.listItemIndicatorWidth,
      height: style.bulletListIconSize,
      child: Padding(
        padding: style.listItemIndicatorPadding,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: style.bulletListDotSize,
            height: style.bulletListDotSize,
            decoration:
            nestedList?
            BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: style.bulletListIconColor ?? PdfColors.black,
                width: 1.0,
              ),
            ):

            BoxDecoration(
              shape: BoxShape.circle,
              color: style.bulletListIconColor ?? PdfColors.black,
            ),
          ),
        ),
      )
    );
  }
}
