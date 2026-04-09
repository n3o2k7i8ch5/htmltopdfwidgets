import '../../html_pdf_widgets.dart';
import 'list_item_container.dart';

Widget NumberListItemWidget({
  required Widget child,
  required int index,
  required HtmlTagStyle customStyles,
  bool withIndicator = true,
  required TextStyle baseTextStyle,
}) {
  final indicator = withIndicator
      ? _NumberListIndicator(style: customStyles, index: index, baseTextStyle: baseTextStyle)
      : SizedBox(width: customStyles.listItemIndicatorWidth);

  if (child is SpanningWidget) {
    return ListItemContainer(
      content: child,
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
