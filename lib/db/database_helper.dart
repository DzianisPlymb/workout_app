import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/user.dart';
import '../models/workout.dart';
import '../models/exercise.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'workout_app.db');

    // Открываем или создаём базу
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица пользователей
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Таблица тренировок
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        duration_minutes INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Таблица упражнений
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES workouts (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Добавляем таблицу exercises для версии 2
      await db.execute('''
        CREATE TABLE exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workout_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          duration_seconds INTEGER NOT NULL,
          FOREIGN KEY (workout_id) REFERENCES workouts (id)
        )
      ''');
    }
  }

  // ---------- Методы для пользователей ----------

  Future<int> registerUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> loginUser(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // ---------- Методы для тренировок ----------

  Future<int> insertWorkout(Workout workout) async {
    final db = await database;
    return await db.insert('workouts', workout.toMap());
  }

  Future<List<Workout>> getWorkoutsForUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'workouts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return result.map((e) => Workout.fromMap(e)).toList();
  }

  Future<int> updateWorkout(Workout workout) async {
    final db = await database;
    return await db.update(
      'workouts',
      workout.toMap(),
      where: 'id = ?',
      whereArgs: [workout.id],
    );
  }

  Future<int> deleteWorkout(int id) async {
    final db = await database;
    return await db.delete(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------- Методы для упражнений ----------

  Future<int> insertExercise(Exercise exercise) async {
    final db = await database;
    return await db.insert('exercises', exercise.toMap());
  }

  Future<List<Exercise>> getExercisesForWorkout(int workoutId) async {
    final db = await database;
    final result = await db.query(
      'exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
    return result.map((e) => Exercise.fromMap(e)).toList();
  }

  Future<int> updateExercise(Exercise exercise) async {
    final db = await database;
    return await db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<int> deleteExercise(int id) async {
    final db = await database;
    return await db.delete(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
