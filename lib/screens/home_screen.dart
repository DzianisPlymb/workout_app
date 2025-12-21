import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/workout.dart';
import '../db/database_helper.dart';
import 'add_workout_screen.dart';
import 'login_screen.dart';

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

    // Если тренировку добавили/обновили — перезагрузим список
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
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteWorkout(w.id!),
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
