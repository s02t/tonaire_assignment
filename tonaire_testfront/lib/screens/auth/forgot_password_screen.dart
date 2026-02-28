import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;
  bool _otpSent = false;
  bool _obscure = true;

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Email is required');
      return;
    }

    setState(() { _loading = true; _error = null; _success = null; });
    final result = await ApiService.forgotPassword(email);
    setState(() { _loading = false; });

    if (result['success']) {
      setState(() {
        _otpSent = true;
        _success = 'OTP sent to your email';
      });
    } else {
      setState(() => _error = result['error']);
    }
  }

  Future<void> _resetPassword() async {
    if (_otpCtrl.text.isEmpty || _newPasswordCtrl.text.isEmpty) {
      setState(() => _error = 'OTP and new password are required');
      return;
    }
    if (_newPasswordCtrl.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final result = await ApiService.verifyOtp(
      _emailCtrl.text.trim(),
      _otpCtrl.text.trim(),
      _newPasswordCtrl.text,
    );
    setState(() { _loading = false; });

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully!'),
            backgroundColor: AppTheme.secondary,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() => _error = result['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.lock_reset, size: 64, color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(
              _otpSent ? 'Enter OTP & New Password' : 'Reset Your Password',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _otpSent
                  ? 'Enter the OTP sent to ${_emailCtrl.text}'
                  : 'Enter your email to receive a reset OTP',
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!, style: const TextStyle(color: AppTheme.error)),
              ),

            if (_success != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_success!, style: const TextStyle(color: AppTheme.secondary)),
              ),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              enabled: !_otpSent,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 16),

            if (_otpSent) ...[
              TextFormField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'OTP Code', prefixIcon: Icon(Icons.pin_outlined)),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _newPasswordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loading ? null : _resetPassword,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Reset Password'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() { _otpSent = false; _success = null; _error = null; }),
                child: const Text('Resend OTP'),
              ),
            ] else
              ElevatedButton(
                onPressed: _loading ? null : _sendOtp,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send OTP'),
              ),
          ],
        ),
      ),
    );
  }
}
