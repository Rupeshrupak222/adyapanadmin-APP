import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Copy image assets from brain directory', () {
    final assetsDir = Directory('d:/adyapan_admin/assets');
    if (!assetsDir.existsSync()) {
      assetsDir.createSync(recursive: true);
      print('Created assets directory.');
    }

    final sourceDir = 'C:/Users/kapis/.gemini/antigravity/brain/77966bf8-58be-4e83-9bf4-80110f696f97';
    
    final filesToCopy = {
      'media__1780052980892.jpg': 'schools.jpg',
      'media__1780052980685.jpg': 'educators.jpg',
      'media__1780052980824.jpg': 'attendance.jpg',
      'media__1780052980918.jpg': 'doubts.jpg',
    };

    filesToCopy.forEach((srcName, destName) {
      final srcFile = File('$sourceDir/$srcName');
      final destFile = File('${assetsDir.path}/$destName');
      
      if (srcFile.existsSync()) {
        srcFile.copySync(destFile.path);
        print('Copied $srcName -> ${destFile.path} successfully!');
      } else {
        print('Source file not found: ${srcFile.path}');
      }
    });
  });
}
