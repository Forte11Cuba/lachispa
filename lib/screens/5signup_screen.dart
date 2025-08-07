import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/server_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '6home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _hasAcceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _glowController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasAcceptedTerms) {
      _showErrorDialog('Debes aceptar los términos y condiciones');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serverProvider = Provider.of<ServerProvider>(context, listen: false);

    try {
      final success = await authProvider.signup(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        serverUrl: serverProvider.currentServerUrl,
      );

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada exitosamente! Bienvenido.'),
            backgroundColor: Color(0xFF2D3FE7),
            duration: Duration(seconds: 1),
          ),
        );
        
        // Navigate to HomeScreen and clear navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Error handled by AuthProvider
    } finally {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.errorMessage != null) {
          _showErrorDialog(authProvider.errorMessage!);
        }
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D47),
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFF2D3FE7)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F1419),
              Color(0xFF1A1D47),
              Color(0xFF2D3FE7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top navigation arrow
              _buildTopNavigation(),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 40),
                      _buildSignupForm(),
                      const SizedBox(height: 20),
                      _buildTermsCheckbox(),
                      const SizedBox(height: 20),
                      _buildServerInfo(),
                      const SizedBox(height: 40),
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

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D3FE7).withValues(alpha: _glowAnimation.value * 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Text(
                AppLocalizations.of(context)!.create_account_title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF2D3FE7).withValues(alpha: _glowAnimation.value * 0.8),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Crea una nueva cuenta para acceder a tu billetera',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUsernameField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 20),
            _buildConfirmPasswordField(),
            const SizedBox(height: 32),
            _buildSignupButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El nombre de usuario es requerido';
        }
        if (value.trim().length < 3) {
          return 'El nombre de usuario debe tener al menos 3 caracteres';
        }
        if (value.trim().length > 20) {
          return 'El nombre de usuario no puede tener más de 20 caracteres';
        }
        // Only letters, numbers and some special characters
        final validPattern = RegExp(r'^[a-zA-Z0-9_.-]+$');
        if (!validPattern.hasMatch(value.trim())) {
          return 'Solo se permiten letras, números, _, . y -';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.signup_username_label,
        hintText: AppLocalizations.of(context)!.signup_username_placeholder,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(Icons.person, color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3FE7)),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'La contraseña es requerida';
        }
        if (value.length < 8) {
          return 'La contraseña debe tener al menos 8 caracteres';
        }
        if (value.length > 50) {
          return 'La contraseña no puede tener más de 50 caracteres';
        }
        // At least one number
        if (!RegExp(r'[0-9]').hasMatch(value)) {
          return 'La contraseña debe contener al menos un número';
        }
        // At least one letter
        if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
          return 'La contraseña debe contener al menos una letra';
        }
        return null;
      },
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.signup_password_label,
        hintText: AppLocalizations.of(context)!.signup_password_placeholder,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.7)),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3FE7)),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Confirma tu contraseña';
        }
        if (value != _passwordController.text) {
          return AppLocalizations.of(context)!.passwords_mismatch_error;
        }
        return null;
      },
      obscureText: !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.confirm_password_label,
        hintText: AppLocalizations.of(context)!.confirm_password_placeholder,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.7)),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          onPressed: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3FE7)),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleSignup(),
    );
  }

  Widget _buildSignupButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D3FE7), Color(0xFF4C63F7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ElevatedButton(
            onPressed: (_isLoading || authProvider.isLoading) ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: (_isLoading || authProvider.isLoading)
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.create_account_button,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              checkboxTheme: CheckboxThemeData(
                fillColor: MaterialStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Color(0xFF2D3FE7);
                  }
                  return Colors.transparent;
                }),
                checkColor: MaterialStateProperty.all(Colors.white),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
            ),
            child: Checkbox(
              value: _hasAcceptedTerms,
              onChanged: (value) {
                setState(() {
                  _hasAcceptedTerms = value ?? false;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'He anotado mi contraseña en un lugar seguro',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildServerInfo() {
    return Consumer<ServerProvider>(
      builder: (context, serverProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dns,
                size: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Servidor: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                serverProvider.serverDisplayName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopNavigation() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
          ),
        ],
      ),
    );
  }
}