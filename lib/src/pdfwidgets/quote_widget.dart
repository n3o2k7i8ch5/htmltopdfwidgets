import '../../html_pdf_widgets.dart';
import '../utils/app_assets.dart';

Widget buildQuoteWidget(Widget child, {required HtmlTagStyle customStyles}) {
  final quoteColor = customStyles.quoteBarColor ?? PdfColors.grey600;
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    decoration: BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: BorderRadius.all(Radius.circular(customStyles.borderRadius)),
      border: Border(
        left: BorderSide(
          color: quoteColor,
          width: 3,
        ),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6, top: 2),
          child: SvgImage(
            svg: AppAssets.quoteIcon,
            width: 16,
            height: 16,
            colorFilter: quoteColor,
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}
