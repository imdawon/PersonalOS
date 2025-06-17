import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity_session.dart';
import '../models/classification_request.dart';
import '../models/today_summary.dart';

class ApiService {
  final String _baseUrl = "http://127.0.0.1:8085/api/v0";

  Future<List<ActivitySession>> getUnclassifiedSessions() async {
    final response = await http.get(Uri.parse('$_baseUrl/unclassified-sessions'));

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => ActivitySession.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load unclassified sessions');
    }
  }

  Future<List<TodaySummaryItem>> getTodaySummary() async {
    final response = await http.get(Uri.parse('$_baseUrl/today-summary'));
     if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => TodaySummaryItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load today summary');
    }
  }

  Future<void> classifySession(ClassificationRequest request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/classify'),
      headers: {'Content-Type': 'application/json'},
      body: request.toJson(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to classify session');
    }
  }

  Future<void> classifySessionBatch(BatchClassificationRequest request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/classify-batch'),
      headers: {'Content-Type': 'application/json'},
      body: request.toJson(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to classify batch');
    }
  }
}