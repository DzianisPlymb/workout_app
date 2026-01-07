import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/workout.dart';
import '../models/exercise.dart';
import '../widgets/exercise_timer.dart';

class WorkoutExecutionScreen extends StatelessWidget {
  final Workout workout;
  final List<Exercise> exercises;

  const WorkoutExecutionScreen({
    super.key,
    required this.workout,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(workout.title),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (exercise.youtubeUrl != null &&
                          exercise.youtubeUrl!.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.smart_display,
                              color: Colors.red, size: 30),
                          onPressed: () async {
                            final uri = Uri.parse(exercise.youtubeUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ExerciseTimer(durationSeconds: exercise.durationSeconds),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}