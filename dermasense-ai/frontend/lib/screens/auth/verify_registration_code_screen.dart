import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import '../../providers/auth_provider.dart';
import '../../providers/skin_profile_provider.dart';
import '../../services/otp_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ds/ds_toast.dart';
import '../home/app_shell.dart';

class VerifyRegistrationCodeScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String password;
  final String? age;
  final String? skinType;

  const VerifyRegistrationCodeScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.password,
    this.age,
    this.skinType,
  });

  @override
  State<VerifyRegistrationCodeScreen> createState() => _VerifyRegistrationCodeScreenState();
}

class _VerifyRegistrationCodeScreenState extends State<VerifyRegistrationCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _otpService = OtpService();

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getCode() {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _verifyCodeAndRegister() async {
    final code = _getCode();
    if (code.length != 6) {
      setState(() {
        _errorText = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      final isValid = await _otpService.verifyRegistrationOtp(widget.email, code);

      if (!isValid) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorText = 'Invalid or expired code. Please try again.';
          });
        }
        return;
      }

      // Code is valid, proceed with registration
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final registeredEmail = widget.email.trim().toLowerCase();
      
      await authProvider.register(
        widget.email.trim(),
        widget.password.trim(),
      );

      // Record in registered_emails collection for verified password reset and general lookup
      try {
        await FirebaseFirestore.instance
            .collection('registered_emails')
            .doc(registeredEmail)
            .set({
          'email': registeredEmail,
          'registeredAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (mounted) {
        final profileProvider = context.read<SkinProfileProvider>();
        final p = profileProvider.profile.copyWith(
          fullName: widget.fullName.trim(),
          email: widget.email.trim(),
          age: widget.age != null ? int.tryParse(widget.age!.trim()) : null,
          skinType: widget.skinType,
        );
        await profileProvider.updateProfile(p);

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AppShell()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Registration failed';
        if (e.code == 'email-already-in-use') {
          message = 'An account already exists for that email.';
        } else if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is badly formatted.';
        } else {
          message = e.message ?? 'An error occurred during registration.';
        }
        DSToast.showError(context, message);
      }
    } catch (e) {
      if (mounted) {
        DSToast.showError(context, 'An unexpected error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    try {
      await _otpService.sendRegistrationOtp(widget.email);
      if (mounted) {
        setState(() => _isResending = false);
        DSToast.showSuccess(context, 'New code sent to your email!');
        // Clear the boxes
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        DSToast.showError(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  void _onChanged(String value, int index) {
    if (_errorText != null) {
      setState(() => _errorText = null);
    }

    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  "Verify Email",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter the 6-digit verification code sent to ${widget.email}.",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) => _onKeyEvent(index, event),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          cursorColor: AppTheme.primary,
                          cursorHeight: 20,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: "",
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.03),
                            hoverColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                          ),
                          onChanged: (value) => _onChanged(value, index),
                        ),
                      ),
                    );
                  }),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorText!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: _isResending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: _resendCode,
                          child: const Text("Didn't receive the code? Resend"),
                        ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    onPressed: _isLoading ? null : _verifyCodeAndRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Verify & Register", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
