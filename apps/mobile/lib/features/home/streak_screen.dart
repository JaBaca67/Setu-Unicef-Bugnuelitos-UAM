import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import '../../shared/widgets/setu_card.dart';
import 'learning_progress.dart';

const List<String> _weekdays = <String>[
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const List<String> _weekdayLetters = <String>[
  'L',
  'M',
  'X',
  'J',
  'V',
  'S',
  'D',
];
const List<String> _months = <String>[
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];
const Color _streakBorder = Color(0xFFB9D9F7);
const Color _streakBlue = Color(0xFFDBEEFD);

String _daysLabel(int days) => days == 1 ? '1 día' : '$days días';

class WeeklyStreakCard extends StatelessWidget {
  const WeeklyStreakCard({
    super.key,
    required this.progress,
    required this.onTap,
  });

  final LearningProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!progress.ready) return LearningProgressStatus(progress: progress);
    final DateTime today = progress.today;
    final DateTime monday = today.subtract(Duration(days: today.weekday - 1));
    return SetuCard(
      onTap: onTap,
      borderColor: _streakBorder,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                _Flame(active: progress.streak > 0),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 2,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        'Racha de ${_daysLabel(progress.streak)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${progress.xp} XP',
                        style: const TextStyle(
                          color: CureandoTheme.blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: CureandoTheme.blue,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                for (int index = 0; index < 7; index++)
                  Expanded(
                    child: _WeeklyDay(
                      date: monday.add(Duration(days: index)),
                      progress: progress,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyDay extends StatelessWidget {
  const _WeeklyDay({required this.date, required this.progress});

  final DateTime date;
  final LearningProgress progress;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      ExcludeSemantics(
        child: Text(
          _weekdayLetters[date.weekday - 1],
          style: const TextStyle(fontSize: 11),
        ),
      ),
      const SizedBox(height: 4),
      _DayMarker(date: date, progress: progress, weekly: true),
    ],
  );
}

class _DayMarker extends StatelessWidget {
  const _DayMarker({
    required this.date,
    required this.progress,
    this.weekly = false,
  });

  final DateTime date;
  final LearningProgress progress;
  final bool weekly;

  @override
  Widget build(BuildContext context) {
    final bool today = date == progress.today;
    final bool active =
        !date.isAfter(progress.today) && progress.isActive(date);
    final Border? border = today
        ? Border.all(color: CureandoTheme.blue, width: 2)
        : weekly
        ? Border.all(color: _streakBorder)
        : null;
    final Widget? number = weekly
        ? (active
              ? const Icon(Icons.check, size: 14, color: CureandoTheme.blue)
              : null)
        : Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: active || today ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : CureandoTheme.ink,
            ),
          );
    return Semantics(
      container: !weekly,
      label:
          '${_weekdays[date.weekday - 1]} ${date.day} de '
          '${_months[date.month - 1].toLowerCase()}'
          '${today ? ', hoy' : ''}${active ? ', actividad completada' : ''}',
      excludeSemantics: true,
      child: Container(
        width: weekly ? 22 : null,
        constraints: BoxConstraints(
          minWidth: weekly ? 22 : 0,
          minHeight: weekly ? 22 : 36,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? (weekly ? _streakBlue : CureandoTheme.blue) : null,
          border: border,
          borderRadius: BorderRadius.circular(weekly ? 24 : 10),
        ),
        child: number,
      ),
    );
  }
}

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key, required this.progress});

  final LearningProgress progress;

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    widget.progress.open();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.progress,
    builder: (BuildContext context, Widget? child) {
      final LearningProgress progress = widget.progress;
      final DateTime today = progress.today;
      final DateTime currentMonth = DateTime.utc(today.year, today.month);
      final DateTime month = _selectedMonth ?? currentMonth;
      return CampaignScreen(
        bodyRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        header: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 16),
          child: Row(
            children: <Widget>[
              IconButton(
                onPressed: () => context.pop(),
                tooltip: 'Volver',
                icon: const BackButtonIcon(),
                color: Colors.white,
              ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Mi racha',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              Image.asset(
                'assets/welcome/campaign-characters.png',
                width: 100,
                excludeFromSemantics: true,
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!progress.ready)
                LearningProgressStatus(progress: progress)
              else ...<Widget>[
                _StreakSummary(progress: progress),
                const SizedBox(height: 12),
                _MonthCalendar(
                  month: month,
                  progress: progress,
                  onPrevious: () => _goToMonth(month, -1),
                  onNext: month.isBefore(currentMonth)
                      ? () => _goToMonth(month, 1)
                      : null,
                ),
                const SizedBox(height: 12),
                SetuCard(
                  color: _streakBlue,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          progress.streak == 0
                              ? 'Empezá tu racha'
                              : 'Seguí aprendiendo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          progress.streak == 0
                              ? 'Completá una actividad de aprendizaje para marcar tu primer día.'
                              : 'Cada día que completás una actividad queda marcado en tu calendario.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.pop(true),
                          child: const Text('Ir a Actividades'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  void _goToMonth(DateTime month, int offset) {
    setState(
      () => _selectedMonth = DateTime.utc(month.year, month.month + offset),
    );
  }
}

class _StreakSummary extends StatelessWidget {
  const _StreakSummary({required this.progress});

  final LearningProgress progress;

  @override
  Widget build(BuildContext context) => SetuCard(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 16,
        runSpacing: 12,
        children: <Widget>[
          _Metric(
            icon: _Flame(active: progress.streak > 0),
            label: 'Racha actual',
            value: _daysLabel(progress.streak),
          ),
          _Metric(
            icon: const Icon(
              Icons.star_rounded,
              color: Color(0xFFEAAA00),
              size: 28,
            ),
            label: 'XP acumulados',
            value: '${progress.xp} XP',
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});

  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      icon,
      const SizedBox(width: 8),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    ],
  );
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.progress,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final LearningProgress progress;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final int leading = month.weekday - 1;
    final int days = DateTime.utc(month.year, month.month + 1, 0).day;
    return SetuCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: onPrevious,
                  tooltip: 'Mes anterior',
                  color: CureandoTheme.blue,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      '${_months[month.month - 1]} ${month.year}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onNext,
                  tooltip: 'Mes siguiente',
                  color: CureandoTheme.blue,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                for (final String label in _weekdayLetters)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
            const Divider(),
            for (int row = 0; row * 7 < leading + days; row++)
              Row(
                children: <Widget>[
                  for (int column = 0; column < 7; column++)
                    Expanded(
                      child: _cell(row * 7 + column - leading + 1, days),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int day, int days) => day < 1 || day > days
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.all(1),
          child: _DayMarker(
            date: DateTime.utc(month.year, month.month, day),
            progress: progress,
          ),
        );
}

class _Flame extends StatelessWidget {
  const _Flame({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => Icon(
    Icons.local_fire_department_rounded,
    size: 30,
    color: active ? const Color(0xFFE97C00) : const Color(0xFFA3C7E8),
  );
}

class LearningProgressStatus extends StatelessWidget {
  const LearningProgressStatus({super.key, required this.progress});

  final LearningProgress progress;

  @override
  Widget build(BuildContext context) => SetuCard(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: progress.loadFailed
          ? Column(
              children: <Widget>[
                const Text('No pudimos cargar tu progreso.'),
                TextButton(
                  onPressed: progress.open,
                  child: const Text('Reintentar'),
                ),
              ],
            )
          : const Text('Cargando tu progreso…'),
    ),
  );
}
