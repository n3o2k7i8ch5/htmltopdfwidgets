import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:htmltopdfwidgets/src/attributes.dart';
import 'package:htmltopdfwidgets/src/extension/int_extensions.dart';
import 'package:htmltopdfwidgets/src/utils/app_assets.dart';
import 'package:htmltopdfwidgets/src/utils/utils.dart';
import 'package:http/http.dart';
import 'package:printing/printing.dart';

import '../htmltopdfwidgets.dart';
import 'extension/color_extension.dart';
import 'html_tags.dart';
import 'pdfwidgets/bullet_list.dart';
import 'pdfwidgets/number_list.dart';
import 'pdfwidgets/quote_widget.dart';

////html deocoder that deocde html and convert it into pdf widgets
class WidgetsHTMLDecoder {
  /// default font of the pdf if it not provided custo
  /// Constructor for the HTML decoder
  final Font? font;

  /// Font for the PDF, if not provided, use default
  final HtmlTagStyle customStyles;

  /// Custom styles for HTML tags
  final List<Font> fontFallback;

  /// Fallback fonts
  WidgetsHTMLDecoder({
    this.font,
    required this.fontFallback,
    this.customStyles = const HtmlTagStyle(),
  });

  //// The class takes an HTML string as input and returns a list of Widgets. The Widgets
  //// are created based on the tags and attributes in the HTML string.
  Future<List<Widget>> convert(String html) async {
    /// Parse the HTML document using the html package
    final document = parse(html.trim());
    final body = document.body;
    if (body == null) {
      return [];
    }

    /// Call the private _parseElement function to process the HTML nodes
    List<Widget> nodes = await _parseElement(body.nodes);

    return nodes;
  }

  //// Converts the given HTML string to a list of Widgets.
  //// and returns the list of widgets

  Future<List<Widget>> _parseElement(
    Iterable<dom.Node> nodes,
  ) async {
    final List<TextSpan> delta = [];
    final List<Widget> result = [];
    TextAlign? textAlign;
    bool checkbox = false;
    bool alreadyChecked = false;

    void deltaToResult(){
      if (delta.isEmpty) return;

      result.add(
          RichText(
            text: TextSpan(children: List.of(delta)), textAlign: textAlign,
          )
      );

      textAlign = null;
      delta.clear();

    }

    ///find dom node in and check if its element or not than convert it according to its specs
    for (final node in nodes) {
      if (node is dom.Text) {
        delta.add(
            TextSpan(
                text: node.text,
                style: TextStyle(font: font, fontFallback: fontFallback)
            )
        );
        continue;
      }

      if (node is! dom.Element){
        assert(false, 'Unknown node type: $node');
        continue;
      }

      final localName = node.localName;
      if (localName == HTMLTags.br) {
        delta.add(const TextSpan(text: "\n"));

      } else if (HTMLTags.formattingElements.contains(localName)) {
        /// Check if the element is a simple formatting element like <span>, <bold>, or <italic>
        final attributes = _parseFormattingElementAttributes(node);
        textAlign = attributes.$1;
        delta.add(
            TextSpan(
                text: "${node.text.replaceAll(RegExp(r'\n+$'), '')}",
                style: attributes.$2
            )
        );

      } else if (HTMLTags.specialElements.contains(localName)) {
        deltaToResult();

        if (checkbox) {
          checkbox = false;

          result.add(
              Row(
                  children: [
                    SvgImage(
                        svg:
                        alreadyChecked?
                        AppAssets.checkedIcon:
                        AppAssets.unCheckedIcon
                    ),
                    ...await _parseSpecialElements(
                      node,
                      type: BuiltInAttributeKey.bulletedList,
                    ),
                  ]
              )
          );
          alreadyChecked = false;
        } else {
          if (localName == HTMLTags.checkbox) {
            final checked = node.attributes["type"];
            if (checked != null && checked == "checkbox") {
              checkbox = true;
              alreadyChecked = node.attributes.keys.contains("checked");
            }
          }

          result.addAll(
            await _parseSpecialElements(
              node,
              type: BuiltInAttributeKey.bulletedList,
            ),
          );
        }

        /// Handle special elements (e.g., headings, lists, images)
      }
    }

    deltaToResult();

    return result;
  }

