import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('attendify.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const intType = 'INTEGER NOT NULL';
    const textType = 'TEXT NOT NULL';
    const textNullType = 'TEXT';

    // Classes table
    await db.execute('''
      CREATE TABLE classes (
        id $idType,
        name $textType,
        code $textType,
        description $textNullType,
        schedule $textNullType,
        teacher_name $textNullType,
        synced $intType DEFAULT 0,
        created_at $textType,
        updated_at $textType
      )
    ''');

    // Attendance records table
    await db.execute('''
      CREATE TABLE attendance_records (
        id $idType,
        class_id $intType,
        class_name $textType,
        date $textType,
        status $textType,
        checked_in_at $textNullType,
        session_id $intType,
        synced $intType DEFAULT 0,
        created_at $textType
      )
    ''');

    // Attendance summary table
    await db.execute('''
      CREATE TABLE attendance_summary (
        id $idType,
        total_sessions $intType,
        present $intType,
        absent $intType,
        late $intType,
        attendance_rate REAL NOT NULL,
        updated_at $textType
      )
    ''');

    // Excuse requests table
    await db.execute('''
      CREATE TABLE excuse_requests (
        id $idType,
        class_id $intType,
        class_name $textType,
        date $textType,
        type $textType,
        reason $textType,
        status $textType,
        response $textNullType,
        attachment_url $textNullType,
        synced $intType DEFAULT 0,
        created_at $textType
      )
    ''');

    // Today's schedule table
    await db.execute('''
      CREATE TABLE schedule (
        id $idType,
        class_id $intType,
        class_name $textType,
        time $textType,
        room $textNullType,
        day $textType,
        updated_at $textType
      )
    ''');

    // Chat messages table (for offline chatbot)
    await db.execute('''
      CREATE TABLE chat_messages (
        id $textType,
        content $textType,
        is_user $intType,
        timestamp $textType,
        session_id $textNullType,
        synced $intType DEFAULT 0
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id $idType,
        table_name $textType,
        record_id $intType,
        operation $textType,
        data $textType,
        created_at $textType
      )
    ''');

    // Teacher-specific tables
    await db.execute('''
      CREATE TABLE teacher_classes (
        id $idType,
        name $textType,
        code $textType,
        enrolled_count $intType,
        schedule $textNullType,
        updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_sessions (
        id $idType,
        class_id $intType,
        class_name $textType,
        start_time $textType,
        end_time $textType,
        status $textType,
        qr_code $textNullType,
        present_count $intType,
        absent_count $intType,
        late_count $intType,
        updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE class_students (
        id $idType,
        class_id $intType,
        name $textType,
        email $textType,
        student_id $textType,
        attendance_rate REAL,
        present_count $intType,
        absent_count $intType,
        late_count $intType,
        updated_at $textType
      )
    ''');

    // Admin-specific tables
    await db.execute('''
      CREATE TABLE admin_users (
        id $idType,
        name $textType,
        email $textType,
        role $textType,
        created_at $textType,
        updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE admin_classes (
        id $idType,
        name $textType,
        code $textType,
        description $textNullType,
        teacher_name $textNullType,
        enrolled_count $intType,
        updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE system_stats (
        id $idType,
        total_users $intType,
        total_students $intType,
        total_teachers $intType,
        total_classes $intType,
        total_sessions $intType,
        average_attendance REAL,
        updated_at $textType
      )
    ''');
  }

  // Generic methods
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await instance.database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await instance.database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<dynamic> whereArgs) async {
    final db = await instance.database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> clearTable(String table) async {
    final db = await instance.database;
    await db.delete(table);
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
