// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:html_pdf_widgets/html_pdf_widgets.dart';

//apply custom styles to html stylee
class HtmlTagStyle {
  //bold style that will merge with default style
  final TextStyle? boldStyle;
  //italic style that will merge with default style
  final TextStyle? italicStyle;
  //bold and italic style that will merge with default style
  final TextStyle? boldItalicStyle;
  //h1 tag style that will merge with default style
  final TextStyle? h1Style;
  //h2 tag style that will merge with default style
  final TextStyle? h2Style;
  //h3 tag style that will merge with default style
  final TextStyle? h3Style;
  //h4 tag style that will merge with default style
  final TextStyle? h4Style;
  //h5 tag style that will merge with default style
  final TextStyle? h5Style;
  //h6 tag style that will merge with default style
  final TextStyle? h6Style;
  //strike through style that will merge with default style
  final TextStyle? strikeThrough;
  //image alignment style that will merge with default style
  final Alignment imageAlignment;
  //paragraph style style that will merge with default style
  final TextStyle? paragraphStyle;
  //code tag style that will merge with default style
  final TextStyle? codeStyle;
  //heading style that will merge with default style
  final TextStyle? headingStyle;
  //list index style that will merge with default style
  final TextStyle? listIndexStyle;
  //href link style that will merge with default style
  final TextStyle? linkStyle;
  final PdfColor? quoteBarColor;
  final double listTopPadding;
  final double listBottomPadding;
  final PdfColor? bulletListIconColor;
  final double bulletListDotSize;
  final double bulletListIconSize;
  final EdgeInsets listItemIndicatorPadding;
  final double listItemIndicatorWidth;
  final double listItemVerticalSeparatorSize;
  final double headingTopSpacing;
  final double headingBottomSpacing;
  final EdgeInsets tablePadding;
  final double borderRadius;
  final double blockSpacing;

  const HtmlTagStyle({
    this.boldStyle,
    this.italicStyle,
    this.boldItalicStyle,
    this.h1Style,
    this.h2Style,
    this.h3Style,
    this.imageAlignment = Alignment.center,
    this.h4Style,
    this.h5Style,
    this.h6Style,
    this.strikeThrough,
    this.paragraphStyle,
    this.codeStyle,
    this.headingStyle,
    this.listIndexStyle,
    this.linkStyle,
    this.quoteBarColor,
    this.listTopPadding = 6.0,
    this.listBottomPadding = 6.0,
    this.bulletListIconColor,
    this.bulletListDotSize = 5.0,
    this.bulletListIconSize = 14.0,
    this.listItemIndicatorPadding = const EdgeInsets.only(right: 12.0),
    this.listItemIndicatorWidth = 24.0,
    this.listItemVerticalSeparatorSize = 6.0,
    this.headingTopSpacing = 12.0,
    this.headingBottomSpacing = 18.0,
    this.tablePadding = const EdgeInsets.all(6.0),
    this.borderRadius = 8.0,
    this.blockSpacing = 8.0,
  });
}
