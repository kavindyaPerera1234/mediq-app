import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import 'registration_screen.dart';
import 'forgot_password_screen.dart';
import 'verification_code_screen.dart';
import 'splash_screen.dart';
import 'package:mediq_app/features/admin_dashboard/screens/admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isStaffMode;

  const LoginScreen({super.key, this.isStaffMode = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  late bool _isStaff;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _useOtpLogin = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isStaff = widget.isStaffMode;
    // Keep inputs completely clean and empty for real users
    _phoneOrEmailController.clear();
    _passwordController.clear();
  }

  @override
  void dispose() {
    _phoneOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = AuthService();
    final input = _phoneOrEmailController.text.trim();
    final password = _passwordController.text.trim();

    // ── Staff or Patient Password Login ─────────────────────────────────────
    if (_isStaff || !_useOtpLogin) {
      try {
        await authService.loginWithEmailPassword(input, password);

        if (!mounted) return;

        if (role == 'admin') {
          // Route to Admin Dashboard — clear all previous routes
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminDashboardScreen(), // Re-enter splash to route properly
            ),
            (route) => false,
          );
        } else if (role == 'patient' || role == 'caregiver') {
          // Rare case: patient account used on staff form
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const PatientMainScreen(),
            ),
            (route) => false,
          );
        } else {
          // doctor / nurse / receptionist / staff
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const SplashScreen(), // Re-enter splash to route properly
            ),
            (route) => false,
          );
        }

        authService.routeUserByRole(context);
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
          switch (e.code) {
            case 'user-not-found':
              _errorMessage = _isStaff
                  ? 'No account found with this email.'
                  : 'No account found with this phone/email. Please register first.';
              break;
            case 'wrong-password':
            case 'invalid-credential':
              _errorMessage = 'Incorrect password. Please try again.';
              break;
            case 'invalid-email':
              _errorMessage = 'Please enter a valid email address or phone number.';
              break;
            case 'user-disabled':
              _errorMessage = 'This account has been disabled.';
              break;
            case 'too-many-requests':
              _errorMessage = 'Too many attempts. Please try again later.';
              break;
            default:
              _errorMessage = e.message ?? 'Login failed. Please check your credentials.';
          }
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Login failed. Please check your credentials.';
        });
      }
    } else {
      // ── Optional SMS OTP Login ───────────────────────────────────────────
      bool userExists = await authService.loginPatient(input);
      setState(() => _isLoading = false);

      if (userExists && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationCodeScreen(
              phoneNumber: input,
            ),
          ),
        );
      } else if (!userExists && mounted) {
        setState(() {
          _errorMessage = 'No patient account registered with this phone number. Please register first.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  _isStaff ? 'Staff / Admin Sign In' : 'Patient Sign In',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isStaff
                      ? 'Sign in with your hospital staff credentials.'
                      : (_useOtpLogin
                          ? 'Enter your mobile number to receive a secure one-time verification code.'
                          : 'Sign in with your mobile number or email and password.'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // Mode toggle pill
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isStaff = false;
                              _useOtpLogin = false;
                              _errorMessage = null;
                              _phoneOrEmailController.clear();
                              _passwordController.clear();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isStaff ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Patient / Caregiver',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: !_isStaff ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isStaff = true;
                              _useOtpLogin = false;
                              _errorMessage = null;
                              _phoneOrEmailController.clear();
                              _passwordController.clear();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isStaff ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Staff / Admin',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _isStaff ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Error Banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Input Field 1: Phone / Email
                Text(
                  _isStaff ? 'Email Address' : 'Mobile Phone Number or Email',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneOrEmailController,
                  keyboardType: _isStaff ? TextInputType.emailAddress : TextInputType.text,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      _isStaff ? Icons.email_outlined : Icons.person_outline_rounded,
                      color: AppColors.primary,
                    ),
                    hintText: _isStaff ? 'e.g. admin@mediq.lk' : '07X XXX XXXX or email',
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return _isStaff ? 'Please enter your email' : 'Please enter your phone number or email';
                    }
                    if (_isStaff && !value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),

                // Password field (visible whenever not using OTP mode)
                if (!_useOtpLogin) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Password',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      hintText: 'Enter your password',
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (!_useOtpLogin && (value == null || value.trim().isEmpty)) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                ],

                // Action Links Row (OTP Toggle & Forgot Password)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!_isStaff)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _useOtpLogin = !_useOtpLogin;
                              _errorMessage = null;
                            });
                          },
                          child: Text(
                            _useOtpLogin ? 'Use Password Sign In' : 'Sign in with SMS Code',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _useOtpLogin ? 'Send Verification Code' : 'Sign In',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),

                const SizedBox(height: 28),

                // Registration footer (patient only)
                if (!_isStaff)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'First time visiting the OPD? ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegistrationScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Register Here',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
