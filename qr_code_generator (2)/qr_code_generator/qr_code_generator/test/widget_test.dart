import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_generator/main.dart';
import 'package:qr_code_generator/providers/qr_provider.dart';
import 'package:qr_code_generator/repositories/qr_repository.dart';

void main() {
  testWidgets('QR Code Generator basic rendering test', (WidgetTester tester) async {
    // Use LocalQrRepository for testing to avoid any Firebase/network dependencies
    final QrRepository qrRepository = LocalQrRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => QrProvider(repository: qrRepository),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the title 'QR Makers' is displayed on the generator screen
    expect(find.text('QR Makers'), findsOneWidget);

    // Verify that the expandable cards are rendered
    expect(find.text('Theme Color'), findsOneWidget);
    expect(find.text('Basic Information'), findsOneWidget);
  });
}
