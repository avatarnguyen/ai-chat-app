// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get counterAppBarTitle => 'Application Codika';

  @override
  String get youHavePushedTheButtonThisManyTimes =>
      'Vous avez appuyé sur le bouton ce nombre de fois :';

  @override
  String hello(String userName) {
    return 'Bonjour $userName';
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
      zero: 'aucun wombat',
    );
    return '$_temp0';
  }

  @override
  String pronoun(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'il',
      'female': 'elle',
      'other': 'iel',
    });
    return '$_temp0';
  }

  @override
  String numberOfDataPoints(int value) {
    final intl.NumberFormat valueNumberFormat = intl
        .NumberFormat.compactCurrency(locale: localeName, decimalDigits: 2);
    final String valueString = valueNumberFormat.format(value);

    return 'Nombre de points de données : $valueString';
  }

  @override
  String helloWorldOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Bonjour le monde le $dateString';
  }

  @override
  String get escapedExample => 'Bonjour ! {N\'est-ce pas} une belle journée ?';
}
