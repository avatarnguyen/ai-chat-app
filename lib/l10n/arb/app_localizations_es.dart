// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get counterAppBarTitle => 'Codika App';

  @override
  String get youHavePushedTheButtonThisManyTimes =>
      'Has pulsado el botón este número de veces:';

  @override
  String hello(String userName) {
    return 'Hola $userName';
  }

  @override
  String nWombats(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString wombats',
      one: '1 wombat',
      zero: 'ningún wombat',
    );
    return '$_temp0';
  }

  @override
  String pronoun(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'él',
      'female': 'ella',
      'other': 'elle',
    });
    return '$_temp0';
  }

  @override
  String numberOfDataPoints(int value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.compactCurrency(locale: localeName, decimalDigits: 2);
    final String valueString = valueNumberFormat.format(value);

    return 'Número de puntos de datos: $valueString';
  }

  @override
  String helloWorldOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Hola Mundo el $dateString';
  }

  @override
  String get escapedExample => '¡Hola! {¿No es} un día maravilloso?';
}
