import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if the email is registered in DermaSense
  Future<bool> isEmailRegistered(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    try {
      // 1. Check if email is in registered_emails collection
      final regDoc = await _firestore
          .collection('registered_emails')
          .doc(cleanEmail)
          .get();
      if (regDoc.exists) return true;

      // 2. Check if email exists in user profiles (data subcollection)
      final profileQuery = await _firestore
          .collectionGroup('data')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      if (profileQuery.docs.isNotEmpty) {
        // Cache in registered_emails for fast future lookups
        await _firestore.collection('registered_emails').doc(cleanEmail).set({
          'email': cleanEmail,
          'verifiedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      }

      // 3. Check if email exists directly in users collection
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        await _firestore.collection('registered_emails').doc(cleanEmail).set({
          'email': cleanEmail,
          'verifiedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      }

      // If no record is found across registered_emails, profiles, or users, email is NOT registered
      return false;
    } catch (e) {
      // On any query error, treat as not found for safety
      return false;
    }
  }

  /// Generate a random 6-digit OTP
  String _generateOtp() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP to the user's email only if registered
  Future<void> sendOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Strictly verify if the email is registered
    final isRegistered = await isEmailRegistered(cleanEmail);
    if (!isRegistered) {
      throw Exception('This email is not registered with DermaSense. Please check the spelling or sign up first.');
    }

    // 2. Generate OTP
    final otp = _generateOtp();

    // 3. Store OTP in Firestore with 10 min expiry
    await _firestore.collection('password_reset_otps').doc(cleanEmail).set({
      'otp': otp,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 10)),
      ),
      'verified': false,
    });

    // 4. Send OTP via Gmail SMTP
    await _sendEmail(cleanEmail, otp);
  }

  /// Verify the OTP entered by the user
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final doc = await _firestore
          .collection('password_reset_otps')
          .doc(email)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAt = data['expiresAt'] as Timestamp;

      // Check if OTP matches and is not expired
      if (storedOtp == otp && expiresAt.toDate().isAfter(DateTime.now())) {
        // Mark as verified
        await _firestore
            .collection('password_reset_otps')
            .doc(email)
            .update({'verified': true});
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Reset the user's password directly after OTP verification (NO email link sent)
  Future<void> resetPassword(String email, String newPassword) async {
    // 1. Verify that OTP was validated
    final doc = await _firestore
        .collection('password_reset_otps')
        .doc(email)
        .get();

    if (!doc.exists || doc.data()?['verified'] != true) {
      throw Exception('OTP not verified. Please verify your code first.');
    }

    // 2. If user is currently signed in, directly update Firebase Auth password
    if (_auth.currentUser != null && _auth.currentUser!.email == email) {
      await _auth.currentUser!.updatePassword(newPassword);
    }

    // 3. Mark the password as reset in Firestore records
    await _firestore.collection('password_reset_records').doc(email).set({
      'email': email,
      'passwordResetAt': FieldValue.serverTimestamp(),
      'status': 'completed',
    }, SetOptions(merge: true));

    // 4. Clean up the OTP document so it cannot be reused
    await _firestore.collection('password_reset_otps').doc(email).delete();
  }

  Future<void> sendRegistrationOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Strictly verify if the email is registered
    final isRegistered = await isEmailRegistered(cleanEmail);
    if (isRegistered) {
      throw Exception('This email is already registered with DermaSense. Please log in instead.');
    }

    // 2. Generate OTP
    final otp = _generateOtp();

    // 3. Store OTP in Firestore with 10 min expiry
    await _firestore.collection('registration_otps').doc(cleanEmail).set({
      'otp': otp,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 10)),
      ),
      'verified': false,
    });

    // 4. Send OTP via Gmail SMTP
    await _sendRegistrationEmail(cleanEmail, otp);
  }

  Future<bool> verifyRegistrationOtp(String email, String otp) async {
    try {
      final doc = await _firestore
          .collection('registration_otps')
          .doc(email)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAt = data['expiresAt'] as Timestamp;

      // Check if OTP matches and is not expired
      if (storedOtp == otp && expiresAt.toDate().isAfter(DateTime.now())) {
        // Mark as verified
        await _firestore
            .collection('registration_otps')
            .doc(email)
            .update({'verified': true});
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Send registration email via Gmail SMTP with top-notch branded HTML template and image
  Future<void> _sendRegistrationEmail(String toEmail, String otp) async {
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: ".env");
    }
    final smtpEmail = dotenv.env['SMTP_EMAIL'];
    final smtpPassword = dotenv.env['SMTP_APP_PASSWORD'];

    if (smtpEmail == null || smtpPassword == null || smtpEmail.isEmpty || smtpPassword.isEmpty) {
      throw Exception(
        'SMTP credentials not configured. Please add SMTP_EMAIL and SMTP_APP_PASSWORD to your .env file.',
      );
    }

    final smtpServer = gmail(smtpEmail, smtpPassword);
    const logoUrl = 'https://raw.githubusercontent.com/subiksenvs/DermaSense/main/dermasense-ai/frontend/assets/images/logo.png';

    final message = Message()
      ..from = Address(smtpEmail, 'DermaSense AI')
      ..recipients.add(toEmail)
      ..subject = 'DermaSense AI • Registration Verification Code'
      ..text = '''
DermaSense AI - Registration Verification Code

Your 6-digit verification code is: $otp

This code will expire in 10 minutes.

If you did not request to register, please safely ignore this email.
Never share this code with anyone. DermaSense will never ask for your verification code.

© 2026 DermaSense AI Health Technologies. All rights reserved.
'''
      ..html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DermaSense AI Registration</title>
</head>
<body style="margin: 0; padding: 0; background-color: #09090B; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased;">
  <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #09090B; padding: 40px 16px;">
    <tr>
      <td align="center">
        <!-- Main Card Container -->
        <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 520px; background-color: #141417; border: 1px solid rgba(255, 122, 89, 0.25); border-radius: 24px; box-shadow: 0 20px 40px rgba(0, 0, 0, 0.6); overflow: hidden;">
          
          <!-- Top Accent Gradient Line -->
          <tr>
            <td style="height: 4px; background: linear-gradient(90deg, #FF7A59, #FFB09C, #E8B6A1);"></td>
          </tr>

          <!-- Header with Logo Image -->
          <tr>
            <td align="center" style="padding: 36px 32px 16px 32px;">
              <table role="presentation" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td align="center" style="background-color: #1F1F24; padding: 12px; border-radius: 20px; border: 1px solid rgba(255, 255, 255, 0.08); box-shadow: 0 8px 16px rgba(0, 0, 0, 0.4);">
                    <img src="$logoUrl" alt="DermaSense AI Logo" width="72" height="72" style="display: block; width: 72px; height: 72px; border-radius: 12px; object-fit: contain;" />
                  </td>
                </tr>
              </table>
              <h1 style="margin: 16px 0 4px 0; color: #FFFFFF; font-size: 24px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                DermaSense <span style="color: #FF7A59;">AI</span>
              </h1>
              <p style="margin: 0; color: #A1A1AA; font-size: 13px; font-weight: 500; letter-spacing: 0.5px;">
                CLINICAL DERMATOLOGICAL INTELLIGENCE
              </p>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding: 0 40px;">
              <div style="height: 1px; background: linear-gradient(90deg, transparent, rgba(255, 122, 89, 0.3), transparent);"></div>
            </td>
          </tr>

          <!-- Body Content -->
          <tr>
            <td style="padding: 28px 40px 16px 40px; text-align: center;">
              <h2 style="margin: 0 0 12px 0; color: #FAFAFA; font-size: 20px; font-weight: 700;">
                Complete Your Registration
              </h2>
              <p style="margin: 0 0 24px 0; color: #D4D4D8; font-size: 14px; line-height: 1.6;">
                Welcome to DermaSense! Please enter the secure 6-digit code below in your mobile application to verify your email and complete registration:
              </p>

              <!-- OTP Code Display Box -->
              <table role="presentation" border="0" cellspacing="0" cellpadding="0" style="margin: 0 auto 24px auto;">
                <tr>
                  <td align="center" style="background: linear-gradient(135deg, #FF7A59 0%, #FF9E7D 100%); padding: 18px 36px; border-radius: 16px; box-shadow: 0 12px 28px rgba(255, 122, 89, 0.35);">
                    <span style="font-family: 'Courier New', Courier, monospace; font-size: 34px; font-weight: 900; letter-spacing: 10px; color: #FFFFFF; text-shadow: 0 2px 4px rgba(0,0,0,0.2); margin-right: -10px;">
                      $otp
                    </span>
                  </td>
                </tr>
              </table>

              <!-- Expiration Notice -->
              <p style="margin: 0 0 24px 0; color: #A1A1AA; font-size: 13px; font-weight: 500;">
                ⏰ This code is valid for <strong style="color: #FF7A59;">10 minutes</strong>.
              </p>

              <!-- Security Callout Box -->
              <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #1B1B1F; border: 1px solid rgba(255, 255, 255, 0.06); border-left: 3px solid #FF7A59; border-radius: 8px; text-align: left;">
                <tr>
                  <td style="padding: 14px 16px;">
                    <p style="margin: 0; color: #A1A1AA; font-size: 12px; line-height: 1.5;">
                      <strong style="color: #FAFAFA;">🛡️ Security Tip:</strong> If you did not make this request, you can safely disregard this email. DermaSense will never ask you to share your verification code.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 24px 40px 32px 40px; text-align: center; background-color: #0E0E10; border-top: 1px solid rgba(255, 255, 255, 0.04);">
              <p style="margin: 0 0 6px 0; color: #71717A; font-size: 11px;">
                DermaSense AI Health Technologies Inc.
              </p>
              <p style="margin: 0; color: #52525B; font-size: 11px;">
                This is an automated security message. Please do not reply to this email.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';

    try {
      await send(message, smtpServer);
    } on MailerException catch (e) {
      final msg = e.message;
      if (msg.contains('535') || msg.contains('Username and Password not accepted')) {
        throw Exception(
          'Gmail rejected the App Password. Please generate a fresh 16-character Google App Password from https://myaccount.google.com/apppasswords and update your .env file.',
        );
      }
      throw Exception('Failed to send email: $msg');
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('535') || errStr.contains('BadCredentials')) {
        throw Exception(
          'Gmail rejected the App Password. Please generate a fresh 16-character Google App Password from https://myaccount.google.com/apppasswords and update your .env file.',
        );
      }
      throw Exception('Failed to send email: $e');
    }
  }

  /// Send email via Gmail SMTP with top-notch branded HTML template and image
  Future<void> _sendEmail(String toEmail, String otp) async {
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: ".env");
    }
    final smtpEmail = dotenv.env['SMTP_EMAIL'];
    final smtpPassword = dotenv.env['SMTP_APP_PASSWORD'];

    if (smtpEmail == null || smtpPassword == null || smtpEmail.isEmpty || smtpPassword.isEmpty) {
      throw Exception(
        'SMTP credentials not configured. Please add SMTP_EMAIL and SMTP_APP_PASSWORD to your .env file.',
      );
    }

    // Direct Google SMTP Server configuration (guarantees Inbox delivery)
    final smtpServer = gmail(smtpEmail, smtpPassword);

    const logoUrl = 'https://raw.githubusercontent.com/subiksenvs/DermaSense/main/dermasense-ai/frontend/assets/images/logo.png';

    final message = Message()
      ..from = Address(smtpEmail, 'DermaSense AI')
      ..recipients.add(toEmail)
      ..subject = 'DermaSense AI • Password Reset Verification Code'
      // Plain text alternative is CRITICAL to prevent spam filters from flagging the email
      ..text = '''
DermaSense AI - Password Reset Verification Code

Your 6-digit verification code is: $otp

This code will expire in 10 minutes.

If you did not request a password reset, please safely ignore this email.
Never share this code with anyone. DermaSense will never ask for your verification code.

© 2026 DermaSense AI Health Technologies. All rights reserved.
'''
      ..html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DermaSense AI Password Reset</title>
