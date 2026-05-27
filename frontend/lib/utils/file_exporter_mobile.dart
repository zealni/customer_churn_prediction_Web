// Mobile fallback
// To fully support saving files to user's device on mobile, we would use path_provider.
// This is a stub that prevents dart:html compilation errors on Android/iOS.
void exportCsvToBrowser(String fileName, String csvData) {
  print('Export CSV on Mobile: Data size: ${csvData.length} bytes.');
  print('Note: To save natively on mobile, use path_provider to save to app docs.');
}
