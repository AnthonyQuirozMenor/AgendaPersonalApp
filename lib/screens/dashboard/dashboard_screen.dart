import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/task.dart';
import '../../models/event.dart';
import '../../utils/dialog_utils.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    // Filter data for dashboard
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final pendingTasks = appState.tasks.where((t) => !t.completed).toList();
    final highPriorityTasks = pendingTasks.where((t) => t.priority == 'Alta').toList();
    
    final upcomingEvents = appState.events.where((e) {
      return e.endDate.isAfter(todayStart);
    }).toList();

    // Responsive sizing
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Welcome Header ---
              Text(
                _getGreeting(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat("d 'de' MMMM 'de' y", 'es').format(now),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // --- Quick Metrics Grid ---
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.count(
                    crossAxisCount: isDesktop ? 3 : (constraints.maxWidth > 500 ? 2 : 1),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    children: [
                      _buildMetricCard(
                        context,
                        title: 'Tareas Pendientes',
                        value: pendingTasks.length.toString(),
                        subtitle: '${highPriorityTasks.length} de alta prioridad',
                        icon: Icons.checklist_rounded,
                        color: theme.colorScheme.primaryContainer,
                        onColor: theme.colorScheme.onPrimaryContainer,
                      ),
                      _buildMetricCard(
                        context,
                        title: 'Próximos Eventos',
                        value: upcomingEvents.length.toString(),
                        subtitle: 'En tu agenda',
                        icon: Icons.calendar_today_rounded,
                        color: theme.colorScheme.secondaryContainer,
                        onColor: theme.colorScheme.onSecondaryContainer,
                      ),
                      _buildMetricCard(
                        context,
                        title: 'Completadas',
                        value: appState.tasks.where((t) => t.completed).length.toString(),
                        subtitle: 'Total de tareas listas',
                        icon: Icons.done_all_rounded,
                        color: theme.colorScheme.tertiaryContainer,
                        onColor: theme.colorScheme.onTertiaryContainer,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // --- Content Layout: Tasks & Events ---
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildUpcomingEventsSection(context, upcomingEvents),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: _buildPendingTasksSection(context, pendingTasks),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildUpcomingEventsSection(context, upcomingEvents),
                        const SizedBox(height: 24),
                        _buildPendingTasksSection(context, pendingTasks),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Buenos días';
    } else if (hour >= 12 && hour < 18) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color onColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: onColor.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: onColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              size: 48,
              color: onColor.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEventsSection(BuildContext context, List<Event> events) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Próximos Eventos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.arrow_right_alt_rounded),
          ],
        ),
        const SizedBox(height: 16),
        if (events.isEmpty)
          _buildEmptyCard(
            context,
            message: 'No tienes eventos o reuniones programadas.',
            icon: Icons.calendar_today_outlined,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.take(4).length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = events[index];
              final dateStr = DateFormat('d MMM, h:mm a', 'es').format(event.startDate);
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.description.isNotEmpty)
                        Text(
                          event.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPendingTasksSection(BuildContext context, List<Task> tasks) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tareas Pendientes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (tasks.isEmpty)
          _buildEmptyCard(
            context,
            message: '¡Todo listo! No tienes tareas pendientes.',
            icon: Icons.check_circle_outline_rounded,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.take(4).length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = tasks[index];
              final dateStr = DateFormat('d MMM', 'es').format(task.dueDate);
              final priorityColor = _getPriorityColor(context, task.priority);

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CheckboxListTile(
                  value: task.completed,
                  onChanged: (_) {
                    confirmAndCompleteTask(context, task, appState);
                  },
                  title: Text(
                    task.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.priority,
                          style: TextStyle(
                            fontSize: 10,
                            color: priorityColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Vence: $dateStr',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              );
            },
          ),
      ],
    );
  }

  Color _getPriorityColor(BuildContext context, String priority) {
    switch (priority) {
      case 'Alta':
        return Colors.red;
      case 'Media':
        return Colors.orange;
      case 'Baja':
      default:
        return Colors.blue;
    }
  }

  Widget _buildEmptyCard(BuildContext context, {required String message, required IconData icon}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
