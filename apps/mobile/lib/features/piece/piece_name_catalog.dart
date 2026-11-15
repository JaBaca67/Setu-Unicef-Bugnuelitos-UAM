import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Género gramatical del sustantivo, para que el apodo concuerde.
enum NameGender { masculine, feminine }

/// Primera palabra del nombre de juego. Lista cerrada: ningún sustantivo es
/// un nombre de pila común, para que el nombre de juego no parezca civil.
enum PieceNameNoun {
  pulgin('Pulgin', NameGender.masculine),
  tapudin('Tapudín', NameGender.masculine),
  chispa('Chispa', NameGender.feminine),
  cometa('Cometa', NameGender.masculine),
  nube('Nube', NameGender.feminine),
  rayo('Rayo', NameGender.masculine),
  volcan('Volcán', NameGender.masculine),
  colibri('Colibrí', NameGender.masculine),
  guardabarranco('Guardabarranco', NameGender.masculine),
  brisa('Brisa', NameGender.feminine),
  galaxia('Galaxia', NameGender.feminine),
  cohete('Cohete', NameGender.masculine);

  const PieceNameNoun(this.label, this.gender);
  final String label;
  final NameGender gender;
}

/// Segunda palabra del nombre de juego: cualidades positivas, sin aludir al
/// aspecto físico. Concuerda en género con el sustantivo.
enum PieceNameTrait {
  valiente('Valiente'),
  cosmico('Cósmico', 'Cósmica'),
  veloz('Veloz'),
  brillante('Brillante'),
  amable('Amable'),
  curioso('Curioso', 'Curiosa'),
  creativo('Creativo', 'Creativa'),
  tranquilo('Tranquilo', 'Tranquila'),
  alegre('Alegre'),
  estelar('Estelar'),
  solidario('Solidario', 'Solidaria'),
  empatico('Empático', 'Empática');

  const PieceNameTrait(this.masculine, [String? feminine])
    : feminine = feminine ?? masculine;

  final String masculine;
  final String feminine;

  String formFor(NameGender gender) =>
      gender == NameGender.feminine ? feminine : masculine;
}

/// Nombre de juego de la pieza: una combinación del catálogo aprobado.
/// Nunca es texto libre, así no puede contener el nombre real.
@immutable
class PieceName {
  const PieceName(this.noun, this.trait);

  final PieceNameNoun noun;
  final PieceNameTrait trait;

  static const PieceName initial = PieceName(
    PieceNameNoun.pulgin,
    PieceNameTrait.valiente,
  );

  String get displayName => '${noun.label} ${trait.formFor(noun.gender)}';

  /// Todas las combinaciones válidas del catálogo.
  static Iterable<PieceName> get all sync* {
    for (final PieceNameNoun noun in PieceNameNoun.values) {
      for (final PieceNameTrait trait in PieceNameTrait.values) {
        yield PieceName(noun, trait);
      }
    }
  }

  factory PieceName.random(math.Random random) => PieceName(
    PieceNameNoun.values[random.nextInt(PieceNameNoun.values.length)],
    PieceNameTrait.values[random.nextInt(PieceNameTrait.values.length)],
  );

  static String _normalize(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// Combinación del catálogo que corresponde al texto guardado; null si el
  /// texto no pertenece al catálogo (por ejemplo, un apodo libre anterior).
  static PieceName? match(String? raw) {
    if (raw == null) return null;
    final String wanted = _normalize(raw);
    if (wanted.isEmpty) return null;
    for (final PieceName name in all) {
      if (_normalize(name.displayName) == wanted) return name;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is PieceName && other.noun == noun && other.trait == trait;

  @override
  int get hashCode => Object.hash(noun, trait);

  @override
  String toString() => displayName;
}
