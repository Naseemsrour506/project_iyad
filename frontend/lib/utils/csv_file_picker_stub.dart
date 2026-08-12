class PickedCsvFile {
  const PickedCsvFile({required this.filename, required this.bytes});

  final String filename;
  final List<int> bytes;
}

Future<PickedCsvFile?> pickCsvFile() {
  throw UnsupportedError('CSV upload is supported only on web.');
}
