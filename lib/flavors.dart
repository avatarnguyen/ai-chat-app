import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum Flavor {
  dev,
  
  prod,
  
}

class F {
  static Flavor? appFlavor;
}

/// Global function to return the current flavor
Flavor getFlavor() {
  // * On iOS/Android, appFlavor is supported and set with the --flavor option
  // * On web, appFlavor is not supported so we read a separate SW_ENV
  // * variable and set it with --dart-define SW_ENV=dev|stag|prod|test
  const webFlavor = String.fromEnvironment('SW_ENV');
  const flavor = kIsWeb ? webFlavor : appFlavor;
  return switch (flavor) {
    'dev' => Flavor.dev,
    'prod' => Flavor.prod,
    
    
    null || '' => Flavor.values.first,
    _ => throw UnsupportedError('Invalid flavor: $flavor'),
  };
}

extension FlavorExtension on Flavor {
  String get asString => toString().split('.').last;
}
// ignore_for_file:no-equal-switch-expression-cases,avoid-nullable-interpolation