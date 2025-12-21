import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/workout.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.workout != null) {
      _titleController.text = widget.workout!.title;
      _descriptionController.text = widget.workout!.description;
      _durationController.text = widget.workout!.durationMinutes.toString();
    }
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
      if (widget.workout == null) {
        // Новая тренировка
        final newWorkout = Workout(
          userId: widget.user.id!,
          title: title,
          description: description,
          durationMinutes: duration,
        );
        await _dbHelper.insertWorkout(newWorkout);
      } else {
        // Обновление имеющейся
        final updatedWorkout = Workout(
          id: widget.workout!.id,
          userId: widget.user.id!,
          title: title,
          description: description,
          durationMinutes: duration,
        );
        await _dbHelper.updateWorkout(updatedWorkout);
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
