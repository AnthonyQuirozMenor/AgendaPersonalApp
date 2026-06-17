import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/habit.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  String _filter = 'Activos'; // 'Activos', 'Completados'

  void _showHabitFormDialog({Habit? habit}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final activeCount = appState.habits.where((h) => !h.isCompleted).length;

    if (habit == null && activeCount >= 6) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Límite alcanzado'),
            ],
          ),
          content: const Text(
            'Solo puedes tener hasta 6 hábitos activos.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _HabitFormDialog(habit: habit),
    );
  }

  void _showDeleteConfirmation(Habit habit) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Hábito'),
        content: Text('¿Estás seguro de que deseas eliminar el hábito "${habit.title}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              appState.deleteHabit(habit.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hábito eliminado correctamente.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showCongratulationsDialog(Habit habit) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 64),
            SizedBox(height: 12),
            Text(
              '¡Felicitaciones!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Has completado el hábito "${habit.title}" durante 21 días consecutivos.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              '¡Tu constancia ha dado frutos! El hábito ha sido marcado como completado y se ha guardado en tu historial.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('¡Excelente!', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    final activeHabits = appState.habits.where((h) => !h.isCompleted).toList();
    final completedHabits = appState.habits.where((h) => h.isCompleted).toList();

    final displayedHabits = _filter == 'Activos' ? activeHabits : completedHabits;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mis Hábitos',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // --- Limit Warning Banner ---
              if (_filter == 'Activos' && activeHabits.length >= 6)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Solo puedes tener hasta 6 hábitos activos.',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // --- Filter Chips ---
              Row(
                children: ['Activos', 'Completados'].map((filterType) {
                  final isSelected = _filter == filterType;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filterType),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _filter = filterType;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // --- Habits List ---
              Expanded(
                child: displayedHabits.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: displayedHabits.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final habit = displayedHabits[index];
                          return _HabitCard(
                            habit: habit,
                            onEdit: () => _showHabitFormDialog(habit: habit),
                            onDelete: () => _showDeleteConfirmation(habit),
                            onStreakCompleted: () => _showCongratulationsDialog(habit),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _filter == 'Activos'
          ? FloatingActionButton(
              onPressed: () => _showHabitFormDialog(),
              tooltip: 'Crear Hábito',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_outlined,
            size: 80,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _filter == 'Activos' ? 'No tienes hábitos activos' : 'No tienes hábitos completados',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filter == 'Activos'
                ? 'Comienza a construir hábitos saludables hoy.'
                : 'Tus hábitos finalizados aparecerán aquí.',
            style: TextStyle(
              color: theme.colorScheme.outline.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// --- INDIVIDUAL REDESIGNED HABIT CARD ---
class _HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStreakCompleted;

  const _HabitCard({
    required this.habit,
    required this.onEdit,
    required this.onDelete,
    required this.onStreakCompleted,
  });

  void _confirmAndCompleteDay(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar hábito'),
        content: const Text('¿Completaste el hábito hoy?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // 'No' action
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              final now = DateTime.now();
              final streakDone = await appState.toggleHabitCompletionDate(habit, now);
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Día registrado correctamente!'),
                    backgroundColor: Colors.green,
                  ),
                );
                if (streakDone) {
                  onStreakCompleted();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if today is completed
    final completedToday = habit.completionDates.any(
      (d) => d.year == today.year && d.month == today.month && d.day == today.day,
    );

    // Calculate dates and range
    final startDate = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
    final endDate = startDate.add(const Duration(days: 20));
    final habitEnded = today.isAfter(endDate);

    return Card(
      elevation: habit.isCompleted ? 0 : 3,
      color: habit.isCompleted
          ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: habit.isCompleted
            ? BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title & Menu ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: habit.isCompleted ? theme.colorScheme.onSurfaceVariant : null,
                          decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (habit.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          habit.description,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                            decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (val) {
                    if (val == 'edit') {
                      onEdit();
                    } else if (val == 'delete') {
                      onDelete();
                    } else if (val == 'toggle_complete') {
                      Provider.of<AppState>(context, listen: false).toggleHabitCompletedStatus(habit);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (!habit.isCompleted)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'toggle_complete',
                      child: Row(
                        children: [
                          Icon(habit.isCompleted ? Icons.undo_rounded : Icons.check_circle_outline_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(habit.isCompleted ? 'Reactivar' : 'Completar / Archivar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Stats Indicators Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Racha actual
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥 ', style: TextStyle(fontSize: 14)),
                      Text(
                        'Racha: ${habit.currentStreak} días seguidos',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Avance
                Text(
                  '${habit.completedDaysCount}/21 días (${habit.progressPercentage.toStringAsFixed(0)}%)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Sequential 21 Days Grid ---
            _HabitSequenceGrid(habit: habit),
            const SizedBox(height: 20),

            // --- "Completar día" Button ---
            if (!habit.isCompleted) ...[
              if (habitEnded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Hábito finalizado (21 días)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: completedToday ? null : () => _confirmAndCompleteDay(context),
                  icon: Icon(completedToday ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded),
                  label: Text(
                    completedToday ? 'Completado hoy' : 'Completar día',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: completedToday ? Colors.green.shade200 : theme.colorScheme.primary,
                    foregroundColor: completedToday ? Colors.green.shade900 : theme.colorScheme.onPrimary,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- SEQUENTIAL GRID WIDGET ---
class _HabitSequenceGrid extends StatelessWidget {
  final Habit habit;

  const _HabitSequenceGrid({required this.habit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isDark = theme.brightness == Brightness.dark;

    // Base date
    final startDate = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);

    // Color systems
    final greenBg = isDark ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E9);
    final greenText = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final greenBorder = isDark ? const Color(0xFF388E3C) : const Color(0xFF4CAF50);

    final redBg = isDark ? const Color(0xFFB71C1C).withOpacity(0.25) : const Color(0xFFFFEBEE);
    final redText = isDark ? const Color(0xFFE57373) : const Color(0xFFC62828);

    final pendingBg = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final pendingText = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 21,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (ctx, index) {
        final dayNum = index + 1;
        final cellDate = startDate.add(Duration(days: index));
        final dateStr = DateFormat('d MMM', 'es').format(cellDate);

        final isCompleted = habit.completionDates.any(
          (d) => d.year == cellDate.year && d.month == cellDate.month && d.day == cellDate.day,
        );

        final isTodayCell = cellDate.year == now.year &&
            cellDate.month == now.month &&
            cellDate.day == now.day;

        final isPast = cellDate.isBefore(today);
        final isFailed = isPast && !isCompleted;

        Color bg;
        Color textColor;
        Widget statusIcon;
        BoxBorder? border;

        if (isCompleted) {
          bg = greenBg;
          textColor = greenText;
          statusIcon = Icon(Icons.check_rounded, size: 14, color: greenText);
          border = Border.all(color: greenBorder, width: 1);
        } else if (isFailed) {
          bg = redBg;
          textColor = redText;
          statusIcon = Icon(Icons.close_rounded, size: 14, color: redText);
        } else {
          bg = pendingBg;
          textColor = pendingText;
          statusIcon = const SizedBox(height: 14);
        }

        if (isTodayCell && !isCompleted) {
          border = Border.all(color: theme.colorScheme.primary, width: 2);
        }

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'D$dayNum',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.8),
                ),
              ),
              statusIcon,
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- FORM DIALOG (CREATE / EDIT) ---
class _HabitFormDialog extends StatefulWidget {
  final Habit? habit;
  const _HabitFormDialog({this.habit});

  @override
  State<_HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<_HabitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.habit?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);

    if (widget.habit == null) {
      final success = await appState.addHabit(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hábito creado correctamente.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solo puedes tener hasta 6 hábitos activos.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      final updated = widget.habit!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      await appState.updateHabit(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hábito actualizado correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.habit != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar Hábito' : 'Nuevo Hábito'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej. Hacer ejercicio, Meditar, Leer',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un título para el hábito.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  hintText: 'Ej. 30 minutos por la mañana',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: Text(isEdit ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
