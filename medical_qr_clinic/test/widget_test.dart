import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medical_qr_clinic/main.dart';
import 'package:medical_qr_clinic/state/clinic_store.dart';

void main() {
  testWidgets('login screen appears', (tester) async {
    await initializeDateFormatting('ar');
    await tester.pumpWidget(ClinicScope(store: ClinicStore(), child: const MedicalQrClinicApp()));
    expect(find.text('مرحباً بعودتك'), findsOneWidget);
  });
}
