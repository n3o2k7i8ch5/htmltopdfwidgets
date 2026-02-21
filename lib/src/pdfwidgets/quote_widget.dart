import '../../html_pdf_widgets.dart';

Widget buildQuoteWidget(Widget child, {required HtmlTagStyle customStyles}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    decoration: BoxDecoration(
      color: PdfColors.grey100,
      border: Border(
        left: BorderSide(
          color: customStyles.quoteBarColor ?? PdfColors.grey600,
          width: 3,
        ),
      ),
    ),
    child: child,
  );
}
