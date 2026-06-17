import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/task.dart';
import '../../utils/dialog_utils.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  String _filter = 'Pendientes'; // 'Todas', 'Pendientes', 'Completadas'

  void _showTaskDialog({Task? task}) {
    showDialog(
      context: context,
      builder: (ctx) => _TaskFormDialog(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    // Apply filter
    final filteredTasks = appState.tasks.where((t) {
      if (_filter == 'Pendientes') return !t.completed;
      if (_filter == 'Completadas') return t.completed;
      return true; // 'Todas'
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mis Tareas',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // --- Filter Chips ---
              Row(
                children: ['Pendientes', 'Completadas', 'Todas'].map((filterType) {
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

              // --- Tasks List ---
              Expanded(
                child: filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: filteredTasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          final priorityColor = _getPriorityColor(task.priority);
                          final dateStr = DateFormat('d MMM, y - h:mm a', 'es').format(task.dueDate);

                          return Card(
                            elevation: task.completed ? 0 : 2,
                            color: task.completed
                                ? theme.colorScheme.surfaceVariant.withOpacity(0.4)
                                : theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: task.completed
                                  ? BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                leading: Checkbox(
                                  value: task.completed,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (_) {
                                    confirmAndCompleteTask(context, task, appState);
                                  },
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: task.completed ? TextDecoration.lineThrough : null,
                                    color: task.completed ? theme.colorScheme.onSurfaceVariant : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (task.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        task.description,
                                        style: TextStyle(
                                          decoration: task.completed ? TextDecoration.lineThrough : null,
                                          color: task.completed ? theme.colorScheme.onSurfaceVariant.withOpacity(0.7) : null,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // Priority Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                        // Due Date
                                        Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.onSurfaceVariant,
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
                                      tooltip: 'Editar tarea',
                                      onPressed: () => _showTaskDialog(task: task),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                                      tooltip: 'Eliminar tarea',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Eliminar Tarea'),
                                            content: const Text('¿Estás seguro de que deseas eliminar esta tarea?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  appState.deleteTask(task.id!);
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
        onPressed: () => _showTaskDialog(),
        tooltip: 'Crear Tarea',
        child: const Icon(Icons.add),
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

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist_rtl_rounded,
            size: 80,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay tareas aquí',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Filtro actual: $_filter',
            style: TextStyle(
              color: theme.colorScheme.outline.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// --- TASK CREATION / EDITING DIALOG ---
class _TaskFormDialog extends StatefulWidget {
  final Task? task;
  const _TaskFormDialog({this.task});

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _priority;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    
    if (widget.task != null) {
      _selectedDate = widget.task!.dueDate;
    } else {
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    }
    _priority = widget.task?.priority ?? 'Media';
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

  void _selectDateTime() async {
    final now = DateTime.now();
    final initialDate = _selectedDate.isBefore(now) ? now : _selectedDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
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
      _selectedDate = combined;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isPastDateTime(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes programar una tarea o evento en una hora que ya pasó.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);

    if (widget.task == null) {
      await appState.addTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDate,
        priority: _priority,
      );
    } else {
      final updated = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDate,
        priority: _priority,
      );
      await appState.updateTask(updated);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.task != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar Tarea' : 'Nueva Tarea'),
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
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un título para la tarea.';
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
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // --- Due Date Picker ---
              OutlinedButton.icon(
                onPressed: _selectDateTime,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  'Fecha y Hora: ${DateFormat('d MMM, y - h:mm a', 'es').format(_selectedDate)}',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Priority Header ---
              Text(
                'Prioridad',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // --- Segmented Button or Choice Chips for Priority ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Baja', 'Media', 'Alta'].map((p) {
                  final isSelected = _priority == p;
                  Color chipColor;
                  switch (p) {
                    case 'Alta':
                      chipColor = Colors.red;
                      break;
                    case 'Media':
                      chipColor = Colors.orange;
                      break;
                    case 'Baja':
                    default:
                      chipColor = Colors.blue;
                  }

                  return ChoiceChip(
                    label: Text(p),
                    selected: isSelected,
                    selectedColor: chipColor.withOpacity(0.25),
                    labelStyle: TextStyle(
                      color: isSelected ? chipColor : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _priority = p;
                        });
                      }
                    },
                  );
                }).toList(),
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
