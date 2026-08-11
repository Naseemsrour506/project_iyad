// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

void downloadCsvFile(String filename, String content) {
  final List<int> bytes = utf8.encode(content);
  final html.Blob blob = html.Blob(<Object>[bytes], 'text/csv;charset=utf-8');
  final String url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();

  html.Url.revokeObjectUrl(url);
}
