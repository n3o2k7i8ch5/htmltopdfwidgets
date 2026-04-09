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

    return buildListItem(
      child: child,
      indicator: indicator,
      indicatorWidth: customStyles.listItemIndicatorWidth,
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
