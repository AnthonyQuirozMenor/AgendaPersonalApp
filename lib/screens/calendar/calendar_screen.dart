import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/task.dart';
import '../../models/event.dart';
import '../../utils/dialog_utils.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isMonthlyView = true;

  final List<String> _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  // Helper: Number of days in a month
  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // Helper: Start weekday offset (0 = Monday, 6 = Sunday)
  int _getStartOffset(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    // firstDay.weekday: 1 = Monday, 7 = Sunday
    return firstDay.weekday - 1;
  }

  // Helper: check if two dates are same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Helper: check if date is within event range
  bool _isDateInEvent(DateTime date, Event event) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
    final end = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);
    return (d.isAtSameMomentAs(start) || d.isAfter(start)) && (d.isAtSameMomentAs(end) || d.isBefore(end));
  }

  void _next() {
    setState(() {
      if (_isMonthlyView) {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      } else {
        _focusedDay = _focusedDay.add(const Duration(days: 7));
      }
    });
  }

  void _previous() {
    setState(() {
      if (_isMonthlyView) {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      } else {
        _focusedDay = _focusedDay.subtract(const Duration(days: 7));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    // Selected day tasks and events
    final dayTasks = appState.tasks.where((t) => _isSameDay(t.dueDate, _selectedDay)).toList();
    final dayEvents = appState.events.where((e) => _isDateInEvent(_selectedDay, e)).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Calendario',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // View Toggle
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Mensual'),
                        icon: Icon(Icons.calendar_view_month),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Semanal'),
                        icon: Icon(Icons.calendar_view_week),
                      ),
                    ],
                    selected: {_isMonthlyView},
                    onSelectionChanged: (val) {
                      setState(() {
                        _isMonthlyView = val.first;
                        _focusedDay = _selectedDay;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Calendar Card ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Navigation & Month Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _previous,
                          ),
                          Text(
                            _isMonthlyView
                                ? DateFormat('MMMM y', 'es').format(_focusedDay).toUpperCase()
                                : 'Semana de ' + DateFormat('d MMM, y', 'es').format(
                                    _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1))),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _next,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Weekdays Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _weekdays.map((day) {
                          return SizedBox(
                            width: 40,
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Divider(height: 20),

                      // Monthly / Weekly Grid
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isMonthlyView
                            ? _buildMonthlyGrid(appState)
                            : _buildWeeklyGrid(appState),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Tasks & Events for Selected Day Header ---
              Text(
                'Agenda para el ' + DateFormat('d \'de\' MMMM', 'es').format(_selectedDay),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // --- Agenda List ---
              Expanded(
                child: (dayTasks.isEmpty && dayEvents.isEmpty)
                    ? Center(
                        child: Text(
                          'No hay tareas ni eventos programados para este día.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                      )
                    : ListView(
                        children: [
                          if (dayEvents.isNotEmpty) ...[
                            _buildSectionHeader(context, 'Eventos', Icons.event),
                            ...dayEvents.map((event) => _buildEventTile(context, event)),
                            const SizedBox(height: 16),
                          ],
                          if (dayTasks.isNotEmpty) ...[
                            _buildSectionHeader(context, 'Tareas', Icons.checklist),
                            ...dayTasks.map((task) => _buildTaskTile(context, task, appState)),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyGrid(AppState appState) {
    final theme = Theme.of(context);
    final daysInMonth = _getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final offset = _getStartOffset(_focusedDay.year, _focusedDay.month);

    final totalGridItems = daysInMonth + offset;
    final rows = (totalGridItems / 7).ceil();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows * 7,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        if (index < offset || index >= daysInMonth + offset) {
          // Empty slots for padded dates
          return const SizedBox();
        }

        final dayNumber = index - offset + 1;
        final date = DateTime(_focusedDay.year, _focusedDay.month, dayNumber);
        final isSelected = _isSameDay(date, _selectedDay);
        final isToday = _isSameDay(date, DateTime.now());

        // Has tasks or events
        final hasTasks = appState.tasks.any((t) => _isSameDay(t.dueDate, date) && !t.completed);
        final hasEvents = appState.events.any((e) => _isDateInEvent(date, e));

        return _buildDayCell(date, dayNumber, isSelected, isToday, hasTasks, hasEvents);
      },
    );
  }

  Widget _buildWeeklyGrid(AppState appState) {
    final startOfWeek = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final date = startOfWeek.add(Duration(days: index));
        final isSelected = _isSameDay(date, _selectedDay);
        final isToday = _isSameDay(date, DateTime.now());

        final hasTasks = appState.tasks.any((t) => _isSameDay(t.dueDate, date) && !t.completed);
        final hasEvents = appState.events.any((e) => _isDateInEvent(date, e));

        return _buildDayCell(date, date.day, isSelected, isToday, hasTasks, hasEvents);
      }),
    );
  }

  Widget _buildDayCell(
    DateTime date,
    int dayNumber,
    bool isSelected,
    bool isToday,
    bool hasTasks,
    bool hasEvents,
  ) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDay = date;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : (isToday ? theme.colorScheme.primaryContainer.withOpacity(0.4) : null),
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNumber.toString(),
              style: TextStyle(
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : (isToday ? theme.colorScheme.primary : null),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasTasks)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? theme.colorScheme.onPrimary : Colors.blue,
                    ),
                  ),
                if (hasTasks && hasEvents) const SizedBox(width: 2),
                if (hasEvents)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? theme.colorScheme.onPrimary : Colors.purple,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, Event event) {
    final theme = Theme.of(context);
    final timeStr = '${DateFormat('h:mm a', 'es').format(event.startDate)} - ${DateFormat('h:mm a', 'es').format(event.endDate)}';
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description.isNotEmpty) Text(event.description),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: const Icon(Icons.lens, color: Colors.purple, size: 12),
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, Task task, AppState appState) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: task.completed,
        onChanged: (_) {
          confirmAndCompleteTask(context, task, appState);
        },
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task.completed ? TextDecoration.lineThrough : null,
            color: task.completed ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getPriorityColor(task.priority).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.priority,
                style: TextStyle(
                  fontSize: 9,
                  color: _getPriorityColor(task.priority),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              task.completed ? 'Completada' : 'Pendiente',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
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
}