  /// Function to parse special HTML elements (e.g., headings, lists, images)
  Future<Iterable<Widget>> _parseSpecialElements(
    dom.Element element, {
    required String type,
  }) async {
    final localName = element.localName;
    switch (localName) {
      /// Handle heading level 1
      case HTMLTags.h1:
        return [_parseHeadingElement(element, level: 1)];

      /// Handle heading level 2
      case HTMLTags.h2:
        return [_parseHeadingElement(element, level: 2)];

      /// Handle heading level 3
      case HTMLTags.h3:
        return [_parseHeadingElement(element, level: 3)];

      /// Handle heading level 4
      case HTMLTags.h4:
        return [_parseHeadingElement(element, level: 4)];

      /// Handle heading level 5
      case HTMLTags.h5:
        return [_parseHeadingElement(element, level: 5)];

      /// Handle heading level 6
      case HTMLTags.h6:
        return [_parseHeadingElement(element, level: 6)];

      /// Handle unordered list
      case HTMLTags.unorderedList:
        return await _parseUnOrderListElement(element);

      /// Handle ordered list and converts its children to widgets
      case HTMLTags.orderedList:
        return await _parseOrderListElement(element);

      /// Handle table
      case HTMLTags.table:
        return await _parseTable(element);

      ///if simple list is found it will handle accordingly
      case HTMLTags.listItem:
        return await _parseListItemElement(
          element,
          type: type,
          nestedList: hasInParent(element, [HTMLTags.listItem]),
        );

      /// it handles the simple paragraph element
      case HTMLTags.paragraph:
        return [await _parseParagraphElement(element)];

      /// Handle block quote tag
      case HTMLTags.blockQuote:
        return await _parseBlockQuoteElement(element);

      /// Handle the image tag
      case HTMLTags.image:
        return [await _parseImageElement(element)];

      /// Handle the line break tag

      /// if no special element is found it treated as simple paragraph
      default:
        return [await _parseParagraphElement(element)];
    }
  }

  Text paragraphNode({required String text}) {
    return Text(text);
  }

  //// Parses the attributes of a formatting element and returns a TextStyle.
  (TextAlign?, TextStyle) _parseFormattingElementAttributes(
      dom.Element element
  ) {
    final localName = element.localName;
    TextAlign? textAlign;
    TextStyle attributes = TextStyle(fontFallback: fontFallback, font: font);
    final List<TextDecoration> decoration = [];
    switch (localName) {

      /// Handle <bold> element
      case HTMLTags.bold || HTMLTags.strong:
        attributes = attributes
            .copyWith(fontWeight: FontWeight.bold)
            .merge(customStyles.boldStyle);
        break;

      /// Handle <em> <i> element
      case HTMLTags.italic || HTMLTags.em:
        attributes = attributes
            .copyWith(fontStyle: FontStyle.italic)
            .merge(customStyles.italicStyle);

        break;

      /// Handle <u> element
      case HTMLTags.underline:
        decoration.add(TextDecoration.underline);
        break;

      /// Handle <del> element
      case HTMLTags.del:
        decoration.add(TextDecoration.lineThrough);

        break;

      /// Handle <span> and <mark> element
      case HTMLTags.span || HTMLTags.mark:
        final deltaAttributes = _getDeltaAttributesFromHtmlAttributes(
          element.attributes,
        );
        textAlign = deltaAttributes.$1;
        attributes = attributes.merge(deltaAttributes.$2);
        if (deltaAttributes.$2.decoration != null) {
          decoration.add(deltaAttributes.$2.decoration!);
        }
        break;

      /// Handle <a> element
      case HTMLTags.anchor:
        final href = element.attributes['href'];
        if (href != null) {
          decoration.add(
            TextDecoration.underline,
          );
          attributes = attributes
              .copyWith(color: PdfColors.blue)
              .merge(customStyles.linkStyle);
        }
        break;

      /// Handle <code> element
      case HTMLTags.code:
        attributes = attributes
            .copyWith(background: const BoxDecoration(color: PdfColors.red))
            .merge(customStyles.codeStyle);
        break;
      default:
        break;
    }

    final deltaAttributes = _getDeltaAttributesFromHtmlAttributes(
      element.attributes,
    );
    textAlign = deltaAttributes.$1;
    attributes = attributes.merge(deltaAttributes.$2);
    if (deltaAttributes.$2.decoration != null) {
      decoration.add(deltaAttributes.$2.decoration!);
    }

    for (final child in element.children) {
      final nattributes = _parseFormattingElementAttributes(child);
      attributes = attributes.merge(nattributes.$2);
      if (nattributes.$2.decoration != null) {
        decoration.add(nattributes.$2.decoration!);
      }
      textAlign = nattributes.$1;
    }

    ///will combine style get from the children
    return (
      textAlign,
      attributes.copyWith(decoration: TextDecoration.combine(decoration))
    );
  }

