import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:thai_safe/core/services/safety_functions_repository.dart';

class IncidentOutboxItem {
  const IncidentOutboxItem({
    required this.clientRequestId,
    required this.request,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  final String clientRequestId;
  final QuickIncidentRequest request;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
}

class IncidentOutbox {
  IncidentOutbox._();

  static final instance = IncidentOutbox._();
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final path = '${await getDatabasesPath()}/thai_safe_outbox.db';
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (database, _) async {
        await database.execute('''
          CREATE TABLE incident_outbox (
            client_request_id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
        ''');
      },
    );
    return _database!;
  }

  Future<void> put(QuickIncidentRequest request, {String? error}) async {
    final database = await _db;
    await database.insert('incident_outbox', {
      'client_request_id': request.clientRequestId,
      'payload': jsonEncode(request.toJson()),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'attempts': 0,
      'last_error': error,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<IncidentOutboxItem>> pending() async {
    final database = await _db;
    final rows = await database.query(
      'incident_outbox',
      orderBy: 'created_at ASC',
      limit: 25,
    );
    return rows
        .map((row) {
          final request = QuickIncidentRequest.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(row['payload']! as String) as Map,
            ),
          );
          return IncidentOutboxItem(
            clientRequestId: row['client_request_id']! as String,
            request: request,
            createdAt: DateTime.parse(row['created_at']! as String),
            attempts: row['attempts']! as int,
            lastError: row['last_error'] as String?,
          );
        })
        .toList(growable: false);
  }

  Future<int> count() async {
    final database = await _db;
    return Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM incident_outbox'),
        ) ??
        0;
  }

  Future<void> markSent(String clientRequestId) async {
    final database = await _db;
    await database.delete(
      'incident_outbox',
      where: 'client_request_id = ?',
      whereArgs: [clientRequestId],
    );
  }

  Future<void> markFailed(String clientRequestId, Object error) async {
    final database = await _db;
    await database.rawUpdate(
      '''
        UPDATE incident_outbox
        SET attempts = attempts + 1, last_error = ?
        WHERE client_request_id = ?
      ''',
      [
        error.toString().substring(0, error.toString().length.clamp(0, 500)),
        clientRequestId,
      ],
    );
  }
}
