import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'routes/routes.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  runApp(const TCFEnMainApp());
}

class TCFEnMainApp extends StatelessWidget {
  const TCFEnMainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TCF En Main',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: RoutesClass.router,
      builder: (context, child) {
        child = FToastBuilder()(context, child);
        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (_) => SelectionArea(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}

