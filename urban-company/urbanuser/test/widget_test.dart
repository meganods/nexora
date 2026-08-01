import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:urbanuser/main.dart';
import 'package:urbanuser/services/app_infra_service.dart';

void main() {
  testWidgets('Nexora user app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NexoraApp());
    await tester.pump();

    // Verify that the provider and consumer are laid out
    expect(find.byType(ChangeNotifierProvider<AppInfraService>), findsOneWidget);
  });
}
