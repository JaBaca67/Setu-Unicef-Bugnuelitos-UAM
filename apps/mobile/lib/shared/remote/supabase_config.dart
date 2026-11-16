import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración remota inyectada en compilación mediante `--dart-define`.
///
/// Nunca incrustar URLs privadas o llaves de servicio en el código fuente.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  factory SupabaseConfig.fromEnvironment() => const SupabaseConfig(
        url: String.fromEnvironment('SUPABASE_URL'),
        anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      );

  final String url;
  final String anonKey;

  bool get isConfigured => url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}

/// Inicializa [Supabase] únicamente si se proveyeron `SUPABASE_URL` y
/// `SUPABASE_ANON_KEY` por `--dart-define`.
Future<bool> initializeSupabaseIfConfigured([SupabaseConfig? config]) async {
  final SupabaseConfig resolved = config ?? SupabaseConfig.fromEnvironment();
  if (!resolved.isConfigured) {
    return false;
  }
  await Supabase.initialize(
    url: resolved.url.trim(),
    publishableKey: resolved.anonKey.trim(),
  );
  return true;
}