  ///convert table tag into the table pdf widget
  Future<Iterable<Widget>> _parseTable(dom.Element element) async {
    final List<TableRow> tablenodes = [];

    ///iterate over html table tag body
    for (final data in element.children) {
      final rwdata = await _parsetableRows(data);

      tablenodes.addAll(rwdata);
    }

    return [
      Table(
          border: TableBorder.all(color: PdfColors.black),
          children: tablenodes),
    ];
  }

  ///converts html table tag body to table row widgets
  Future<List<TableRow>> _parsetableRows(dom.Element element) async {
    final List<TableRow> nodes = [];

    ///iterate over <tr> tag and convert its children to related pdf widget
    for (final data in element.children) {
      final tabledata = await _parsetableData(data);

      nodes.add(tabledata);
    }
    return nodes;
  }

  ///parse html data and convert to table row
  Future<TableRow> _parsetableData(
    dom.Element element,
  ) async {
    final List<Widget> nodes = [];

    ///iterate over <tr>children
    for (final data in element.children) {
      if (data.children.isEmpty) {
        ///if single <th> or<td> tag found
        final node = paragraphNode(text: data.text);

        nodes.add(node);
      } else {
        ///if nested <p><br> in <tag> found
        final newnodes = await _parseTableSpecialNodes(data);

        nodes.addAll(newnodes);
      }
    }

    ///returns the tale row
    return TableRow(
        decoration: BoxDecoration(border: Border.all(color: PdfColors.black)),
        children: nodes);
  }

  ///parse the nodes and handle theem accordingly
  Future<Iterable<Widget>> _parseTableSpecialNodes(dom.Element element) async {
    final List<Widget> nodes = [];

    ///iterate over multiple childrens
    if (element.children.isNotEmpty) {
      for (final childrens in element.children) {
        ///parse them according to their widget
        nodes.addAll(await _parseTableDataElementsData(childrens));
      }
    } else {
      nodes.addAll(await _parseTableDataElementsData(element));
    }
    return nodes;
  }

  ///check if children contains the <p> <li> or any other tag

  Future<List<Widget>> _parseTableDataElementsData(dom.Element element) async {
    final List<Widget> delta = [];
    final result = <Widget>[];

    ///find dom node in and check if its element or not than convert it according to its specs

    final localName = element.localName;

    /// Check if the element is a simple formatting element like <span>, <bold>, or <italic>
    if (localName == HTMLTags.br) {
    } else if (HTMLTags.formattingElements.contains(localName)) {
      final attributes = _parseFormattingElementAttributes(element);

      result.add(Text(element.text, style: attributes.$2));
    } else if (HTMLTags.specialElements.contains(localName)) {
      /// Handle special elements (e.g., headings, lists, images)
      result.addAll(
        await _parseSpecialElements(
          element,
          type: BuiltInAttributeKey.bulletedList,
        ),
      );
    } else if (element is dom.Text) {
      /// Process text nodes and add them to delta
      delta.add(Text(element.text,
          style: TextStyle(font: font, fontFallback: fontFallback)));
    } else {
      assert(false, 'Unknown node type: $element');
    }

    /// If there are text nodes in delta, wrap them in a Wrap widget and add to the result
    if (delta.isNotEmpty) {
      result.add(Wrap(children: delta));
    }
    return result;
  }

