import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/setu_brand_mark.dart';

/// Avatar ilustrado del estudiante: una figura de la marca con un color
/// elegido. No usa fotos, nombres, iniciales ni datos de contacto.
@immutable
class StudentAvatar {
  const StudentAvatar({required this.motif, required this.colorName});

  final BrandMotif motif;
  final String colorName;

  static const Map<String, Color> colors = <String, Color>{
    'Azul': CureandoTheme.blue,
    'Rosa': CureandoTheme.pink,
    'Amarillo': CureandoTheme.yellow,
    'Verde': CureandoTheme.green,
  };

  static const Map<BrandMotif, String> motifNames = <BrandMotif, String>{
    BrandMotif.puzzle: 'Rompecabezas',
    BrandMotif.flower: 'Flor',
    BrandMotif.spiral: 'Espiral',
  };

  static const StudentAvatar initial = StudentAvatar(
    motif: BrandMotif.flower,
    colorName: 'Amarillo',
  );

  Color get color => colors[colorName] ?? CureandoTheme.blue;

  String get description =>
      '${motifNames[motif] ?? 'Figura'} de color ${colorName.toLowerCase()}';

  StudentAvatar copyWith({BrandMotif? motif, String? colorName}) =>
      StudentAvatar(
        motif: motif ?? this.motif,
        colorName: colorName ?? this.colorName,
      );
}

class StudentAvatarBadge extends StatelessWidget {
  const StudentAvatarBadge({super.key, required this.avatar, this.size = 56});

  final StudentAvatar avatar;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
    alignment: Alignment.center,
    child: BrandDecoration(
      motif: avatar.motif,
      color: avatar.color,
      size: size * .62,
    ),
  );
}

/// Hoja para personalizar el avatar con opciones gráficas. Devuelve el avatar
/// elegido o null si se cancela. La elección vive solo en esta sesión.
Future<StudentAvatar?> showAvatarEditor(
  BuildContext context,
  StudentAvatar current,
) => showModalBottomSheet<StudentAvatar>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  barrierLabel: 'Cerrar avatar',
  sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
      ? AnimationStyle.noAnimation
      : null,
  builder: (BuildContext context) => _AvatarEditor(current: current),
);

class _AvatarEditor extends StatefulWidget {
  const _AvatarEditor({required this.current});

  final StudentAvatar current;

  @override
  State<_AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends State<_AvatarEditor> {
  late StudentAvatar _avatar = widget.current;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text('Tu avatar virtual', style: textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            const Text(
              'Es un dibujo que te representa dentro de la app. '
              'No usamos fotos, nombres ni cuentas.',
            ),
            const SizedBox(height: 16),
            Center(
              child: Semantics(
                label: 'Vista previa del avatar: ${_avatar.description}',
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: CureandoTheme.blueSoft,
                    shape: BoxShape.circle,
                  ),
                  child: StudentAvatarBadge(avatar: _avatar, size: 84),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Figura', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: <Widget>[
                for (final MapEntry<BrandMotif, String> motif
                    in StudentAvatar.motifNames.entries)
                  ChoiceChip(
                    avatar: BrandDecoration(
                      motif: motif.key,
                      color: CureandoTheme.blue,
                      size: 20,
                    ),
                    label: Text(motif.value),
                    selected: _avatar.motif == motif.key,
                    onSelected: (_) =>
                        setState(() => _avatar = _avatar.copyWith(motif: motif.key)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Color', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: <Widget>[
                for (final MapEntry<String, Color> color
                    in StudentAvatar.colors.entries)
                  ChoiceChip(
                    avatar: ExcludeSemantics(
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: color.value,
                      ),
                    ),
                    label: Text(color.key),
                    selected: _avatar.colorName == color.key,
                    onSelected: (_) => setState(
                      () => _avatar = _avatar.copyWith(colorName: color.key),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu elección se recuerda mientras la app está abierta.',
              style: TextStyle(color: CureandoTheme.secondaryInk),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, _avatar),
              child: const Text('Guardar avatar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
