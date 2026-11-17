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
    required this.icon,
  });

  final String name;
  final String number;
  final String detail;
  final IconData icon;
}

/// Líneas oficiales verificadas el 16-nov-2026 en la cartilla «Mujer,
/// Dignidad y Derechos» del MINED (p. 29). MINSA y UNICEF no se publican
/// hasta que el equipo confirme una línea oficial de atención.
const List<HelpContact> verifiedHelpContacts = <HelpContact>[
  HelpContact(
    name: 'Policía Nacional',
    number: '118',
    detail: 'Si hay peligro o una agresión',
    icon: Icons.local_police_rounded,
  ),
  HelpContact(
    name: 'Ministerio de la Familia',
    number: '133',
    detail: 'Orientación y acompañamiento',
    icon: Icons.groups_rounded,
  ),
];

const String helpContactsSource =
    'Fuente: MINED Nicaragua, cartilla «Mujer, Dignidad y Derechos» '
    '(118 para denunciar; 133 para orientación y acompañamiento). '
    'Territorio: Nicaragua. Verificado: 16 de noviembre de 2026. '
    'Responsable editorial: equipo SéTú (Bugñuelitos, UAM).';

const Color _cardBorder = Color(0xFFD6E2F5);

BoxDecoration _helpCardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(22),
  border: Border.all(color: _cardBorder, width: 1.5),
  boxShadow: const <BoxShadow>[
    BoxShadow(color: Color(0x140C62EB), blurRadius: 14, offset: Offset(0, 4)),
  ],
);

/// Título de sección de la pestaña Ayuda.
class HelpSectionTitle extends StatelessWidget {
  const HelpSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(
          color: CureandoTheme.ink,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    ),
  );
}

class _IconColumn extends StatelessWidget {
  const _IconColumn(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 56,
    child: Icon(icon, color: CureandoTheme.blue, size: 36),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1.5,
    height: 52,
    margin: const EdgeInsets.only(right: 12),
    color: _cardBorder,
  );
}

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

/// «Líneas de ayuda»: contactos oficiales verificados con botón Llamar.
class EmergencyContactsCard extends StatelessWidget {
  const EmergencyContactsCard({super.key});

  Widget _row(BuildContext context, HelpContact contact) {
    final Widget info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          contact.number,
          style: const TextStyle(
            color: CureandoTheme.ink,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        Text(
          contact.name,
          style: const TextStyle(
            color: CureandoTheme.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    final Widget call = FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: CureandoTheme.blue,
        minimumSize: const Size(84, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      onPressed: () => _dial(context, contact.number),
      child: Text(
        'Llamar',
        semanticsLabel: 'Llamar a ${contact.name}, ${contact.number}',
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Con pantalla angosta o texto grande el botón baja bajo el texto.
          final bool compact =
              constraints.maxWidth < 320 ||
              MediaQuery.textScalerOf(context).scale(10) > 13;
          final Widget head = Row(
            children: <Widget>[
              _IconColumn(contact.icon),
              const _Divider(),
              Expanded(child: info),
              if (!compact) ...<Widget>[const SizedBox(width: 8), call],
            ],
          );
          if (!compact) return head;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[head, const SizedBox(height: 10), call],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('emergency-contacts-card'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const HelpSectionTitle('Líneas de ayuda'),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: _helpCardDecoration(),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < verifiedHelpContacts.length; i++) ...<Widget>[
              if (i > 0) const Divider(height: 1, color: _cardBorder),
              _row(context, verifiedHelpContacts[i]),
            ],
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        helpContactsSource,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
      ),
    ],
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
    builder: (BuildContext context, _) => Column(
      key: const Key('trusted-contacts-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const HelpSectionTitle('Mis contactos de confianza'),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: _helpCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const _IconColumn(Icons.person_rounded),
                  const _Divider(),
                  Expanded(
                    child: Text(
                      !_contacts.ready
                          ? 'Abriendo tus números…'
                          : _contacts.failed
                          ? 'No se pudieron abrir tus números en este teléfono.'
                          : 'Guardá el número de alguien de confianza.',
                      style: const TextStyle(
                        color: CureandoTheme.ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (_contacts.ready && !_contacts.failed) ...<Widget>[
                for (int i = 0; i < _contacts.contacts.length; i++) ...<Widget>[
                  const Divider(height: 22, color: _cardBorder),
                  _row(i),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: CureandoTheme.blue, width: 2),
                    foregroundColor: CureandoTheme.blue,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                  ),
                  onPressed: _contacts.isFull ? null : _showAddSheet,
                  child: Text(
                    _contacts.isFull
                        ? 'Máximo ${TrustedContacts.maxContacts} contactos'
                        : 'Agregar contacto',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// «Preguntas frecuentes» de la pestaña Ayuda; se abren en la misma pantalla.
class HelpFaqSection extends StatelessWidget {
  const HelpFaqSection({super.key});

  static const List<(String, String)> faqs = <(String, String)>[
    (
      '¿Quién puede leer mi alerta?',
      'El personal autorizado de la Mesa de Escucha puede leer lo que '
          'compartiste para atender tu caso.',
    ),
    (
      '¿Qué pasa después de enviar una alerta?',
      'SéTú te muestra si se confirmó la entrega. Si alguien de la Mesa de '
          'Escucha habilita el chat, vas a recibir un aviso.',
    ),
    (
      '¿Qué puedo hacer sin internet?',
      'Podés consultar las líneas de ayuda y tus contactos guardados. Para '
          'llamar necesitás señal telefónica y para usar el chat necesitás '
          'internet.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('help-faq-section'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const HelpSectionTitle('Preguntas frecuentes'),
      Container(
        decoration: _helpCardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < faqs.length; i++) ...<Widget>[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: _cardBorder,
                    ),
                  ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 18),
                    childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    iconColor: CureandoTheme.blue,
                    collapsedIconColor: CureandoTheme.blue,
                    expandedAlignment: Alignment.centerLeft,
                    title: Text(
                      faqs[i].$1,
                      style: const TextStyle(
                        color: CureandoTheme.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                    children: <Widget>[Text(faqs[i].$2)],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
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