  /// Function to parse a heading element and return a RichText widget
  Widget _parseHeadingElement(
    dom.Element element, {
    required int level,
  }) {
    TextAlign? textAlign;
    final delta = <TextSpan>[];
    final children = element.nodes.toList();
    for (final child in children) {
      if (child is dom.Element) {
        final attributes = _parseFormattingElementAttributes(child);
        textAlign = attributes.$1;
        delta.add(TextSpan(text: child.text, style: attributes.$2));
      } else {
        delta.add(TextSpan(
            text: child.text,
            style: TextStyle(font: font, fontFallback: fontFallback)));
      }
    }

    /// Return a RichText widget with the parsed text and styles
    return SizedBox(
        width: double.infinity,
        child: RichText(
            textAlign: textAlign,
            text: TextSpan(
                children: delta,
                style: TextStyle(
                        fontSize: level.getHeadingSize,
                        fontWeight: FontWeight.bold)
                    .merge(level.getHeadingStyle(customStyles)))));
  }

  /// Function to parse a block quote element and return a list of widgets
  Future<List<Widget>> _parseBlockQuoteElement(dom.Element element) async {
    final result = <Widget>[];
    if (element.children.isNotEmpty) {
      for (final child in element.children) {
        result.addAll(
            await _parseListItemElement(
              child,
              type: BuiltInAttributeKey.quote,
              nestedList: hasInParent(child, [HTMLTags.listItem])
            )
        );
      }
    } else {
      result.add(
          buildQuotewidget(Text(element.text), customStyles: customStyles));
    }
    return result;
  }

  bool hasInParent(dom.Element element, List<String> tags){
    if(element.parent == null) return false;
    for(String tag in tags)
      if(element.parent!.localName == tag) return true;

    return hasInParent(element.parent!, tags);
  }

  /// Function to parse an unordered list element and return a list of widgets
  Future<Iterable<Widget>> _parseUnOrderListElement(dom.Element element) async {

    // Check if the list is nested within another list
    bool nestedList = hasInParent(element, [HTMLTags.listItem]);

    // If the list has no children, return a single bullet widget
    if (element.children.isEmpty)
      return [
        BulletListItemWidget(
            child: Text(
              element.text,
              style: customStyles.paragraphStyle,
            ),
            customStyles: customStyles,
            nestedList: nestedList
        )
      ];

    final result = <Widget>[];

    // Add vertical space before the list if it is not nested
    if(!nestedList && customStyles.listItemVerticalSeparatorSize > 0)
      result.add(SizedBox(height: customStyles.listItemVerticalSeparatorSize));

    // Parse each list item and add it to the result
    for (int i=0; i<element.children.length; i++) {
      final childElement = element.children[i];

      // Parse the list item element and add it to the result
      result.addAll(
          await _parseListItemElement(
              childElement,
              type: BuiltInAttributeKey.bulletedList,
              nestedList: nestedList,
          )
      );

      // Add vertical space between list items
      if(i < element.children.length - 1 && customStyles.listItemVerticalSeparatorSize > 0)
        result.add(SizedBox(height: customStyles.listItemVerticalSeparatorSize));

    }

    // Add vertical space after the list if it is not nested
    if(!nestedList && customStyles.listItemVerticalSeparatorSize > 0)
      result.add(SizedBox(height: customStyles.listItemVerticalSeparatorSize));

    return result;

  }

