import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/server_provider.dart';
import '../services/user_credentials_service.dart';
import '../models/saved_user.dart';
import '../l10n/generated/app_localizations.dart';
import '5signup_screen.dart';
import '6home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberPassword = false;
  bool _hasNavigated = false; // Prevent multiple navigation
  
  // Autocomplete
  final UserCredentialsService _credentialsService = UserCredentialsService.instance;
  List<String> _usernameSuggestions = [];
  bool _showSuggestions = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _usernameFocusNode = FocusNode();
  String _currentServerUrl = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupUsernameListener();
    _initializeServerUrl();
    
    // Check existing credentials after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingCredentials();
    });
  }

  @override
  void didUpdateWidget(LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload users when screen updates
    print('[LoginScreen] Screen updated, reloading users...');
    _loadInitialUsers();
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
  
  void _setupUsernameListener() {
    _usernameController.addListener(() {
      _onUsernameChanged(_usernameController.text);
    });
    
    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus) {
        // Give time for click to process before hiding
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_usernameFocusNode.hasFocus) {
            setState(() {
              _showSuggestions = false;
            });
            print('[LoginScreen] Dropdown hidden due to focus loss');
          }
        });
      } else {
        // When field receives focus, reload users
        print('[LoginScreen] Username field focused, reloading users...');
        _loadInitialUsers();
      }
    });
  }
  
  void _initializeServerUrl() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final serverProvider = Provider.of<ServerProvider>(context, listen: false);
      setState(() {
        _currentServerUrl = serverProvider.currentServerUrl;
      });
      print('[LoginScreen] Current server initialized: $_currentServerUrl');
      _loadInitialUsers();
      _debugPrintAllUsers();
    });
  }
  
  Future<void> _debugPrintAllUsers() async {
    try {
      final allUsers = await _credentialsService.getAllUsers();
      print('[LoginScreen] === DEBUG: All users in DB ===');
      for (final user in allUsers) {
        print('[LoginScreen] ${user.username} @ ${user.serverUrl} (remember: ${user.rememberPassword})');
      }
      print('[LoginScreen] === Total: ${allUsers.length} users ===');
    } catch (e) {
      print('[LoginScreen] Error en debug: $e');
    }
  }
  
  Future<void> _loadInitialUsers() async {
    try {
      print('[LoginScreen] Loading initial users for server: $_currentServerUrl');
      
      // Debug: Check all users first
      final allUsers = await _credentialsService.getAllUsers();
      print('[LoginScreen] Total users in DB: ${allUsers.length}');
      for (final user in allUsers) {
        print('[LoginScreen] 👤 ${user.username} @ ${user.serverUrl} (remember: ${user.rememberPassword})');
      }
      
      // Load users for current server
      final users = await _credentialsService.getSavedUsers(_currentServerUrl);
      print('[LoginScreen] Users for current server: ${users.length}');
      
      if (users.isNotEmpty) {
        setState(() {
          _usernameSuggestions = users.map((user) => user.username).toList();
        });
        print('[LoginScreen] Suggestions updated: $_usernameSuggestions');
      } else {
        print('[LoginScreen] No saved users found for this server');
        setState(() {
          _usernameSuggestions = [];
        });
      }
    } catch (e) {
      print('[LoginScreen] Error loading initial users: $e');
    }
  }
  
  Future<void> _onUsernameChanged(String value) async {
    print('[LoginScreen] Username cambiado: "$value"');
    
    if (value.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _rememberPassword = false; // Reset checkbox if no username
      });
      return;
    }
    
    try {
      // Get suggestions
      final suggestions = await _credentialsService.getUserSuggestions(_currentServerUrl, value);
      print('[LoginScreen] Suggestions obtained: $suggestions');
      
      // Check credentials for this specific user
      final userInfo = await _credentialsService.getUserInfo(_currentServerUrl, value.trim());
      
      if (mounted) {
        setState(() {
          if (suggestions.isNotEmpty) {
            _usernameSuggestions = suggestions;
            _showSuggestions = true;
          } else {
            _showSuggestions = false;
          }
          
          // Update checkbox state based on existing credentials
          if (userInfo != null && userInfo.rememberPassword) {
            print('[LoginScreen] ✅ User has saved credentials - checking checkbox');
            _rememberPassword = true;
          } else {
            print('[LoginScreen] ❌ User has no credentials - unchecking checkbox');
            _rememberPassword = false;
          }
        });
      }
    } catch (e) {
      print('[LoginScreen] Error getting suggestions: $e');
    }
  }
  
  void _showSuggestionsOverlay() {
    _hideSuggestions();
    
    print('[LoginScreen] Creating overlay with ${_usernameSuggestions.length} suggestions');
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 24,
        right: 24,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF1A1D47),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _usernameSuggestions.map((username) {
                  return GestureDetector(
                    onTap: () {
                      print('[LoginScreen] GestureDetector: Click detected on user: $username');
                      _selectUsername(username);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.login,
                            color: Colors.white54,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
    
    print('[LoginScreen] Inserting overlay in context');
    Overlay.of(context).insert(_overlayEntry!);
    print('[LoginScreen] Overlay inserted successfully');
  }
  
  void _hideSuggestions() {
    print('[LoginScreen] Hiding suggestions...');
    try {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) {
        setState(() {
          _showSuggestions = false;
        });
        print('[LoginScreen] Suggestions hidden');
      } else {
        print('[LoginScreen] Widget not mounted, state not updated');
      }
    } catch (e) {
      print('[LoginScreen] Error hiding suggestions: $e');
    }
  }
  
  Future<void> _selectUsername(String username) async {
    print('[LoginScreen] User selected: $username');
    print('[LoginScreen] Current server: $_currentServerUrl');
    
    _hideSuggestions();
    _usernameController.text = username;
    
    print('[LoginScreen] Username field updated');
    
    // Try to auto-fill password
    try {
      print('[LoginScreen] Trying to retrieve saved password...');
      final password = await _credentialsService.getDecryptedPassword(_currentServerUrl, username);
      
      if (password != null) {
        print('[LoginScreen] Password retrieved successfully, filling field...');
        _passwordController.text = password;
        setState(() {
          _rememberPassword = true;
        });
        print('[LoginScreen] Password field filled and checkbox activated');
      } else {
        print('[LoginScreen] Could not retrieve password (password is null)');
      }
    } catch (e) {
      print('[LoginScreen] Error getting saved password: $e');
    }
  }

  // Simplified direct method for dropdown
  Future<void> _selectUsernameDirectly(String username) async {
    print('[LoginScreen] DIRECTO - User selected: $username');
    print('[LoginScreen] DIRECTO - Current server: $_currentServerUrl');
    
    // Ocultar dropdown
    setState(() {
      _showSuggestions = false;
      _usernameController.text = username;
    });
    
    print('[LoginScreen] DIRECTO - Username field updated');
    
    // Try to auto-fill password
    try {
      print('[LoginScreen] DIRECTO - Trying to retrieve saved password...');
      final password = await _credentialsService.getDecryptedPassword(_currentServerUrl, username);
      
      if (password != null) {
        print('[LoginScreen] DIRECTO - Password retrieved successfully, filling field...');
        setState(() {
          _passwordController.text = password;
          _rememberPassword = true;
        });
        print('[LoginScreen] DIRECTO - Password field filled and checkbox activated');
      } else {
        print('[LoginScreen] DIRECTO - Could not retrieve password (password is null)');
      }
    } catch (e) {
      print('[LoginScreen] DIRECTO - Error getting saved password: $e');
    }
  }
  
  // Check if saved credentials exist for current user
  Future<void> _checkExistingCredentials() async {
    try {
      final serverProvider = context.read<ServerProvider>();
      final currentServerUrl = serverProvider.currentServerUrl;
      final currentUsername = _usernameController.text.trim();
      
      if (currentUsername.isNotEmpty) {
        print('[LoginScreen] Checking existing credentials for: $currentUsername');
        
        // Check if saved credentials exist for this user
        final userInfo = await _credentialsService.getUserInfo(currentServerUrl, currentUsername);
        
        if (userInfo != null && userInfo.rememberPassword) {
          print('[LoginScreen] ✅ Credentials found - updating checkbox state');
          if (mounted) {
            setState(() {
              _rememberPassword = true;
            });
            
            // Show feedback to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.credentials_found_message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          print('[LoginScreen] ❌ No saved credentials for this user');
        }
      }
    } catch (e) {
      print('[LoginScreen] Error checking existing credentials: $e');
    }
  }

  // Handle checkbox changes with warnings
  Future<void> _handleRememberPasswordChange(bool newValue) async {
    final currentUsername = _usernameController.text.trim();
    
    // If there's a user and unchecking the checkbox
    if (currentUsername.isNotEmpty && _rememberPassword && !newValue) {
      // Check if saved credentials exist
      try {
        final userInfo = await _credentialsService.getUserInfo(_currentServerUrl, currentUsername);
        
        if (userInfo != null && userInfo.rememberPassword) {
          // Show warning before unchecking
          final shouldProceed = await _showCredentialDeletionWarning();
          if (!shouldProceed) {
            return; // Don't change state if user cancels
          }
        }
      } catch (e) {
        print('[LoginScreen] Error checking credentials for warning: $e');
      }
    }
    
    setState(() {
      _rememberPassword = newValue;
    });
    
    // Visual feedback
    if (newValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.password_will_be_remembered),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Show warning about credential deletion
  Future<bool> _showCredentialDeletionWarning() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D47),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.delete_credentials_title,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.delete_credentials_message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.delete_credentials_cancel,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete_credentials_confirm,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  // Method to save credentials in background
  void _saveCredentialsInBackground(String serverUrl, String username, String password) {
    _credentialsService.saveUserCredentials(
      serverUrl: serverUrl,
      username: username,
      password: password,
      rememberPassword: _rememberPassword,
    ).then((saveResult) {
      print('[LoginScreen] Credentials saved: $saveResult');
    }).catchError((error) {
      print('[LoginScreen] Error saving credentials: $error');
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _hideSuggestions();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hasNavigated) {
      print('[LoginScreen] Navigation already in progress, ignoring additional click');
      return;
    }

    setState(() => _isLoading = true);
    print('[LoginScreen] Starting login process...');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serverProvider = Provider.of<ServerProvider>(context, listen: false);

    try {
      print('[LoginScreen] Llamando a authProvider.login...');
      final success = await authProvider.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        serverUrl: serverProvider.currentServerUrl,
      );
      
      print('[LoginScreen] Login result: $success');

      if (success) {
        print('[LoginScreen] Successful login, starting post-login process...');
        _hasNavigated = true;

        // Save credentials in background (don't block navigation)
        if (_rememberPassword) {
          print('[LoginScreen] Saving credentials in background...');
          _credentialsService.saveUserCredentials(
            serverUrl: serverProvider.currentServerUrl,
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            rememberPassword: _rememberPassword,
          ).then((result) {
            print('[LoginScreen] Save result: $result');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result 
                    ? AppLocalizations.of(context)!.password_saved_successfully
                    : AppLocalizations.of(context)!.password_save_failed),
                  backgroundColor: const Color(0xFF2D3FE7),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }).catchError((error) {
            print('[LoginScreen] Error saving: $error');
          });
        }

        // Navegar inmediatamente
        if (mounted) {
          print('[LoginScreen] Navegando a HomeScreen...');
          await Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
          print('[LoginScreen] Navigation completed successfully');
        } else {
          print('[LoginScreen] Widget desmontado, no se puede navegar');
        }
      } else {
        print('[LoginScreen] Login failed');
        // Reset navigation flag if login failed
        _hasNavigated = false;
      }
    } catch (e) {
      print('[LoginScreen] Exception during login: $e');
      _hasNavigated = false;
    } finally {
      // Only update state if we haven't navigated successfully
      if (mounted && !_hasNavigated) {
        print('[LoginScreen] Finishing login process...');
        setState(() => _isLoading = false);
        
        // Show errors if any
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.errorMessage != null) {
          print('[LoginScreen] Mostrando error: ${authProvider.errorMessage}');
          final errorMessage = AppLocalizations.of(context)!.login_error_prefix + authProvider.errorMessage!;
          _showErrorDialog(context, errorMessage);
        }
      } else if (_hasNavigated) {
        print('[LoginScreen] Successful login, state not updated (navigation completed)');
      }
    }
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
              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildLoginForm(),
                      const SizedBox(height: 16),
                      _buildHelpInfo(),
                      const SizedBox(height: 16),
                      _buildServerInfo(),
                      const SizedBox(height: 16),
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
                AppLocalizations.of(context)!.login_title,
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
          AppLocalizations.of(context)!.login_subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
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
            const SizedBox(height: 16),
            _buildRememberPasswordCheckbox(),
            const SizedBox(height: 32),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _usernameController,
          focusNode: _usernameFocusNode,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context)!.username_required_error;
            }
            if (value.trim().length < 3) {
              return AppLocalizations.of(context)!.username_length_error;
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.username_label,
            hintText: AppLocalizations.of(context)!.username_placeholder,
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            prefixIcon: Icon(Icons.person, color: Colors.white.withValues(alpha: 0.7)),
            suffixIcon: _usernameSuggestions.isNotEmpty 
                ? Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.7))
                : null,
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
          onTap: () async {
            print('[LoginScreen] Username field tapped, reloading users...');
            await _loadInitialUsers();
            
            if (_usernameSuggestions.isNotEmpty) {
              print('[LoginScreen] Activating dropdown with ${_usernameSuggestions.length} suggestions');
              setState(() {
                _showSuggestions = true;
              });
            } else {
              print('[LoginScreen] No suggestions to show');
              setState(() {
                _showSuggestions = false;
              });
            }
          },
        ),
        // Direct dropdown without overlay
        if (_showSuggestions && _usernameSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D47),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.saved_users_header,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          print('[LoginScreen] Cerrando dropdown manualmente');
                          setState(() {
                            _showSuggestions = false;
                          });
                        },
                        icon: Icon(
                          Icons.close,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 16,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                // User list
                ...(_usernameSuggestions.map((username) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        print('[LoginScreen] DIRECTO: Click detected on user: $username');
                        _selectUsernameDirectly(username);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D3FE7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.tap_to_autocomplete_hint,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white54,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.password_required_error;
        }
        if (value.length < 6) {
          return AppLocalizations.of(context)!.password_length_error;
        }
        return null;
      },
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.password_label,
        hintText: AppLocalizations.of(context)!.password_placeholder,
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
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
    );
  }

  Widget _buildRememberPasswordCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _rememberPassword,
          onChanged: (value) {
            _handleRememberPasswordChange(value ?? false);
          },
          activeColor: const Color(0xFF2D3FE7),
          checkColor: Colors.white,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            _handleRememberPasswordChange(!_rememberPassword);
          },
          child: Text(
            AppLocalizations.of(context)!.remember_password_label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
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
            onPressed: (_isLoading || authProvider.isLoading) ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: (_isLoading || authProvider.isLoading)
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.logging_in_button,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Text(
                    AppLocalizations.of(context)!.login_button,
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


  Widget _buildServerInfo() {
    return Consumer<ServerProvider>(
      builder: (context, serverProvider, child) {
        // Update server URL if it has changed
        if (_currentServerUrl != serverProvider.currentServerUrl) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _currentServerUrl = serverProvider.currentServerUrl;
            });
            print('[LoginScreen] Server updated to: $_currentServerUrl');
            _loadInitialUsers();
          });
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dns,
                size: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.server_prefix,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Flexible(
                child: Text(
                  serverProvider.serverDisplayName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.no_account_question,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignupScreen()),
              );
            },
            child: Text(
              AppLocalizations.of(context)!.register_link,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
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

// Show authentication errors
void _showErrorDialog(BuildContext context, String error) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1D47),
      title: Text(
        AppLocalizations.of(context)!.login_error_prefix.replaceAll(': ', ''),
        style: const TextStyle(color: Colors.white),
      ),
      content: Text(
        error,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.close_dialog,
            style: const TextStyle(color: Color(0xFF2D3FE7)),
          ),
        ),
      ],
    ),
  );
}