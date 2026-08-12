// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedCsvFile {
  const PickedCsvFile({required this.filename, required this.bytes});

  final String filename;
  final List<int> bytes;
}

Future<PickedCsvFile?> pickCsvFile() async {
  final Completer<PickedCsvFile?> completer = Completer<PickedCsvFile?>();

  final html.FileUploadInputElement input = html.FileUploadInputElement()
    ..accept = '.csv,text/csv';

  input.click();

  input.onChange.first.then((_) {
    final List<html.File>? files = input.files;

    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final html.File file = files.first;
    final html.FileReader reader = html.FileReader();

    reader.onError.first.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Could not read CSV file.'));
      }
    });

    reader.onLoadEnd.first.then((_) {
      final Object? result = reader.result;

      if (result is ByteBuffer) {
        if (!completer.isCompleted) {
          completer.complete(
            PickedCsvFile(filename: file.name, bytes: result.asUint8List()),
          );
        }
        return;
      }

      if (result is Uint8List) {
        if (!completer.isCompleted) {
          completer.complete(PickedCsvFile(filename: file.name, bytes: result));
        }
        return;
      }

      if (!completer.isCompleted) {
        completer.completeError(Exception('Unsupported CSV file format.'));
      }
    });

    reader.readAsArrayBuffer(file);
  });

  return completer.future;
}
