import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/event.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  void _showEventDialog({Event? event}) {
    showDialog(
      context: context,
      builder: (ctx) => _EventFormDialog(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final events = appState.events;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reuniones y Eventos',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Organiza tus reuniones, eventos e hitos importantes',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // --- Events List ---
              Expanded(
                child: events.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          final startStr = DateFormat('EEEE d \'de\' MMM, h:mm a', 'es').format(event.startDate);
                          final endStr = DateFormat('h:mm a', 'es').format(event.endDate);
                          
                          // Check if multi-day event
                          final isMultiDay = event.startDate.day != event.endDate.day ||
                              event.startDate.month != event.endDate.month ||
                              event.startDate.year != event.endDate.year;
                          
                          final dateText = isMultiDay
                              ? '$startStr - ${DateFormat('EEEE d \'de\' MMM, h:mm a', 'es').format(event.endDate)}'
                              : '$startStr a $endStr';

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.videocam_outlined,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                title: Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (event.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(event.description),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_filled,
                                          size: 14,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            dateText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      tooltip: 'Editar evento',
                                      onPressed: () => _showEventDialog(event: event),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                                      tooltip: 'Eliminar evento',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Eliminar Evento'),
                                            content: const Text('¿Estás seguro de que deseas eliminar este evento?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  appState.deleteEvent(event.id!);
                                                },
                                                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                                                child: const Text('Eliminar'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventDialog(),
        tooltip: 'Crear Evento',
        child: const Icon(Icons.add_task_rounded),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 80,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay eventos programados',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Presiona el botón + para programar uno.',
            style: TextStyle(
              color: theme.colorScheme.outline.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// --- EVENT CREATION / EDITING DIALOG ---
class _EventFormDialog extends StatefulWidget {
  final Event? event;
  const _EventFormDialog({this.event});

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    
    if (widget.event != null) {
      _startDate = widget.event!.startDate;
      _endDate = widget.event!.endDate;
    } else {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
      _endDate = _startDate.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isPastDateTime(DateTime selected) {
    final now = DateTime.now();
    final selectedDate = DateTime(selected.year, selected.month, selected.day);
    final today = DateTime(now.year, now.month, now.day);
    
    if (selectedDate.isBefore(today)) {
      return true;
    }
    if (selectedDate.isAtSameMomentAs(today)) {
      if (selected.hour < now.hour) {
        return true;
      }
      if (selected.hour == now.hour && selected.minute < now.minute) {
        return true;
      }
    }
    return false;
  }

  Future<void> _selectDateTime(bool isStart) async {
    final now = DateTime.now();
    final initialDate = isStart ? _startDate : _endDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validate immediately if combined date/time is in the past
    if (_isPastDateTime(combined)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No puedes programar una tarea o evento en una hora que ya pasó.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = combined;
        // Auto-adjust end date to start date + 1 hour if end is before start
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 1));
        }
      } else {
        if (combined.isBefore(_startDate)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La fecha de fin no puede ser anterior a la fecha de inicio.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        _endDate = combined;
      }
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isPastDateTime(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes programar una tarea o evento en una hora que ya pasó.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de fin debe ser posterior a la fecha de inicio.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);

    if (widget.event == null) {
      await appState.addEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
      );
    } else {
      final updated = widget.event!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
      );
      await appState.updateEvent(updated);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.event != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar Evento' : 'Nuevo Evento'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Title ---
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título del Evento *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un título para el evento.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Description ---
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Ubicación',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // --- Start Date Picker ---
              Text(
                'Inicio:',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () => _selectDateTime(true),
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  DateFormat('d MMM, y - h:mm a', 'es').format(_startDate),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(height: 16),

              // --- End Date Picker ---
              Text(
                'Fin:',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () => _selectDateTime(false),
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  DateFormat('d MMM, y - h:mm a', 'es').format(_endDate),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.centerLeft,
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