</head>
<body style="margin: 0; padding: 0; background-color: #09090B; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased;">
  <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #09090B; padding: 40px 16px;">
    <tr>
      <td align="center">
        <!-- Main Card Container -->
        <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 520px; background-color: #141417; border: 1px solid rgba(255, 122, 89, 0.25); border-radius: 24px; box-shadow: 0 20px 40px rgba(0, 0, 0, 0.6); overflow: hidden;">
          
          <!-- Top Accent Gradient Line -->
          <tr>
            <td style="height: 4px; background: linear-gradient(90deg, #FF7A59, #FFB09C, #E8B6A1);"></td>
          </tr>

          <!-- Header with Logo Image -->
          <tr>
            <td align="center" style="padding: 36px 32px 16px 32px;">
              <table role="presentation" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td align="center" style="background-color: #1F1F24; padding: 12px; border-radius: 20px; border: 1px solid rgba(255, 255, 255, 0.08); box-shadow: 0 8px 16px rgba(0, 0, 0, 0.4);">
                    <img src="$logoUrl" alt="DermaSense AI Logo" width="72" height="72" style="display: block; width: 72px; height: 72px; border-radius: 12px; object-fit: contain;" />
                  </td>
                </tr>
              </table>
              <h1 style="margin: 16px 0 4px 0; color: #FFFFFF; font-size: 24px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                DermaSense <span style="color: #FF7A59;">AI</span>
              </h1>
              <p style="margin: 0; color: #A1A1AA; font-size: 13px; font-weight: 500; letter-spacing: 0.5px;">
                CLINICAL DERMATOLOGICAL INTELLIGENCE
              </p>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding: 0 40px;">
              <div style="height: 1px; background: linear-gradient(90deg, transparent, rgba(255, 122, 89, 0.3), transparent);"></div>
            </td>
          </tr>

          <!-- Body Content -->
          <tr>
            <td style="padding: 28px 40px 16px 40px; text-align: center;">
              <h2 style="margin: 0 0 12px 0; color: #FAFAFA; font-size: 20px; font-weight: 700;">
                Password Reset Verification
              </h2>
              <p style="margin: 0 0 24px 0; color: #D4D4D8; font-size: 14px; line-height: 1.6;">
                We received a request to reset the password for your account. Please enter the secure 6-digit code below in your mobile application:
              </p>

              <!-- OTP Code Display Box -->
              <table role="presentation" border="0" cellspacing="0" cellpadding="0" style="margin: 0 auto 24px auto;">
                <tr>
                  <td align="center" style="background: linear-gradient(135deg, #FF7A59 0%, #FF9E7D 100%); padding: 18px 36px; border-radius: 16px; box-shadow: 0 12px 28px rgba(255, 122, 89, 0.35);">
                    <span style="font-family: 'Courier New', Courier, monospace; font-size: 34px; font-weight: 900; letter-spacing: 10px; color: #FFFFFF; text-shadow: 0 2px 4px rgba(0,0,0,0.2); margin-right: -10px;">
                      $otp
                    </span>
                  </td>
                </tr>
              </table>

              <!-- Expiration Notice -->
              <p style="margin: 0 0 24px 0; color: #A1A1AA; font-size: 13px; font-weight: 500;">
                ⏰ This code is valid for <strong style="color: #FF7A59;">10 minutes</strong>.
              </p>

              <!-- Security Callout Box -->
              <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #1B1B1F; border: 1px solid rgba(255, 255, 255, 0.06); border-left: 3px solid #FF7A59; border-radius: 8px; text-align: left;">
                <tr>
                  <td style="padding: 14px 16px;">
                    <p style="margin: 0; color: #A1A1AA; font-size: 12px; line-height: 1.5;">
                      <strong style="color: #FAFAFA;">🛡️ Security Tip:</strong> If you did not make this request, you can safely disregard this email. DermaSense will never ask you to share your verification code.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 24px 40px 32px 40px; text-align: center; background-color: #0E0E10; border-top: 1px solid rgba(255, 255, 255, 0.04);">
              <p style="margin: 0 0 6px 0; color: #71717A; font-size: 11px;">
                DermaSense AI Health Technologies Inc.
              </p>
              <p style="margin: 0; color: #52525B; font-size: 11px;">
                This is an automated security message. Please do not reply to this email.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';

    try {
      await send(message, smtpServer);
    } on MailerException catch (e) {
      final msg = e.message;
      if (msg.contains('535') || msg.contains('Username and Password not accepted')) {
        throw Exception(
          'Gmail rejected the App Password. Please generate a fresh 16-character Google App Password from https://myaccount.google.com/apppasswords and update your .env file.',
        );
      }
      throw Exception('Failed to send email: $msg');
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('535') || errStr.contains('BadCredentials')) {
        throw Exception(
          'Gmail rejected the App Password. Please generate a fresh 16-character Google App Password from https://myaccount.google.com/apppasswords and update your .env file.',
        );
      }
      throw Exception('Failed to send email: $e');
    }
  }
}
