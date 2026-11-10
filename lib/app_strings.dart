import 'package:flutter/widgets.dart';

String ludoText(BuildContext context, String arabic, String english) {
  return Localizations.localeOf(context).languageCode == 'en'
      ? english
      : arabic;
}

String ludoColorName(BuildContext context, String arabic, String english) {
  return ludoText(context, arabic, english);
}
