import 'dart:io';

/// Simple script to replace occurrences of
///   Color(0xAARRGGBB).withOpacity(alpha)
/// with
///   Color.fromRGBO(r, g, b, alpha)
///
/// Usage:
///   dart run tools/fix_withopacity.dart        # dry-run (report only)
///   dart run tools/fix_withopacity.dart --apply  # apply changes

final _pattern = RegExp(r"Color\(\s*0x([A-Fa-f0-9]{8})\s*\)\.withOpacity\(\s*([^\)]+?)\s*\)");

// pattern to find variable declarations assigned to Color(0xAARRGGBB)
final _varDeclPattern = RegExp(r"(?:static\s+)?(?:const|final|var)?\s*(?:Color\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*Color\(\s*0x([A-Fa-f0-9]{8})\s*\)");

// simple mapping for Colors.black/white withOpacity
final _simpleColorsPattern = RegExp(r"Colors\.(black|white)\.withOpacity\(\s*([^\)]+?)\s*\)");

class _VarReplacement {
  final int start;
  final int end;
  final String original;
  final String replacement;
  _VarReplacement(this.start, this.end, this.original, this.replacement);
}

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final cwd = Directory.current;
  print('Running fix_withopacity.dart in ${cwd.path}');

  final dartFiles = <File>[];
  await for (final entity in cwd.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // skip generated files or hidden folders if needed
      if (entity.path.contains('.dart_tool') || entity.path.contains('build') || entity.path.contains('packages')) continue;
      dartFiles.add(entity);
    }
  }

  var totalMatches = 0;
  final modifiedFiles = <String>[];

  for (final file in dartFiles) {
    final text = await file.readAsString();
  final matches = _pattern.allMatches(text).toList();
  final varDecls = _varDeclPattern.allMatches(text).toList();
  if (matches.isEmpty && varDecls.isEmpty) continue;

    // additionally, detect local Color variable declarations so we can replace var.withOpacity(...) usages
    final varMap = <String, String>{}; // varName -> hex
    for (final m in _varDeclPattern.allMatches(text)) {
      final name = m.group(1)!;
      final hex = m.group(2)!;
      varMap[name] = hex;
    }
    // (we'll directly search per-variable below when building replacements)

  totalMatches += matches.length;
    print('\nFile: ${file.path} - ${matches.length} matches');

    var newText = text;
    // replace direct Color(...).withOpacity first
    for (final m in matches.reversed) {
      final hexStr = m.group(1)!; // AARRGGBB
      final alphaExpr = m.group(2)!;
      final value = int.parse(hexStr, radix: 16);
      final r = (value >> 16) & 0xFF;
      final g = (value >> 8) & 0xFF;
      final b = value & 0xFF;

      final replacement = 'Color.fromRGBO($r, $g, $b, $alphaExpr)';
      final start = m.start;
      final end = m.end;
      newText = newText.replaceRange(start, end, replacement);
      print('  - Replaced "${text.substring(start, end)}" => "$replacement"');
    }

    // handle var.withOpacity replacements (use original text indices); collect matches per var
    final varReplacements = <_VarReplacement>[];
    if (varMap.isNotEmpty) {
      for (final entry in varMap.entries) {
        final name = entry.key;
        final hex = entry.value;
        final value = int.parse(hex, radix: 16);
        final r = (value >> 16) & 0xFF;
        final g = (value >> 8) & 0xFF;
        final b = value & 0xFF;
        final vpat = RegExp(r"\b" + RegExp.escape(name) + r"\.withOpacity\(\s*([^\)]+?)\s*\)");
        for (final um in vpat.allMatches(text)) {
          final alpha = um.group(1)!;
          final repl = 'Color.fromRGBO($r, $g, $b, $alpha)';
          varReplacements.add(_VarReplacement(um.start, um.end, text.substring(um.start, um.end), repl));
        }
      }
      // apply var replacements in reverse order to avoid shifting indices
      varReplacements.sort((a, b) => b.start.compareTo(a.start));
      for (final vr in varReplacements) {
        newText = newText.replaceRange(vr.start, vr.end, vr.replacement);
        print('  - Replaced "${vr.original}" => "${vr.replacement}"');
      }
    }

    // handle simple Colors.black/white.withOpacity(...) replacements
    final simpleMatches = _simpleColorsPattern.allMatches(text).toList();
    if (simpleMatches.isNotEmpty) {
      for (final m in simpleMatches.reversed) {
        final name = m.group(1)!;
        final alpha = m.group(2)!;
        final r = name == 'black' ? 0 : 255;
        final g = name == 'black' ? 0 : 255;
        final b = name == 'black' ? 0 : 255;
        final repl = 'Color.fromRGBO($r, $g, $b, $alpha)';
        newText = newText.replaceRange(m.start, m.end, repl);
        print('  - Replaced "${text.substring(m.start, m.end)}" => "$repl"');
      }
      totalMatches += simpleMatches.length;
    }

    if (apply) {
      await file.writeAsString(newText);
      modifiedFiles.add(file.path);
    }
  }

  print('\nSummary: total matches: $totalMatches');
  if (apply) {
    print('Files modified: ${modifiedFiles.length}');
    for (final f in modifiedFiles) print(' - $f');
  } else {
    print('Dry-run complete. Rerun with --apply to apply changes.');
  }
}
