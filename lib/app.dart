import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/growth_store.dart';
import 'screens/root_shell.dart';

class PersonalGrowthApp extends StatelessWidget {
  const PersonalGrowthApp({super.key, required this.store});

  final GrowthStore store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GrowthStore>.value(
      value: store,
      child: MaterialApp(
        title: '个人成长分析',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const RootShell(),
      ),
    );
  }
}
