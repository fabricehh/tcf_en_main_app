import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/routes.dart';
import '../../theme/theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _supabase = Supabase.instance.client;

  late final StreamSubscription<AuthState> _authSubscription;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _resetSuccess = false;
  bool _isReady = false;
  String _userEmail = '';

  int _passwordStrengthLevel = 0;
  String _passwordStrengthLabel = 'Force du mot de passe';
  Color _passwordStrengthColor = AppColors.textMuted;

  @override
  void initState() {
    super.initState();
    _listenAuthState();
  }

  void _listenAuthState() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.passwordRecovery) {
        final email = session?.user.email;
        if (email != null && email.isNotEmpty) {
          setState(() {
            _userEmail = email;
            _isReady = true;
          });
        } else {
          _redirectToLogin('Lien de réinitialisation invalide.');
        }
      } else if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        // Ignorer ces événements, ils peuvent précéder passwordRecovery
      } else if (event == AuthChangeEvent.signedOut) {
        _redirectToLogin('Session expirée. Veuillez réessayer.');
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isReady) {
        _redirectToLogin('Le lien a expiré ou est invalide.');
      }
    });
  }

  void _redirectToLogin(String message) {
    if (!mounted) return;
    _showToast(message);
    context.go(RoutesClass.login);
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = true}) {
    final bgColor = isError ? '#e53935' : '#43a047';
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      timeInSecForIosWeb: 5,
      gravity: ToastGravity.TOP,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 14,
      webBgColor: bgColor,
    );
  }

  void _updatePasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrengthLevel = 0;
        _passwordStrengthLabel = 'Force du mot de passe';
        _passwordStrengthColor = AppColors.textMuted;
      });
      return;
    }

    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) strength++;

    String label;
    Color color;

    switch (strength) {
      case 1:
        label = 'Très faible';
        color = const Color(0xFFEF4444);
      case 2:
        label = 'Faible';
        color = const Color(0xFFF97316);
      case 3:
        label = 'Bon';
        color = const Color(0xFFEAB308);
      case >= 4:
        label = 'Très fort';
        color = const Color(0xFF22C55E);
      default:
        label = 'Très faible';
        color = const Color(0xFFEF4444);
    }

    setState(() {
      _passwordStrengthLevel = strength;
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
    });
  }

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (!mounted) return;

      setState(() => _resetSuccess = true);
      _showToast(
        'Mot de passe modifié avec succès !',
        isError: false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.message.contains('same_password')) {
        _showToast('Le nouveau mot de passe doit être différent de l\'ancien');
      } else {
        _showToast(e.message);
      }
    } catch (_) {
      if (!mounted) return;
      _showToast('Une erreur est survenue. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SpinKitFadingCircle(color: AppColors.accent, size: 48),
              const SizedBox(height: 20),
              Text(
                'Vérification en cours...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: _buildLeftPanel()),
                          Expanded(
                            child: _resetSuccess
                                ? _buildSuccessContent()
                                : _buildFormContent(),
                          ),
                        ],
                      );
                    }
                    return _resetSuccess
                        ? _buildSuccessContent()
                        : _buildFormContent();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgPanel, AppColors.bgPanelDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nouveau\nmot de passe',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choisissez un mot de passe fort et unique pour sécuriser votre compte.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w300,
                        fontSize: 16,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Container(
      color: AppColors.bgCard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modifier le mot de passe',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Choisissez un nouveau mot de passe pour votre compte',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _userEmail,
            readOnly: true,
            enabled: false,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 20),
          Text('Nouveau mot de passe',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onChanged: _updatePasswordStrength,
            decoration: InputDecoration(
              hintText: 'Minimum 8 caractères',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un mot de passe';
              }
              if (value.length < 8) {
                return 'Le mot de passe doit contenir au moins 8 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 6),
          _buildPasswordStrengthBar(),
          const SizedBox(height: 20),
          Text('Confirmer le mot de passe',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleUpdatePassword(),
            decoration: InputDecoration(
              hintText: 'Répétez votre mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez confirmer votre mot de passe';
              }
              if (value != _passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleUpdatePassword,
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpinKitThreeBounce(color: Colors.white, size: 20),
                      ],
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 8),
                        Text('Enregistrer'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _passwordStrengthLevel / 5,
            minHeight: 4,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              _passwordStrengthLevel > 0
                  ? _passwordStrengthColor
                  : Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _passwordStrengthLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _passwordStrengthColor,
                fontSize: 14,
              ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Container(
      color: AppColors.bgCard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Mot de passe modifié !',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Votre mot de passe a été mis à jour avec succès. Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(RoutesClass.login),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login, size: 20),
                      SizedBox(width: 8),
                      Text('Aller à la connexion'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
