import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import 'student_resources.dart';

/// Vista de muestra de «Pedir apoyo». El recorrido real de solicitud
/// (E04/E05) y el envío todavía no están implementados.
class SupportPreviewScreen extends StatelessWidget {
  const SupportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const BackButtonIcon(),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
        title: const Text('Pedir apoyo'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SampleBanner(),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      'Cuéntanos lo que quieras compartir',
                      style: textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cuando este recorrido esté listo vas a poder pedir apoyo '
                    'en pasos cortos: elegís el tipo de situación, contás si '
                    'te pasa a vos o si sos Testigo Solidario, agregás '
                    'detalles solo si querés, y revisás todo antes de enviar.',
                  ),
                  const SizedBox(height: 16),
                  const _StepCard(
                    icon: Icons.category_outlined,
                    title: '1 · Tipo y rol',
                    text: 'Qué está pasando y cómo participás. No te pedimos '
                        'nombre ni carné.',
                  ),
                  const _StepCard(
                    icon: Icons.edit_note_rounded,
                    title: '2 · Detalles opcionales',
                    text: 'Vos decidís cuánto contar. Un aviso sin relato '
                        'también vale.',
                  ),
                  const _StepCard(
                    icon: Icons.fact_check_outlined,
                    title: '3 · Revisar y enviar',
                    text: 'Antes de enviar vas a ver quién recibe qué y el '
                        'estado real de la entrega.',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CureandoTheme.greenSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.notifications_active_outlined,
                              color: Color(0xFF057634),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Después de enviar',
                                style: textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Podés recibir un aviso cuando una persona '
                          'autorizada esté disponible para conversar. El '
                          'aviso abre tu chat y no incluye detalles de lo que '
                          'contaste. En esta demostración nadie está '
                          'conectado todavía.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push<void>('/inicio/apoyo/chat'),
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('Ver cómo será el chat'),
                  ),
                  const SizedBox(height: 12),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'Pendiente: formulario E04/E05, envío real y aviso de '
                        'disponibilidad. Esta vista solo muestra el recorrido '
                        'previsto con datos ficticios.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: CureandoTheme.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Vista de muestra del chat humano (E08). No hay conversación real: la mesa
/// de escucha conectada requiere internet y backend pendientes.
class ChatPreviewScreen extends StatelessWidget {
  const ChatPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const BackButtonIcon(),
        tooltip: 'Volver',
        onPressed: () => context.pop(),
      ),
      title: const Text('Chat humano'),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SampleBanner(
                  text: 'Muestra: nadie está conectado en esta demostración',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aquí vas a conversar con una persona real del equipo de '
                  'escucha, por internet. No es un chat automático ni un '
                  'robot. Solo vos y la persona asignada pueden leerlo.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: CureandoTheme.blueSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Equipo de escucha (mensaje de ejemplo): «Hola, gracias '
                    'por escribir. Estoy para escucharte, sin apuro.»',
                  ),
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'Pendiente: conexión con la mesa de escucha, horarios '
                      'reales y tarjetas rompehielos. Si no hay internet o no '
                      'hay una persona disponible, la app lo dirá sin simular '
                      'atención.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