  /// Function to parse an ordered list element and return a list of widgets
  Future<Iterable<Widget>> _parseOrderListElement(dom.Element element) async {

    // Check if the list is nested within another list
    bool nestedList = hasInParent(element, [HTMLTags.listItem]);

    // If the list has no children, return a single number widget
    if (element.children.isEmpty)
      return [
        NumberListItemWidget(
            child: Text(
              element.text,
              style: customStyles.paragraphStyle,
            ),
            index: 1,
            customStyles: customStyles
        )
      ];

    final result = <Widget>[];

    // Add vertical space before the list if it is not nested
    if(!nestedList && customStyles.listItemVerticalSeparatorSize > 0)
      result.add(SizedBox(height: customStyles.listItemVerticalSeparatorSize));

    // Parse each list item and add it to the result
    for (var i = 0; i < element.children.length; i++) {
      final childElement = element.children[i];

      // Parse the list item element and add it to the result
      result.addAll(
          await _parseListItemElement(
            childElement,
            type: BuiltInAttributeKey.numberList, index: i + 1,
            nestedList: nestedList,
          )
      );

      // Add vertical space between list items
      if(i < element.children.length - 1 && customStyles.listItemVerticalSeparatorSize > 0)
        result.add(SizedBox(height: customStyles.listItemVerticalSeparatorSize));

    }

    // Add vertical space after the list if it is not nested
    if(!nestedList && customStyles.listItemVerticalSeparatorSize > 0)
      result.add(SizedBox(height: customStyles.listItemVerticalSeparatorSize));

    return result;
  }

  /// Function to parse a list element (unordered or ordered) and return a list of widgets
  Future<Iterable<Widget>> _parseListItemElement(
    dom.Element element, {
    required String type,
    bool withIndicator = true,
    int? index,
    required bool nestedList,
  }) async {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: await _parseElement(element.nodes)
    );

