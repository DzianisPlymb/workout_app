import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../db/database_helper.dart';
import 'add_workout_screen.dart';
import 'login_screen.dart';
import 'workout_execution_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<Workout> _workouts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      _isLoading = true;
    });
    final list = await _dbHelper.getWorkoutsForUser(widget.user.id!);
    setState(() {
      _workouts = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteWorkout(int id) async {
    await _dbHelper.deleteWorkout(id);
    await _loadWorkouts();
  }

  Future<void> _startWorkout(Workout workout) async {
    final exercises = await _dbHelper.getExercisesForWorkout(workout.id!);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutExecutionScreen(
          workout: workout,
          exercises: exercises,
        ),
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openAddWorkout([Workout? workout]) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddWorkoutScreen(
          user: widget.user,
          workout: workout,
        ),
      ),
    );

    // Если тренировку добавили илиобновили — пперезагрузка списка
    if (result == true) {
      await _loadWorkouts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мои тренировки (${widget.user.username})'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workouts.isEmpty
              ? const Center(
                  child: Text('Пока нет тренировок. Добавьте первую!'),
                )
              : ListView.builder(
                  itemCount: _workouts.length,
                  itemBuilder: (context, index) {
                    final w = _workouts[index];
                    return ListTile(
                      title: Text(w.title),
                      subtitle: Text(
                          'Длительность: ${w.durationMinutes} мин\n${w.description}'),
                      isThreeLine: true,
                      onTap: () => _openAddWorkout(w),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow, color: Colors.green),
                            onPressed: () => _startWorkout(w),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              final workoutId = w.id;
                              if (workoutId != null) {
                                _deleteWorkout(workoutId);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddWorkout(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
