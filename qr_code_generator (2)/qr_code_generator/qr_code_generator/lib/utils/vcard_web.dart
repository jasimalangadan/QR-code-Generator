// Web implementation to open native device contact/phonebook directly without file downloads.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

void openContactSaveWeb({
  required String name,
  required String phone,
  String? organization,
  String? email,
}) {
  final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final String targetUrl = 'tel:$cleanPhone';

  try {
    // Create and click DOM anchor for highest browser compatibility
    final anchor = html.AnchorElement(href: targetUrl)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
  } catch (_) {
    html.window.location.href = targetUrl;
  }
}
