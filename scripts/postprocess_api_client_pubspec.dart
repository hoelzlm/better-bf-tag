// Post-processes the pubspec.yaml that openapi-generator writes for
// packages/api_client so the package joins the root Pub workspace and
// targets the SDK this repo uses. Idempotent: running it twice in a row on
// its own output is a no-op.
//
// Usage: dart run scripts/postprocess_api_client_pubspec.dart <path-to-pubspec.yaml>
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: postprocess_api_client_pubspec.dart <pubspec.yaml>');
    exit(1);
  }

  final file = File(args.first);
  final lines = file.readAsLinesSync();
  final out = <String>[];

  var sawPublishTo = false;
  var sawResolution = false;
  var inEnvironment = false;
  var sawSdkInEnvironment = false;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.startsWith('publish_to:')) {
      sawPublishTo = true;
      out.add('publish_to: none');
      continue;
    }
    if (line.startsWith('resolution:')) {
      sawResolution = true;
      out.add('resolution: workspace');
      continue;
    }

    if (line.startsWith('environment:')) {
      inEnvironment = true;
      out.add(line);
      continue;
    }
    if (inEnvironment) {
      if (RegExp(r'^\s+sdk:').hasMatch(line)) {
        sawSdkInEnvironment = true;
        out.add("  sdk: ^3.9.0");
        continue;
      }
      // A non-indented, non-blank line ends the environment block.
      if (line.isNotEmpty && !line.startsWith(' ')) {
        inEnvironment = false;
      }
    }

    out.add(line);
  }

  // Insert publish_to/resolution right after `name:` if the generator ever
  // stops emitting them (e.g. a template change upstream).
  if (!sawPublishTo || !sawResolution) {
    final nameIndex = out.indexWhere((l) => l.startsWith('name:'));
    final insertAt = nameIndex == -1 ? 0 : nameIndex + 1;
    final toInsert = <String>[
      if (!sawPublishTo) 'publish_to: none',
      if (!sawResolution) 'resolution: workspace',
    ];
    out.insertAll(insertAt, toInsert);
  }

  if (!sawSdkInEnvironment) {
    final envIndex = out.indexWhere((l) => l.startsWith('environment:'));
    if (envIndex != -1) {
      out.insert(envIndex + 1, '  sdk: ^3.9.0');
    }
  }

  final result = '${out.join('\n').trimRight()}\n';
  file.writeAsStringSync(result);
}
