import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/theme/app_theme.dart';
import 'trusted_contacts.dart';

/// Contacto de ayuda publicado solo si tiene fuente, territorio, fecha de
/// verificación y responsable editorial (AGENTS.md, ADR 0025).
class HelpContact {
  const HelpContact({
    required this.name,
    required this.number,
    required this.detail,
  });

  final String name;
  final String number;
  final String detail;
}

/// Contactos verificados el 16-nov-2026. MINSA y UNICEF no se publican hasta
/// que el equipo confirme una línea oficial de atención.
const List<HelpContact> verifiedHelpContacts = <HelpContact>[
  HelpContact(
    name: 'Policía Nacional',
    number: '118',
    detail: 'Emergencias · 24 horas',
  ),
  HelpContact(
    name: 'Asistencia médica de emergencia',
    number: '128',
    detail: 'Emergencias médicas',
  ),
];

const String helpContactsSource =
    'Fuente: Policía Nacional de Nicaragua (línea 118) y guía oficial de '
    'viaje del Gobierno de Canadá para Nicaragua (118 y 128). Territorio: '
    'Nicaragua. Verificado: 16 de noviembre de 2026. Responsable editorial: '
    'equipo SéTú (Bugñuelitos, UAM). Otras líneas, como MINSA, se agregan '
    'cuando estén verificadas.';

const MethodChannel _dialer = MethodChannel('dev.cureando.app/dialer');

Future<void> _dial(BuildContext context, String number) async {
  try {
    await _dialer.invokeMethod<void>('dial', <String, String>{
      'number': number,
    });
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('Marcá $number desde tu teléfono.')),
    );
  }
}

/// Tarjeta «Si estás en peligro ahora» con los contactos verificados.
class EmergencyContactsCard extends StatelessWidget {
  const EmergencyContactsCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('emergency-contacts-card'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFFFC2E2), width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Si estás en peligro ahora',
          style: TextStyle(
            color: CureandoTheme.ink,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Llamar es gratis. Podés pedirle a una persona adulta de confianza '
          'que te acompañe.',
        ),
        for (final HelpContact contact in verifiedHelpContacts) ...<Widget>[
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${contact.name} · ${contact.number}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: CureandoTheme.ink,
                      ),
                    ),
                    Text(contact.detail),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0092),
                  minimumSize: const Size(48, 48),
                ),
                onPressed: () => _dial(context, contact.number),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: Text(
                  'Llamar',
                  semanticsLabel: 'Llamar a ${contact.name}, ${contact.number}',
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Text(helpContactsSource, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

/// «Mis números de confianza»: el estudiante anota números propios (familia,
/// persona adulta de confianza) para llamar rápido. Cifrados en el teléfono.
class TrustedContactsSection extends StatefulWidget {
  const TrustedContactsSection({super.key, this.contacts});

  /// Se inyecta en pruebas; si es nulo se abre el almacén del dispositivo.
  final TrustedContacts? contacts;

  @override
  State<TrustedContactsSection> createState() => _TrustedContactsSectionState();
}

class _TrustedContactsSectionState extends State<TrustedContactsSection> {
  late final TrustedContacts _contacts = widget.contacts ?? TrustedContacts();

  @override
  void initState() {
    super.initState();
    if (!_contacts.ready) unawaited(_contacts.open());
  }

  @override
  void dispose() {
    if (widget.contacts == null) _contacts.dispose();
    super.dispose();
  }

  Future<void> _showAddSheet() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) =>
        _AddTrustedContactSheet(contacts: _contacts),
  );

  Widget _row(int i) {
    final TrustedContact contact = _contacts.contacts[i];
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                contact.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: CureandoTheme.ink,
                ),
              ),
              Text(contact.number),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Borrar ${contact.name}',
          onPressed: () => _contacts.removeAt(i),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => _dial(context, contact.number),
          icon: const Icon(Icons.call_rounded, size: 18),
          label: Text('Llamar', semanticsLabel: 'Llamar a ${contact.name}'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _contacts,
    builder: (BuildContext context, _) => Container(
      key: const Key('trusted-contacts-section'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Mis números de confianza',
            style: TextStyle(
              color: CureandoTheme.ink,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Anotá números de personas que te ayudan, para tenerlos a mano. '
            'Quedan guardados solo en este teléfono.',
          ),
          if (!_contacts.ready)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Abriendo tus números…'),
            )
          else if (_contacts.failed)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('No se pudieron abrir tus números en este teléfono.'),
            )
          else ...<Widget>[
            for (int i = 0; i < _contacts.contacts.length; i++) ...<Widget>[
              const SizedBox(height: 12),
              _row(i),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _contacts.isFull ? null : _showAddSheet,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                _contacts.isFull
                    ? 'Máximo ${TrustedContacts.maxContacts} números'
                    : 'Agregar número',
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Hoja para anotar un número; es dueña de sus campos para liberarlos recién
/// cuando termina la animación de cierre.
class _AddTrustedContactSheet extends StatefulWidget {
  const _AddTrustedContactSheet({required this.contacts});

  final TrustedContacts contacts;

  @override
  State<_AddTrustedContactSheet> createState() =>
      _AddTrustedContactSheetState();
}

class _AddTrustedContactSheetState extends State<_AddTrustedContactSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _number = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final String? result = await widget.contacts.add(
      name: _name.text,
      number: _number.text,
    );
    if (!mounted) return;
    if (result == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _error = result;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      20 +
          MediaQuery.viewInsetsOf(context).bottom +
          MediaQuery.viewPaddingOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Agregar número de confianza',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Se guarda solo en este teléfono. SéTú no lo envía a nadie.',
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('trusted-name-field'),
          controller: _name,
          maxLength: TrustedContacts.maxNameLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: '¿Quién es?',
            hintText: 'Ej.: Mamá, Tía, Profe de confianza',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('trusted-number-field'),
          controller: _number,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Número'),
        ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Color(0xFFB00063))),
        ],
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _saving ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
