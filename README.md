# html_pdf_widgets


html_pdf_widgets is a Flutter package that allows you to convert HTML content into PDF documents with support for various Rich Text Editor formats. With this package, you can effortlessly generate PDF files that include elements such as lists, paragraphs, images, quotes, headings, and many more.

The package was built upon the [htmltopdfwidgets](https://pub.dev/packages/htmltopdfwidgets) package by simplifying the code, adding more features, and fixing bugs.

## Features

- Convert HTML content to PDF documents in Flutter apps
- Support for Rich Text Editor formats
- Seamless integration with your Flutter project
- Lightweight and easy to use

## Installation

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  html_pdf_widgets: <latest version>
```

## Usage

To use html_pdf_widgets in your Flutter project, follow these simple steps:

1. Import the package:

```dart
import 'package:html_pdf_widgets/html_pdf_widgets.dart';
```

2. Convert HTML to PDF:

```dart
final htmlContent = '''
  <h1>Heading Example</h1>
  <p>This is a paragraph.</p>
  <img src="image.jpg" alt="Example Image" />
  <blockquote>This is a quote.</blockquote>
  <ul>
    <li>First item</li>
    <li>Second item</li>
    <li>Third item</li>
  </ul>
''';

  var filePath = 'test/example.pdf';
  var file = File(filePath);
  final document = Document();
  List<Widget> widgets = await HTMLToPdf().convert(htmlContent);
  document.addPage(
    MultiPage(
      maxPages: 200,
      build: (context) => widgets
    )
  );
  await file.writeAsBytes(await document.save());
```

For more details on usage and available options, please refer to the [API documentation](https://pub.dev/documentation/htmltopdfwidgets/latest).

## Example

You can find a complete example in the [example](https://github.com/n3o2k7i8ch5/htmltopdfwidgets/tree/main/example) directory of this repository.

## License

This package is licensed under the [MIT License](https://github.com/alihassan143/htmltopdfwidgets/blob/main/LICENSE).

## Contributing

Contributions are welcome! If you encounter any issues or have suggestions for improvements, please feel free to open an issue or submit a pull request on the [GitHub repository](https://github.com/n3o2k7i8ch5/htmltopdfwidgets).


## Help Maintenance


<a href="https://buymeacoffee.com/n3o2k7i8ch5" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: auto !important;width: auto !important;" ></a>

