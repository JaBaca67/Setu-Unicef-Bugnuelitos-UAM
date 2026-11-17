import 'package:cureando_mobile/features/home/help_contacts.dart';
import 'package:cureando_mobile/features/home/trusted_contacts.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements LocalStorePersistence {
  Map<String, Object?>? value;

  @override
  Future<Map<String, Object?>?> load() async => value;

  @override
  Future<void> save(Map<String, Object?> next) async => value = next;
}

void main() {
  test('normaliza números y nombres de confianza', () {
    expect(TrustedContacts.normalizeNumber(' 8888-1234 '), '88881234');
    expect(TrustedContacts.normalizeNumber('+505 8888 1234'), '+50588881234');
    expect(TrustedContacts.normalizeNumber('12'), isNull);
    expect(TrustedContacts.normalizeName('  Mamá '), 'Mamá');
    expect(TrustedContacts.normalizeName('   '), isNull);
  });

  test('guarda, recupera y borra números en el almacén local', () async {
    final _MemoryStore store = _MemoryStore();
    final TrustedContacts contacts = TrustedContacts(
      openStore: () async => store,
    );
    await contacts.open();
    expect(await contacts.add(name: 'Tía', number: '8888 0000'), isNull);
    expect(await contacts.add(name: '', number: '8888 0000'), isNotNull);
    expect(store.value?['version'], 1);

    final TrustedContacts reopened = TrustedContacts(
      openStore: () async => store,
    );
    await reopened.open();
    expect(reopened.contacts.single.name, 'Tía');
    expect(reopened.contacts.single.number, '88880000');

    await reopened.removeAt(0);
    expect(reopened.contacts, isEmpty);
  });

  test('limita la cantidad de números', () async {
    final TrustedContacts contacts = TrustedContacts(
      openStore: () async => _MemoryStore(),
    );
    await contacts.open();
    for (int i = 0; i < TrustedContacts.maxContacts; i++) {
      expect(
        await contacts.add(name: 'Persona $i', number: '8888000$i'),
        isNull,
      );
    }
    expect(contacts.isFull, isTrue);
    expect(await contacts.add(name: 'Extra', number: '88889999'), isNotNull);
  });

  testWidgets('Ayuda muestra contactos verificados y permite anotar uno', (
    WidgetTester tester,
  ) async {
    final TrustedContacts contacts = TrustedContacts(
      openStore: () async => _MemoryStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const EmergencyContactsCard(),
                TrustedContactsSection(contacts: contacts),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('118'), findsOneWidget);
    expect(find.text('133'), findsOneWidget);
    expect(find.text('Ministerio de la Familia'), findsOneWidget);
    expect(find.textContaining('Atiende las 24 horas'), findsNothing);
    await tester.tap(find.text('¿Cuándo llamar?').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Atiende las 24 horas'), findsOneWidget);
    expect(find.textContaining('Fuente: MINED Nicaragua'), findsOneWidget);

    await tester.tap(find.text('Agregar contacto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('trusted-name-field')), 'Mamá');
    await tester.enterText(
      find.byKey(const Key('trusted-number-field')),
      '8888 1234',
    );
    await tester.enterText(
      find.byKey(const Key('trusted-note-field')),
      'Cuando me siento triste',
    );
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'), warnIfMissed: true);
    await tester.pumpAndSettle();
    expect(find.text('Mamá'), findsOneWidget);
    expect(find.text('88881234'), findsOneWidget);
    expect(find.text('Cuando me siento triste'), findsNothing);
    await tester.ensureVisible(find.text('¿Para qué?'));
    await tester.tap(find.text('¿Para qué?'));
    await tester.pumpAndSettle();
    expect(find.text('Cuando me siento triste'), findsOneWidget);
    expect(contacts.contacts.single.note, 'Cuando me siento triste');
  });

  testWidgets('las preguntas frecuentes se abren en la misma pantalla', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: HelpFaqSection())),
      ),
    );
    expect(find.textContaining('personal autorizado'), findsNothing);
    await tester.tap(find.text('¿Quién puede leer mi alerta?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('personal autorizado'), findsOneWidget);
  });
}
