import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/qr_profile.dart';
import 'vcard_stub.dart' if (dart.library.html) 'vcard_web.dart';

class VCardHelper {
  /// Generates RFC 2426 compliant vCard 3.0 content string
  static String generateVCard(QrProfile profile, [String? specificNumber]) {
    final buffer = StringBuffer();
    buffer.write("BEGIN:VCARD\r\n");
    buffer.write("VERSION:3.0\r\n");

    final name = profile.name.trim().isNotEmpty
        ? profile.name.trim()
        : 'Contact';
    final parts = name.split(' ');
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    buffer.write("N:$lastName;$firstName;;;\r\n");
    buffer.write("FN:$name\r\n");

    if (profile.headline.trim().isNotEmpty) {
      buffer.write("ORG:${profile.headline.trim()}\r\n");
      buffer.write("TITLE:${profile.headline.trim()}\r\n");
    }

    final List<String> contactNumbers = [];
    if (specificNumber != null && specificNumber.trim().isNotEmpty) {
      contactNumbers.add(specificNumber.trim());
    }

    final allPhones = profile.contactList.isNotEmpty
        ? profile.contactList
        : (profile.contactUs.trim().isNotEmpty
              ? [profile.contactUs.trim()]
              : <String>[]);

    for (final p in allPhones) {
      final clean = p.trim();
      if (clean.isNotEmpty && !contactNumbers.contains(clean)) {
        contactNumbers.add(clean);
      }
    }

    for (int i = 0; i < contactNumbers.length; i++) {
      final phone = contactNumbers[i];
      final type = i == 0 ? 'CELL,VOICE' : 'WORK,VOICE';
      buffer.write("TEL;TYPE=$type:$phone\r\n");
    }

    final waNumbers = profile.whatsappList.isNotEmpty
        ? profile.whatsappList
        : (profile.whatsapp.trim().isNotEmpty
              ? [profile.whatsapp.trim()]
              : <String>[]);

    for (int i = 0; i < waNumbers.length; i++) {
      final wa = waNumbers[i].trim();
      if (wa.isNotEmpty && !contactNumbers.contains(wa)) {
        buffer.write("TEL;TYPE=CELL,X-WA:$wa\r\n");
      }
    }

    if (profile.email.trim().isNotEmpty) {
      buffer.write("EMAIL;TYPE=INTERNET:${profile.email.trim()}\r\n");
    }

    if (profile.customLinkUrl.trim().isNotEmpty) {
      buffer.write("URL:${profile.customLinkUrl.trim()}\r\n");
    } else if (profile.googleReview.trim().isNotEmpty) {
      buffer.write("URL:${profile.googleReview.trim()}\r\n");
    }

    buffer.write("END:VCARD\r\n");
    return buffer.toString();
  }

  /// Opens the device's native contact manager / phonebook to save the number directly without file downloads.
  static Future<bool> saveContactToPhoneBook(
    QrProfile profile, [
    String? specificNumber,
  ]) async {
    try {
      final name = profile.name.trim().isNotEmpty
          ? profile.name.trim()
          : 'Contact';
      String phone = '';
      if (specificNumber != null && specificNumber.trim().isNotEmpty) {
        phone = specificNumber.trim();
      } else if (profile.contactList.isNotEmpty) {
        phone = profile.contactList.first.trim();
      } else if (profile.contactUs.trim().isNotEmpty) {
        phone = profile.contactUs.trim();
      } else if (profile.whatsappList.isNotEmpty) {
        phone = profile.whatsappList.first.trim();
      } else if (profile.whatsapp.trim().isNotEmpty) {
        phone = profile.whatsapp.trim();
      }

      if (phone.isEmpty) return false;

      if (kIsWeb) {
        openContactSaveWeb(
          name: name,
          phone: phone,
          organization: profile.headline.trim().isNotEmpty
              ? profile.headline.trim()
              : null,
          email: profile.email.trim().isNotEmpty ? profile.email.trim() : null,
        );
        return true;
      } else {
        final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
        final uri = Uri.parse('tel:$cleanPhone');

        // 1. Attempt direct dialer / call intent launch
        try {
          if (await canLaunchUrl(uri)) {
            final launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            if (launched) return true;
          }
          final launchedFallback = await launchUrl(uri);
          if (launchedFallback) return true;
        } catch (_) {}

        // 2. Fallback for emulators/devices without active dialer: Share vCard
        try {
          final vcardStr = generateVCard(profile, specificNumber);
          final cleanFileName = name
              .replaceAll(RegExp(r'[^\w\s-]'), '_')
              .trim();
          final bytes = Uint8List.fromList(utf8.encode(vcardStr));
          final file = XFile.fromData(
            bytes,
            name: '$cleanFileName.vcf',
            mimeType: 'text/vcard',
          );
          await Share.shareXFiles([file], text: 'Save $name to Contacts');
          return true;
        } catch (e) {
          debugPrint('Error sharing contact card fallback: $e');
        }

        return false;
      }
    } catch (e) {
      debugPrint('Error opening contact to phone book: $e');
      return false;
    }
  }
}