    /// Build a bullet list widget
    if (type == BuiltInAttributeKey.bulletedList) {
      return [
        BulletListItemWidget(
            child: child,
            customStyles: customStyles,
            nestedList: nestedList,
            withIndicator: withIndicator
        )
      ];

      /// Build a numbered list widget
    } else if (type == BuiltInAttributeKey.numberList) {
      return [
        NumberListItemWidget(
            child: child,
            index: index!,
            customStyles: customStyles,
            withIndicator: withIndicator
        )
      ];

      /// Build a quote  widget
    } else if (type == BuiltInAttributeKey.quote) {
      return [buildQuotewidget(child, customStyles: customStyles)];
    } else {
      return [child];
    }
  }

  /// Function to parse a paragraph element and return a widget
  Future<Widget> _parseParagraphElement(dom.Element element) async {
    return await _parseDeltaElement(element);
  }

  /// Function to parse an image element and return an Image widget
  Future<Widget> _parseImageElement(dom.Element element) async {
    final src = element.attributes["src"];
    try {
      if (src == null) return Text("");

      // Handle base64 image provided as string
      if (src.startsWith("data:image/")) {
        // Separate from the base64 metadata, if there is any
        final List<String> components = src.split(",");

        if (components.length > 1) {
          var base64Encoded = components.last;
          Uint8List listData = base64Decode(base64Encoded);
          return Image(
            MemoryImage(listData),
            alignment: customStyles.imageAlignment,
          );
        }
        return Text("");
      }

      // Handle svg image provided as an asset
      if (src.startsWith("asset:") && src.endsWith(".svg")) {
        String? svgData = await readStringFromAssets(src.substring("asset:".length));
        if(svgData == null) return Text("");
        return SvgImage(
            svg: svgData,
            alignment: customStyles.imageAlignment
        );
        
      // Handle raster (pixel) image provided as an asset
      } else if (src.startsWith("asset:")) {
        return Image(
            await imageFromAssetBundle(src.substring("asset:".length)),
            alignment: customStyles.imageAlignment
        );
      }

      final netImage = await _saveImage(src);

      // Handle svg image provided as a web URL
      if(src.endsWith(".svg")) {
        return SvgImage(
            svg: utf8.decode(netImage),
            alignment: customStyles.imageAlignment
        );
      }

      // Handle raster (pixel) image provided as a web URL
      return Image(
          MemoryImage(netImage),
          alignment: customStyles.imageAlignment
      );

    } catch (e) {
      return Text("");
    }
  }

  /// Function to download and save an image from a URL
  Future<Uint8List> _saveImage(String url) async {
    try {
      /// Download image
      final Response response = await get(Uri.parse(url));

      /// Get temporary directory

      return response.bodyBytes;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<Widget> _parseDeltaElement(dom.Element element, {TextAlign? align, TextStyle? style}) async {

    var (newAlign, newStyle) = _getDeltaAttributesFromHtmlAttributes(
        element.attributes
    );

    align = newAlign ?? align ?? TextAlign.left;
    style = newStyle.merge(style ?? customStyles.paragraphStyle);

    final List<TextSpan> delta = [];
    final List<Widget> result = [];

    void deltaToResult(){
      if (delta.isEmpty) return;
      result.add(
          // SizedBox expands the RichText widget to the full width of the
          // parent. This way the text is able to be aligned properly.
          SizedBox(
            width: double.infinity,
            child: RichText(
              textAlign: align,
              text: TextSpan(children: List.of(delta)),
            ),
          )
      );
    }

    for (final dom.Node node in element.nodes) {

      // Not of type `Element` - convert to text and add to delta.
      if(node is! dom.Element){
        delta.add(
          TextSpan(
            text: node.text?.replaceAll(RegExp(r'\n+$'), '') ?? "",
            style: style
          )
        );
        continue;
      }

      // Handle new line breaks within the paragraph
      if (node.localName == HTMLTags.br) {
        delta.add(const TextSpan(text: "\n"));
        continue;
      }

      // Handle simple formatting elements (e.g., <bold>, <italic>, <underline>)
      if(HTMLTags.formattingElements.contains(node.localName)) {
        deltaToResult();

        final (newAlign, newStyle) = _parseFormattingElementAttributes(node);
        result.add(
            await _parseDeltaElement(
                node,
                align: newAlign ?? align,
                style: newStyle.merge(style)
            )
        );

        continue;
      }

      // Handle special elements (e.g., headings, lists) within a paragraph
      if(HTMLTags.specialElements.contains(node.localName)) {
        deltaToResult();

        result.addAll(
          await _parseSpecialElements(
            node, type: BuiltInAttributeKey.bulletedList,
          )
        );
        continue;
      }

      // No match so far - parse text and attributes within the paragraph
      deltaToResult();
      result.add(
          await _parseDeltaElement(node, align: align, style: style)
      );

    }

    deltaToResult();

    /// Create a column with wrapped text and child nodes
    return Wrap(children: result);
  }

  /// Function to parse a complex HTML element and return a widget
  // Future<Widget> _parseDeltaElement(dom.Element element) async {
  //   final delta = <TextSpan>[];
  //   final children = element.nodes.toList();
  //   final childNodes = <Widget>[];
  //   TextAlign? textAlign;
  //   for (final child in children) {
  //     /// Recursively parse child elements
  //     if (child is dom.Element) {
  //       if (child.children.isNotEmpty &&
  //           HTMLTags.formattingElements.contains(child.localName) == false) {
  //         childNodes.addAll(await _parseElement(child.children));
  //       } else {
  //         /// Handle special elements (e.g., headings, lists) within a paragraph
  //         if (HTMLTags.specialElements.contains(child.localName)) {
  //           childNodes.addAll(
  //             await _parseSpecialElements(
  //               child,
  //               type: BuiltInAttributeKey.bulletedList,
  //             ),
  //           );
  //         } else {
  //           if (child.localName == HTMLTags.br) {
  //             delta.add(const TextSpan(
  //               text: "\n",
  //             ));
  //           } else {
  //             /// Parse text and attributes within the paragraph
  //             final attributes = _parseFormattingElementAttributes(child);
  //             textAlign = attributes.$1;
  //
  //             delta.add(TextSpan(
  //                 text: "${child.text.replaceAll(RegExp(r'\n+$'), ' ')} ",
  //                 style: attributes.$2.merge(customStyles.paragraphStyle)));
  //           }
  //         }
  //       }
  //     } else {
  //       final attributes =
  //       _getDeltaAttributesFromHtmlAttributes(element.attributes);
  //       textAlign = attributes.$1;
  //
  //       /// Process text nodes and add them to delta variable
  //       delta.add(TextSpan(
  //           text: child.text?.replaceAll(RegExp(r'\n+$'), '') ?? "",
  //           style: attributes.$2
  //               .copyWith(font: font, fontFallback: fontFallback)
  //               .merge(customStyles.paragraphStyle)));
  //     }
  //   }
  //
  //   /// Create a column with wrapped text and child nodes
  //   return Wrap(children: [
  //     SizedBox(
  //       width: double.infinity,
  //       child: RichText(textAlign: textAlign, text: TextSpan(children: delta)),
  //     ),
  //     ...childNodes
  //   ]);
  // }

  /// Utility function to convert a CSS string to a map of CSS properties
  static Map<String, String> _cssStringToMap(String? cssString) {
    final Map<String, String> result = {};
    if (cssString == null) {
      return result;
    }
    final entries = cssString.split(';');
    for (final entry in entries) {
      final tuples = entry.split(':');
      if (tuples.length < 2) {
        continue;
      }
      result[tuples[0].trim()] = tuples[1].trim();
    }
    return result;
  }

  /// Function to extract text styles from HTML attributes
  (TextAlign?, TextStyle) _getDeltaAttributesFromHtmlAttributes(
      LinkedHashMap<Object, String> htmlAttributes
  ) {
    TextStyle style = const TextStyle();
    TextAlign? textAlign;

    ///extract styls from the inline css
    final styleString = htmlAttributes["style"];
    final cssMap = _cssStringToMap(styleString);

    ///get font weight
    final fontWeightStr = cssMap["font-weight"];
    if (fontWeightStr != null) {
      if (fontWeightStr == "bold") {
        style = style
            .copyWith(fontWeight: FontWeight.bold)
            .merge(customStyles.boldStyle);
      } else {
        int? weight = int.tryParse(fontWeightStr);
        if (weight != null && weight > 500) {
          style = style
              .copyWith(fontWeight: FontWeight.bold)
              .merge(customStyles.boldStyle);
        }
      }
    }

    ///apply different text decorations like undrline line through
    final textDecorationStr = cssMap["text-decoration"];
    if (textDecorationStr != null) {
      style = style.copyWith(
          decoration:
              _assignTextDecorations(style, textDecorationStr).decoration);
    }

    ///apply background color on text
    final backgroundColorStr = cssMap["background-color"];
    final backgroundColor = backgroundColorStr == null
        ? null
        : ColorExtension.tryFromRgbaString(backgroundColorStr);
    if (backgroundColor != null) {
      style = style.copyWith(color: backgroundColor);
    }

    ///apply background color on text
    final colorstr = cssMap["color"];
    final color =
        colorstr == null ? null : ColorExtension.tryFromRgbaString(colorstr);
    if (color != null) {
      style = style.copyWith(color: color);
    }

    ///apply italic tag

    if (cssMap["font-style"] == "italic") {
      style = style
          .copyWith(fontStyle: FontStyle.italic)
          .merge(customStyles.italicStyle);
    }
    final align = cssMap["text-align"];
    if (align != null) {
      textAlign = _alignText(align);
    }

    return (textAlign, style);
  }

  static TextAlign _alignText(String alignmentString) {
    switch (alignmentString) {
      case "right":
        return TextAlign.right;
      case "center":
        return TextAlign.center;
      case "left":
        return TextAlign.left;
      case "justify":
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  ///this function apply thee text decorations from html inline style css
  static TextStyle _assignTextDecorations(
      TextStyle style, String decorationStr) {
    final decorations = decorationStr.split(" ");
    final textdecorations = <TextDecoration>[];
    for (final d in decorations) {
      if (d == "line-through") {
        textdecorations.add(TextDecoration.lineThrough);
      } else if (d == "underline") {
        textdecorations.add(TextDecoration.underline);
      }
    }
    return style.copyWith(decoration: TextDecoration.combine(textdecorations));
  }
}
