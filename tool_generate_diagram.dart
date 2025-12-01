import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  final packageName = 'flutter_application_1';
  final libDir = Directory('lib');
  
  if (!libDir.existsSync()) {
    print('Error: lib directory not found');
    return;
  }

  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  print('graph TD');
  // Styling
  print('  node [shape=box, style=filled, fillcolor="#f9f9f9", color="#666666"];');

  // Collect all files first to ensure we only link to existing files
  final filePaths = <String>{};
  for (var file in files) {
    var sourcePath = p.relative(file.path, from: 'lib').replaceAll('\\', '/');
    filePaths.add(sourcePath);
  }

  for (var file in files) {
    var content = file.readAsStringSync();
    var lines = content.split('\n');
    var sourcePath = p.relative(file.path, from: 'lib').replaceAll('\\', '/');
    var sourceId = _getId(sourcePath);

    // Print node definition with label
    print('  $sourceId["$sourcePath"]');

    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('import ')) {
        var importPath = _extractImport(line);
        if (importPath == null) continue;

        String? targetPath;
        String? targetId;
        String? linkLabel;

        if (importPath.startsWith('package:$packageName/')) {
          targetPath = importPath.replaceFirst('package:$packageName/', '');
        } else if (importPath.startsWith('package:')) {
           // External package
           var pkgName = importPath.split('/')[0].replaceFirst('package:', '');
           targetId = _getId('pkg_$pkgName');
           print('  $targetId["$pkgName (package)"]:::package');
           print('  class $targetId package');
        } else if (importPath.startsWith('dart:')) {
           // Dart SDK - skip to avoid clutter or group? Skip for now for "clear" diagram
           continue; 
        } else {
           // Relative path
           var fileDir = p.dirname(sourcePath);
           // Handle parent directories manually if needed, but p.normalize does it
           // We need to be careful about 'lib' prefix. sourcePath is relative to lib.
           // So fileDir is relative to lib.
           // If import is '../models/foo.dart', and file is 'pages/bar.dart', fileDir is 'pages'.
           // join('pages', '../models/foo.dart') -> 'models/foo.dart'. Correct.
           targetPath = p.normalize(p.join(fileDir, importPath)).replaceAll('\\', '/');
        }

        if (targetPath != null) {
           // Verify target exists in our project
           if (filePaths.contains(targetPath)) {
             targetId = _getId(targetPath);
           } else {
             // Maybe it's a generated file or I missed it? 
             // Or maybe it's outside lib? (unlikely for flutter)
             // Just ignore if not found to keep it clean, or mark as missing?
             // Let's ignore for clarity unless it's critical.
             continue;
           }
        }

        if (targetId != null) {
           print('  $sourceId --> $targetId');
        }
      }
    }
  }
  print('  classDef package fill:#e1f5fe,stroke:#01579b,stroke-width:2px;');
}

String _getId(String path) {
  // Create a safe ID
  return path.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
}

String? _extractImport(String line) {
  var match = RegExp(r"import\s+['""]([^'""]+)['""]").firstMatch(line);
  return match?.group(1);
}
