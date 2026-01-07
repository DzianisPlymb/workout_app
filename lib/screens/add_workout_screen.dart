import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
          userId: widget.user.id ?? (throw Exception('User ID is null')),
          title: title,
          description: description,
          durationMinutes: duration,
        );
        workoutId = await _dbHelper.insertWorkout(newWorkout);
        // // Сохранить упражнения с правильным workoutId
        // for (var exercise in _exercises) {
        //   final updatedExercise = Exercise(
        //     workoutId: workoutId,
        //     name: exercise.name,
        //     durationSeconds: exercise.durationSeconds,
        //   );
        //   await _dbHelper.insertExercise(updatedExercise);
        // }
        
        // Обновление ID тренировки для всех добавленных упражнений и сохранение их
        for (var i = 0; i < _exercises.length; i++) {
          _exercises[i] = Exercise(
            id: _exercises[i].id,
            workoutId: workoutId,
            name: _exercises[i].name,
            durationSeconds: _exercises[i].durationSeconds,
            youtubeUrl: _exercises[i].youtubeUrl,
          );
          // Если у упражнения уже есть IDто обновление иначе вставляем
          if (_exercises[i].id != null) {
              await _dbHelper.updateExercise(_exercises[i]);
          } else {
              await _dbHelper.insertExercise(_exercises[i]);
          }
        }
      } else {
        // Обновление существующей тренировки
        workoutId = widget.workout!.id!;
        final updatedWorkout = Workout(
          id: workoutId,
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

  Future<void> _addOrEditExercise([Exercise? exercise]) async {

    const String apiKey = String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');
    final nameController = TextEditingController(text: exercise?.name ?? '');
    final durationController =
        TextEditingController(text: exercise?.durationSeconds.toString() ?? '');
    String? youtubeUrl = exercise?.youtubeUrl;

    Timer? searchTimer;
    String? youtubeThumbnailUrl;
    bool isSearching = false;

    void searchYouTube(String query, StateSetter setState) {
      if (apiKey.isEmpty) {
        print('YouTube API key is not set. Skipping search.');
        return;
      }
      if (query.length < 3) {
        return;
      }

      setState(() {
        isSearching = true;
        youtubeThumbnailUrl = null;
        youtubeUrl = null;
      });

      http
          .get(
        Uri.parse(
            'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query exercise&type=video&maxResults=1&key=$apiKey'),
      )
          .then((response) {
        // отладка
        print('YouTube API Response Status: ${response.statusCode}');
        print('YouTube API Response Body: ${response.body}');
        // конец отладки

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['items'] != null && data['items'].isNotEmpty) {
            final videoId = data['items'][0]['id']['videoId'];
            setState(() {
              youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';
              youtubeThumbnailUrl =
                  data['items'][0]['snippet']['thumbnails']['high']['url'];
            });
          } else {
             print('YouTube API: No items found in response.');
          }
        } else {
          print('YouTube API Error: Failed to load video.');
        }
      }).whenComplete(() {
        setState(() {
          isSearching = false;
        });
      });
    }

    nameController.addListener(() {
      if (searchTimer?.isActive ?? false) searchTimer!.cancel();
      searchTimer = Timer(const Duration(seconds: 1), () {

      });
    });

    final result = await showDialog<Exercise?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {

            nameController.addListener(() {
              if (searchTimer?.isActive ?? false) searchTimer!.cancel();
              searchTimer = Timer(const Duration(seconds: 1), () {
                searchYouTube(nameController.text, setState);
              });
            });

            return AlertDialog(
              title: Text(exercise == null
                  ? 'Добавить упражнение'
                  : 'Редактировать упражнение'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Название'),
                    ),
                    TextField(
                      controller: durationController,
                      decoration: const InputDecoration(
                          labelText: 'Длительность (секунды)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    if (isSearching)
                      const CircularProgressIndicator()
                    else if (youtubeThumbnailUrl != null)
                      InkWell(
                        onTap: () async {
                          if (youtubeUrl != null) {
                            final uri = Uri.parse(youtubeUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                        child: Column(
                          children: [
                            Image.network(youtubeThumbnailUrl!),
                            const SizedBox(height: 4),
                            const Text(
                              'Нажмите, чтобы открыть видео',
                              style: TextStyle(color: Colors.blue, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final durationText = durationController.text.trim();
                    final duration = int.tryParse(durationText);

                    if (name.isNotEmpty && duration != null && duration > 0) {
                      final ex = Exercise(
                        id: exercise?.id,
                        workoutId: _workoutId,
                        name: name,
                        durationSeconds: duration,
                        youtubeUrl: youtubeUrl,
                      );
                      Navigator.of(context).pop(ex);
                    }
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      if (result.id == null) {
        // Новое
        await _dbHelper.insertExercise(result);
      } else {
        // Обновление
        await _dbHelper.updateExercise(result);
      }
      _loadExercises();
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
                    leading: (exercise.youtubeUrl != null && exercise.youtubeUrl!.isNotEmpty)
                        ? const Icon(Icons.smart_display, color: Colors.red)
                        : const Icon(Icons.smart_display, color: Colors.grey),
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
                          onPressed: () {
                            final exerciseId = exercise.id;
                            if (exerciseId != null) {
                              _deleteExercise(exerciseId);
                            }
                          },
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
