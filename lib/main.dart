import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/theme.dart';
import 'data/growth_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 初始化：数据存放在应用私有目录，卸载即清除，全程不联网
  await Hive.initFlutter();
  final store = await GrowthStore.open();

  // 纸张底色 + 深色状态栏图标
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.card,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(PersonalGrowthApp(store: store));
}
