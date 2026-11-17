import 'package:cureando_mobile/shared/platform/secure_screen_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('el chat activa la protección al entrar y la quita al salir', (
    WidgetTester tester,
  ) async {
    const MethodChannel channel = MethodChannel('test/secure_screen_guard');
    final List<Object?> calls = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      MethodCall call,
    ) async {
      if (call.method == 'setSecureScreen') calls.add(call.arguments);
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SecureScreenGuard(channel: channel, child: Text('Chat')),
      ),
    );
    expect(calls, <Object?>[true]);

    await tester.pumpWidget(const MaterialApp(home: Text('Inicio')));
    expect(calls, <Object?>[true, false]);
  });
}
