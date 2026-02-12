/// ISO 3166-1 country code format.
enum CountryCodeFormat {
  /// Two-letter code (e.g., 'US', 'JP', 'GB').
  alpha2(length: 2),

  /// Three-letter code (e.g., 'USA', 'JPN', 'GBR').
  alpha3(length: 3);

  const CountryCodeFormat({required this.length});

  /// The expected character length of this format.
  final int length;
}
