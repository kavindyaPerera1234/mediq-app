import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isRegistration;

  const VerificationCodeScreen({
    super.key,
    required this.phoneNumber,
    this.isRegistration = false,
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  static const int _otpLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  int _resendCountdown = 60;
  Timer? _timer;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _verificationId;
  int? _resendToken;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sendRealSmsCode();
  }

  void _startTimer() {
    _timer?.cancel();
    _resendCountdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendRealSmsCode({bool isResend = false}) async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
      _statusMessage = 'Requesting SMS code via Firebase...';
    });
    _startTimer();

    try {
      await AuthService().sendPhoneVerification(
        phoneNumber: widget.phoneNumber,
        resendToken: isResend ? _resendToken : null,
        onCodeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isSending = false;
            _statusMessage = 'SMS verification code sent to your phone.';
          });
        },
        onVerificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _isSending = false;
            _errorMessage = _friendlyPhoneError(e);
            _statusMessage = null;
          });
        },
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;
          if (credential.smsCode != null && credential.smsCode!.length == _otpLength) {
            for (var i = 0; i < _otpLength; i++) {
              _controllers[i].text = credential.smsCode![i];
            }
          }
          _handleVerify();
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = 'Could not send SMS: $e';
      });
    }
  }

  String _friendlyPhoneError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number format is invalid. Please use +94XXXXXXXXX.';
      case 'too-many-requests':
        return 'Too many SMS requests sent. Please try again in a few minutes.';
      case 'quota-exceeded':
        return 'SMS daily quota reached for this Firebase project.';
      case 'operation-not-allowed':
        return 'Phone sign-in is not enabled in Firebase Console yet. Please enable Phone under Sign-in method.';
      default:
        return e.message ?? 'SMS sending failed. Code: ${e.code}';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredCode =>
      _controllers.map((c) => c.text.trim()).join();

  Future<void> _handleVerify() async {
    final code = _enteredCode;
    if (code.length < _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits of the SMS verification code.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      if (_verificationId != null) {
        await AuthService().verifyPhoneOtp(
          verificationId: _verificationId!,
          smsCode: code,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (!mounted) return;
      setState(() => _isVerifying = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number verified successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      AuthService().routeUserByRole(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = e.code == 'invalid-verification-code'
            ? 'Invalid 6-digit code. Please check your SMS and try again.'
            : (e.message ?? 'Verification failed: ${e.code}');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Verification error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedPhone = AuthService.formatToE164(widget.phoneNumber);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Verification Code',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit SMS verification code to '),
                    TextSpan(
                      text: formattedPhone,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const TextSpan(text: '. Please enter it below:'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      if (_isSending)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      else
                        const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF991B1B), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_otpLength, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < _otpLength - 1) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (_enteredCode.length == _otpLength) {
                          _handleVerify();
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isVerifying ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Verify & Proceed',
                        style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
              ),

              const SizedBox(height: 20),

              Center(
                child: _resendCountdown > 0
                    ? Text(
                        'Resend code in $_resendCountdown seconds',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : TextButton.icon(
                        onPressed: _isSending ? null : () => _sendRealSmsCode(isResend: true),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          'Resend Code via SMS',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Phone verification protects your OPD booking history and live queue notifications.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
