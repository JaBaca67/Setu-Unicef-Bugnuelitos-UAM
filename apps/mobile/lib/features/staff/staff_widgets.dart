import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/remote/setu_remote_models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import '../../shared/widgets/flow_scaffold.dart';
import 'staff_backend.dart';

/// Lleva a la superficie del rol activo o al selector de centro.
void enterStaffArea(BuildContext context, StaffSession session) {
  final StaffMembershipScope? active = session.active;
  context.go(active == null ? '/personal/ambito' : active.role.path);
}

/// Campo con la etiqueta visible arriba, como en la maqueta.
class StaffField extends StatelessWidget {
  const StaffField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.capitalization = TextCapitalization.none,
    this.onSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? maxLength;

  static OutlineInputBorder _border(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      ExcludeSemantics(
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 8),
      // Etiqueta para lector de pantalla; la visible va arriba.
      Semantics(
        label: label,
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          autocorrect: false,
          enableSuggestions: !obscure && onToggleObscure == null,
          textInputAction: textInputAction,
          textCapitalization: capitalization,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: _border(const Color(0xFFA5C1EF), 1.5),
            enabledBorder: _border(const Color(0xFFA5C1EF), 1.5),
            focusedBorder: _border(CureandoTheme.blue, 2),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    tooltip: obscure
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: CureandoTheme.ink,
                    ),
                    onPressed: onToggleObscure,
                  ),
          ),
        ),
      ),
    ],
  );
}

/// Aviso con icono y texto; el color nunca es el único indicador.
class StaffNotice extends StatelessWidget {
  const StaffNotice(this.text, {super.key, this.error = true});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? CureandoTheme.yellowSoft : CureandoTheme.blueSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: error ? const Color(0xFFE5C100) : const Color(0xFFA5C1EF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            error ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: CureandoTheme.ink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Botón principal que muestra la espera sin perder su tamaño.
class StaffPrimaryButton extends StatelessWidget {
  const StaffPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => FilledButton(
    style: flowPrimaryStyle(),
    onPressed: busy ? null : onPressed,
    child: busy
        ? Semantics(
            label: 'Procesando',
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          )
        : Text(label, textAlign: TextAlign.center),
  );
}

/// Pantalla de una superficie de personal: marca, rol y menú de la sesión.
class StaffAreaScaffold extends StatelessWidget {
  const StaffAreaScaffold({
    super.key,
    required this.session,
    required this.body,
    this.bottom,
  });

  final StaffSession session;
  final Widget body;
  final Widget? bottom;

  void _menu(BuildContext context) {
    final StaffMembershipScope? active = session.active;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (BuildContext sheet) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  active?.role.label ?? 'Personal autorizado',
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
              ),
              if (active != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(active.place),
              ],
              const SizedBox(height: 16),
              if (session.memberships.length > 1)
                OutlinedButton(
                  style: flowSecondaryStyle(),
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    context.go('/personal/ambito');
                  },
                  child: const Text('Cambiar de centro'),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(sheet).pop();
                  session.signOut();
                },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FlowScaffold(
    header: Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 12),
      child: Row(
        children: <Widget>[
          const CampaignSymbol(size: 30),
          const SizedBox(width: 8),
          const ExcludeSemantics(
            child: Text(
              'SéTú',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 1.5,
            height: 34,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white70,
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                session.active?.role.label ?? 'Personal autorizado',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Mi sesión',
            onPressed: () => _menu(context),
            icon: const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person_outline_rounded,
                color: CureandoTheme.ink,
              ),
            ),
          ),
        ],
      ),
    ),
    bottom: bottom,
    body: body,
  );
}
