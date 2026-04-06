import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/routes.dart';
import '../../theme/theme.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final isLoggedIn = supabase.auth.currentUser != null;
    if (isLoggedIn) {
      context.go(RoutesClass.overview);
    } else {
      context.go(RoutesClass.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/logos/logo_app.png",height: 150,width: 150,),
            const SizedBox(height: 24),
            Text(
              'TCF En Main',
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 48),
            SpinKitFadingCircle(
              color: AppColors.accent,
              size: 44,
            ),
          ],
        ),
      ),
    );
  }
}
