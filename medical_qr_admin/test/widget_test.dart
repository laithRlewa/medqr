import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medical_qr_admin/main.dart';
import 'package:medical_qr_admin/state/admin_store.dart';

void main() {
  testWidgets('login screen loads', (tester) async {
    await initializeDateFormatting('ar');
    await tester.pumpWidget(
      AdminScope(store: AdminStore(), child: const MedicalQrAdminApp()),
    );
    expect(find.text('مرحباً بعودتك'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
