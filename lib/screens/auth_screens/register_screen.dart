import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/routes.dart';
import '../../theme/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  int _passwordStrengthLevel = 0;
  String _passwordStrengthLabel = 'Force du mot de passe';
  Color _passwordStrengthColor = AppColors.textMuted;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
        },
      );

      if (!mounted) return;

      _showToast(
        'Compte créé avec succès ! Vérifiez votre email.',
        isError: false,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.go(RoutesClass.login);
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.message.contains('already registered')) {
        _showToast('Un compte existe déjà avec cet email');
      } else {
        _showToast(e.message);
      }
    } catch (_) {
      if (!mounted) return;
      _showToast('Erreur lors de la création du compte. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          if (isWide) {
            return Row(
              children: [
                Expanded(child: _buildLeftPanel()),
                Expanded(child: _buildRightPanel()),
              ],
            );
          }
          return _buildRightPanel();
        },
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
          // Éléments décoratifs
          ..._buildDecorativeElements(),
          // Lien retour
          Positioned(
            top: 24,
            left: 24,
            child: InkWell(
              onTap: () => context.go(RoutesClass.splash),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 8),
                    Text(
                      "Retour à l'accueil",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Contenu centré
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logos/logo_app.png',
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 550,
                    child: Text(
                      'Rejoignez TCF En Main et commencez votre apprentissage du français. '
                          'Créez votre compte gratuitement et accédez à des milliers de questions et exercices.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 23,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDecorativeElements() {
    const elements = [
      _DecoElement(type: 'circle', size: 8, left: 0.15, top: 0.20, opacity: 0.4),
      _DecoElement(type: 'circle', size: 12, left: 0.85, top: 0.15, opacity: 0.3),
      _DecoElement(type: 'dot', size: 4, left: 0.25, top: 0.70, opacity: 0.5),
      _DecoElement(type: 'dot', size: 6, left: 0.60, top: 0.10, opacity: 0.6),
      _DecoElement(type: 'dot', size: 8, left: 0.20, top: 0.50, opacity: 0.4),
      _DecoElement(type: 'circle', size: 8, left: 0.80, top: 0.60, opacity: 0.3),
      _DecoElement(type: 'dot', size: 4, left: 0.70, top: 0.75, opacity: 0.4),
      _DecoElement(type: 'circle', size: 12, left: 0.10, top: 0.85, opacity: 0.3),
      _DecoElement(type: 'dot', size: 8, left: 0.50, top: 0.15, opacity: 0.5),
      _DecoElement(type: 'circle', size: 4, left: 0.65, top: 0.50, opacity: 0.6),
    ];

    return elements.map((e) {
      return Align(
        alignment: FractionalOffset(e.left, e.top),
        child: Opacity(
          opacity: e.opacity,
          child: e.type == 'dot'
              ? Container(
                  width: e.size,
                  height: e.size,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                )
              : Container(
                  width: e.size,
                  height: e.size,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1),
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      );
    }).toList();
  }

  Widget _buildRightPanel() {
    return Container(
      color: AppColors.bgCard,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: 24),
                  _buildForm(),
                  const SizedBox(height: 20),
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/logos/logo_app.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'TCF En Main',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => context.go(RoutesClass.login),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Créer un compte',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Rejoignez TCF Canada Training et commencez votre apprentissage du français. '
                'Créez votre compte gratuitement et accédez à des milliers de questions et exercices.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/logos/logo_app.png',
            width: 72,
            height: 72,
            fit: BoxFit.contain,
          ),
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
          _buildNameFields(),
          const SizedBox(height: 16),
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 16),
          _buildConfirmPasswordField(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
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
                        Icon(Icons.person_add_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Créer le compte'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildNameField(
            controller: _firstNameController,
            label: 'Prénom',
            hint: 'Votre prénom',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildNameField(
            controller: _lastNameController,
            label: 'Nom',
            hint: 'Votre nom',
          ),
        ),
      ],
    );
  }

  Widget _buildNameField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ce champ est requis';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'votre@email.com',
            prefixIcon: Icon(Icons.mail_outline),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer votre email';
            }
            if (!value.contains('@')) {
              return 'Veuillez entrer un email valide';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mot de passe', style: Theme.of(context).textTheme.labelLarge),
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
      ],
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

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmer le mot de passe',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleRegister(),
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
      ],
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Vous avez déjà un compte ? ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => context.go(RoutesClass.login),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFooterItem(Icons.info_outline, 'À propos de nous'),
          _buildFooterItem(Icons.chat_bubble_outline, 'Contactez-nous'),
          _buildFooterItem(Icons.shield_outlined, 'Politique de\nconfidentialité'),
        ],
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecoElement {
  final String type;
  final double size;
  final double left;
  final double top;
  final double opacity;

  const _DecoElement({
    required this.type,
    required this.size,
    required this.left,
    required this.top,
    required this.opacity,
  });
}
