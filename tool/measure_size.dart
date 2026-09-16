// ignore_for_file: avoid_print

// Measures what a consumer actually pays for this package, per feature.
//
// Each probe is compiled twice, once as written and once importing nothing, so
// that runtime and entrypoint scaffolding cancel out of the difference.
//
// Usage:
//   dart run tool/measure_size.dart [--keep]
import 'dart:io';

/// Lookup keys come from `args` so the compilers cannot constant-fold a const
/// map lookup and optimise away the data the probe is meant to measure.
const _preamble = '''
void main(List<String> args) {
  final key = args.isEmpty ? 'Asia/Tokyo' : args.first;
''';

const _baselineSource = '$_preamble  print(key.length);\n}\n';

String _probeSource(String body) =>
    "import 'package:timezone_country/timezone_country.dart';\n\n"
    '$_preamble$body}\n';

final _probes = <String, String>{
  'baseline': _baselineSource,
  'timezoneToCountryCode': _probeSource(
    '  print(TimezoneConvert.timezoneToCountryCode(key));\n',
  ),
  'countryName+countryFlag': _probeSource(
    '  print(TimezoneConvert.countryName(key));\n'
    '  print(TimezoneConvert.countryFlag(key));\n',
  ),
  'timezoneToWindows': _probeSource(
    '  print(TimezoneConvert.timezoneToWindows(key));\n',
  ),
  'timezoneCoordinates': _probeSource(
    '  print(TimezoneConvert.timezoneCoordinates(key));\n',
  ),
  'wholePublicApi': _probeSource(
    '  print(TimezoneConvert.timezoneToCountryCode(key));\n'
    '  print(TimezoneConvert.timezoneToCountryCodes(key));\n'
    '  print(TimezoneConvert.countryToTimezones(key));\n'
    '  print(TimezoneConvert.resolveTimezone(key));\n'
    '  print(TimezoneConvert.alpha2ToAlpha3(key));\n'
    '  print(TimezoneConvert.alpha3ToAlpha2(key));\n'
    '  print(TimezoneConvert.countryName(key));\n'
    '  print(TimezoneConvert.countryFlag(key));\n'
    '  print(TimezoneConvert.countryCodeFromFlag(key));\n'
    '  print(TimezoneConvert.countryNumericCode(key));\n'
    '  print(TimezoneConvert.numericToCountryCode(key));\n'
    '  print(TimezoneConvert.windowsToTimezone(key));\n'
    '  print(TimezoneConvert.windowsToTimezones(key));\n'
    '  print(TimezoneConvert.timezoneToWindows(key));\n'
    '  print(TimezoneConvert.timezoneCity(key));\n'
    '  print(TimezoneConvert.metazone(key));\n'
    '  print(TimezoneConvert.timezoneGenericName(key));\n'
    '  print(TimezoneConvert.timezoneStandardName(key));\n'
    '  print(TimezoneConvert.timezoneDaylightName(key));\n'
    '  print(TimezoneConvert.primaryTimezone(key));\n'
    '  print(TimezoneConvert.timezoneFixedOffset(key));\n'
    '  print(TimezoneConvert.isKnownTimezone(key));\n'
    '  print(TimezoneConvert.fixedOffsetTimezones.length);\n'
    '  print(TimezoneConvert.timezoneComment(key));\n'
    '  print(TimezoneConvert.timezoneCoordinates(key));\n'
    '  print(TimezoneConvert.nearestTimezone(0, 0));\n'
    '  print(TimezoneConvert.isValidTimezone(key));\n'
    '  print(TimezoneConvert.isValidCountryCode(key));\n'
    '  print(TimezoneConvert.isKnownCountryCode(key));\n'
    '  print(TimezoneConvert.allTimezones.length);\n'
    '  print(TimezoneConvert.allCountryCodes.length);\n'
    '  print(TimezoneConvert.allCountryCodesAlpha3.length);\n'
    '  print(TimezoneConvert.ianaVersion);\n'
    '  print(TimezoneConvert.windowsZonesVersion);\n'
    '  print(TimezoneConvert.windowsZonesIanaVersion);\n'
    '  print(key.toCountryCode);\n',
  ),
};

class _Target {
  const _Target(this.name, this.args, this.output);

  final String name;

  /// Built as `dart compile <args> <output> <input>`.
  final List<String> Function(String output, String input) args;

  /// The artifact whose bytes are measured, relative to the probe directory.
  final String Function(String stem) output;
}

final _targets = <_Target>[
  _Target(
    'dart2js --minify',
    (out, input) => ['compile', 'js', '-O4', '--minify', '-o', out, input],
    (stem) => '$stem.js',
  ),
  // dart2wasm also emits a .mjs loader; only the .wasm module carries the data.
  _Target(
    'dart2wasm',
    (out, input) => ['compile', 'wasm', '-O2', '-o', out, input],
    (stem) => '$stem.wasm',
  ),
  _Target(
    'AOT exe',
    (out, input) => ['compile', 'exe', '-o', out, input],
    (stem) => '$stem.exe',
  ),
];

void main(List<String> args) {
  final keep = args.contains('--keep');

  final dir = Directory('build/measure_size');
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);

  try {
    for (final entry in _probes.entries) {
      File('${dir.path}/${entry.key}.dart').writeAsStringSync(entry.value);
    }

    for (final target in _targets) {
      final sizes = <String, ({int raw, int gzipped})>{};
      var failure = '';
      for (final name in _probes.keys) {
        final out = '${dir.path}/${target.output(name)}';
        final result = Process.runSync('dart', [
          ...target.args(out, '${dir.path}/$name.dart'),
        ]);
        if (result.exitCode != 0) {
          failure = '${result.stdout}${result.stderr}'.trim();
          break;
        }
        final bytes = File(out).readAsBytesSync();
        sizes[name] = (raw: bytes.length, gzipped: gzip.encode(bytes).length);
      }
      _report(target.name, sizes, failure);
    }
  } finally {
    if (!keep) dir.deleteSync(recursive: true);
  }
}

void _report(
  String target,
  Map<String, ({int raw, int gzipped})> sizes,
  String failure,
) {
  print('\n## $target');
  if (failure.isNotEmpty) {
    print('  compile failed:');
    print(failure.split('\n').map((l) => '    $l').join('\n'));
    return;
  }

  final baseline = sizes['baseline']!;
  const widths = [26, 12, 12, 14, 14];
  final header = ['entrypoint', 'raw', 'gzip', '+raw', '+gzip'];
  print(_row(header, widths));
  print(widths.map((w) => '-' * w).join(' '));
  for (final entry in sizes.entries) {
    final isBaseline = entry.key == 'baseline';
    print(
      _row([
        entry.key,
        _kb(entry.value.raw),
        _kb(entry.value.gzipped),
        isBaseline ? '-' : _kb(entry.value.raw - baseline.raw),
        isBaseline ? '-' : _kb(entry.value.gzipped - baseline.gzipped),
      ], widths),
    );
  }
}

String _row(List<String> cells, List<int> widths) => [
  cells.first.padRight(widths.first),
  for (var i = 1; i < cells.length; i++) cells[i].padLeft(widths[i]),
].join(' ');

String _kb(int bytes) => '${(bytes / 1024).toStringAsFixed(1)} KB';
