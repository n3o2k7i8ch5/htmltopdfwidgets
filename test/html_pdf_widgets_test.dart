/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io';
import 'dart:typed_data';

import 'package:html_pdf_widgets/html_pdf_widgets.dart';
import 'package:test/test.dart';

late Document pdf;

void main() {

  const htmlText = '''
    <h1>Heading Example 1</h1>
    <h2>Heading Example 2</h2>
    <h3>Heading Example 3</h3>
    
    <p>You should see a Flutter svg image below:</p>
    <img src="https://storage.googleapis.com/cms-storage-bucket/6a07d8a62f4308d2b854.svg" alt="Example Image" />
    
    <p>You should see a Google png image below:</p>
    <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Google_2015_logo.svg/640px-Google_2015_logo.svg.png" alt="Example Image" />
    
    <p>This is a paragraph.</p>

    <blockquote>This is a quote.</blockquote>

    <h4>### Test unordered nested list</h4>
    <ul>
      <li>First item</li>
      <li>Second item</li>
      <li>Third item</li>
      <li>
      <ul>
      <li>1st subitem</li>
      <li>2nd subitem</li>
      <li>3rd subitem, and here goes some text to see if the subitems are all aligned properly to the left.</li>
      </ul>
      </li>
      <li>Fourth item</li>
    </ul>

    <h4>### Test ordered nested list</h4>
    <ol>
      <li>First item<br>With a newline</li>
      <li>Second item<br><i>With an italics newline</i></li>
      <li>Third item<br><b>With a bold newline</b></li>
      <li>
      <ol>
        <li>First subitem<br>With a newline</li>
        <li>Second subitem<br><i>With an italics newline</i></li>
        <li>Third subitem<br><b>With a bold newline</b></li>
      </ol>
      </li>
    </ol>
    <br>

    <h4>### Test single formattings</h4>
    <p><b>Hello there bold</b></p>
    <p><i>Hello there italic</i></p>
    <p><u>Hello there underline</u></p>

    <h4>Test multiple formattings is one paragraph with newline</h4>
    <p>Regular text<br>Regular text (after a newline)</p>
    <p><b>Bold text<br>Bold text (after a newline)</b></p>
    <p><b><i>Bold and italic text<br>Bold and italic text (after a newline)</i></b></p>
    <p><b><i><u>Bold, italic and underline text<br>Bold, italic and underline text (after a newline)</u></i></b></p>
    <p><b><i>Bold and italic text<br><u>Bold, italic and underline text (after a newline)</u></i></b></p>
    <p><i><u>Italic and underline text<b><br>Bold, italic and underline text (after a newline)</b></u></i></p>

    <h4>### Test text alignment</h4>

    <p style="text-align:justify;">This is a very long, but lovely and tremendously pleasant and easy to read line in a paragraph that is justified.</p>
    <p style="text-align:left;">This is a line in a paragraph that is aligned left.</p>
    <p style="text-align:right;">This is a line in a paragraph that is aligned right.</p>
    <p style="text-align:center;">This is a line in a paragraph that is aligned center.</p>

    <h4>### Test simple table</h4>
    <table>
    <tr>
      <th>Company</th>
      <th>Contact</th>
      <th>Country</th>
    </tr>
    <tr>
      <td>Alfreds Futterkiste</td>
      <td>Maria Anders</td>
      <td>Germany</td>
    </tr>
    <tr>
      <td>Centro comercial Moctezuma</td>
      <td>Francisco Chang</td>
      <td>Mexico</td>
    </tr>
  </table>
  
  <h4>### Test fancy table</h4>
    <table>
    <tr>
      <th style="padding-left: 8px; padding-right: 8px;">Some header no 1</th>
      <th style="padding-left: 8px; padding-right: 8px;">Some header no 2</th>
      <th style="padding-left: 8px; padding-right: 8px;">Some header no 3</th>
    </tr>
    <tr>
      <td style="padding-left: 8px; padding-right: 8px;"><p>We have exactly one <u>underlined</u> word in this table.</p></td>
      <td style="padding-left: 8px; padding-right: 8px;"><p>We have exactly one <b>bold</b> word in this table.</p></td>
      <td style="padding-left: 8px; padding-right: 8px;"><p>We have exactly one <i>italic</i> word in this table.</p></td>
    </tr>
    <tr>
      <td style="padding-left: 8px; padding-right: 8px;">
        <ol>
          <li>First item<br>With a newline</li>
          <li>Second item<br><i>With an italics newline</i></li>
          <li>Third item<br><b>With a bold newline</b></li>
          <li>
          <ol>
            <li>First subitem<br>With a newline</li>
            <li>Second subitem<br><i>With an italics newline</i></li>
            <li>Third subitem<br><b>With a bold newline</b></li>
          </ol>
          </li>
        </ol>
      </td>
      <td style="padding-left: 8px; padding-right: 8px;">Nested list in a table should be visible on the left-hand side</td>
      <td style="padding-left: 8px; padding-right: 8px;">Mexico</td>
    </tr>
  </table>''';

  setUpAll(() {
    // Document.debug = true;
    // RichText.debug = true;
    pdf = Document();
  });

  test('convertion_test', () async {
    List<Widget> widgets = await HTMLToPdf().convert(htmlText);
    pdf.addPage(
        MultiPage(
          maxPages: 200,
          build: (context) => widgets,
        )
    );

    final file = File('example.pdf');
    Uint8List pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);

  });

}
