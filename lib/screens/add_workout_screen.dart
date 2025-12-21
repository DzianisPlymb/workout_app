import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../db/database_helper.dart';

class AddWorkoutScreen extends StatefulWidget {
  final User user;
  final Workout? workout; // null — новая, не null — редактирование

  const AddWorkoutScreen({
    super.key,
    required this.user,
    this.workout,
  });

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  final _dbHelper = DatabaseHelper.instance;

  bool _isSaving = false;
  String? _errorMessage;
  List<Exercise> _exercises = [];
  late int _workoutId;

  @override
  void initState() {
    super.initState();
    if (widget.workout != null) {
      _workoutId = widget.workout!.id!;
      _titleController.text = widget.workout!.title;
      _descriptionController.text = widget.workout!.description;
      _durationController.text = widget.workout!.durationMinutes.toString();
      _loadExercises();
    } else {
      _workoutId = -1; // placeholder
    }
  }

  Future<void> _loadExercises() async {
    _exercises = await _dbHelper.getExercisesForWorkout(_workoutId);
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final durationText = _durationController.text.trim();

    if (title.isEmpty || durationText.isEmpty) {
      setState(() {
        _errorMessage = 'Название и длительность обязательны';
      });
      return;
    }

    final duration = int.tryParse(durationText);
    if (duration == null || duration <= 0) {
      setState(() {
        _errorMessage = 'Длительность должна быть положительным числом';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      int workoutId;
      if (widget.workout == null) {
        // Новая тренировка
        final newWorkout = Workout(
          userId: widget.user.id!,
          title: title,
          description: description,
          durationMinutes: duration,
        );
        workoutId = await _dbHelper.insertWorkout(newWorkout);
        // Сохранить упражнения с правильным workoutId
        for (var exercise in _exercises) {
          final updatedExercise = Exercise(
            workoutId: workoutId,
            name: exercise.name,
            durationSeconds: exercise.durationSeconds,
          );
          await _dbHelper.insertExercise(updatedExercise);
        }
      } else {
        // Обновление имеющейся
        workoutId = widget.workout!.id!;
        final updatedWorkout = Workout(
          id: workoutId,
          userId: widget.user.id!,
          title: title,
          description: description,
          durationMinutes: duration,
        );
        await _dbHelper.updateWorkout(updatedWorkout);
        // Упражнения уже обновлены отдельно
      }

      if (!mounted) return;
      Navigator.of(context).pop(true); // true = обновить список
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _addOrEditExercise([Exercise? exercise]) async {
    final nameController = TextEditingController(text: exercise?.name ?? '');
    final durationController = TextEditingController(text: exercise?.durationSeconds.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exercise == null ? 'Добавить упражнение' : 'Редактировать упражнение'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(labelText: 'Длительность (секунды)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      final durationText = durationController.text.trim();
      final duration = int.tryParse(durationText);

      if (name.isNotEmpty && duration != null && duration > 0) {
        if (exercise == null) {
          // Новое упражнение
          final newExercise = Exercise(
            workoutId: _workoutId,
            name: name,
            durationSeconds: duration,
          );
          await _dbHelper.insertExercise(newExercise);
        } else {
          // Обновление
          final updatedExercise = Exercise(
            id: exercise.id,
            workoutId: _workoutId,
            name: name,
            durationSeconds: duration,
          );
          await _dbHelper.updateExercise(updatedExercise);
        }
        _loadExercises();
      }
    }
  }

  Future<void> _deleteExercise(int id) async {
    await _dbHelper.deleteExercise(id);
    _loadExercises();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.workout != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактировать тренировку' : 'Новая тренировка'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Длительность (минуты)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Text('Упражнения:', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(
              height: 200,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return ListTile(
                    title: Text(exercise.name),
                    subtitle: Text('${exercise.durationSeconds} сек'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _addOrEditExercise(exercise),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteExercise(exercise.id!),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => _addOrEditExercise(),
              child: const Text('Добавить упражнение'),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _save,
                    child: Text(isEdit ? 'Сохранить' : 'Добавить'),
                  ),
          ],
        ),
      ),
    );
  }
}
