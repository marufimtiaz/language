import 'package:flutter/material.dart';

import '../services/quiz_service.dart';

class QuizProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get quizzes => _quizzes;
  bool get isLoading => _isLoading;

  Future<void> fetchQuizList(String classId) async {
    _isLoading = true;
    // notifyListeners();

    try {
      _quizzes = await _quizService.fetchQuizList(classId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching quizzes: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // fetchQuizQuestions
  Future<List<Map<String, dynamic>>> fetchQuizQuestions(
      String classId, int quizIndex) async {
    try {
      return await _quizService.fetchQuizQuestions(classId, quizIndex);
    } catch (e) {
      print('Error fetching quiz questions: $e');
      return [];
    }
  }

  // fetchquestions
  Future<List<Map<String, dynamic>>> fetchQuestions() async {
    return await _quizService.fetchQuestions();
  }

  Future<String?> createQuiz(
      String classId, List<int> questionIds, DateTime endDate) async {
    try {
      String? result =
          await _quizService.createQuiz(classId, questionIds, endDate);
      if (result != null) {
        await fetchQuizList(classId);
      }
      return result;
    } catch (e) {
      print('Error creating quiz: $e');
      return null;
    }
  }

  Future<bool> deleteQuiz(String classId, int quizIndex) async {
    try {
      bool result = await _quizService.deleteQuiz(classId, quizIndex);
      if (result) {
        await fetchQuizList(classId);
      }
      return result;
    } catch (e) {
      print('Error deleting quiz: $e');
      return false;
    }
  }

  Future<bool> submitQuiz(String classId, int quizIndex, int score) async {
    try {
      bool result = await _quizService.submitQuiz(classId, quizIndex, score);
      if (result) {
        await fetchQuizList(classId);
      }
      return result;
    } catch (e) {
      print('Error submitting quiz: $e');
      return false;
    }
  }

  Future<bool> isQuizDone(String classId, int quizIndex) async {
    return await _quizService.isQuizDone(classId, quizIndex);
  }

  bool isActive(Map<String, dynamic> quiz) {
    return _quizService.isActive(quiz);
  }

  Future<int> getQuizSubmissionCount(String classId, int quizIndex) async {
    return await _quizService.getQuizSubmissionCount(classId, quizIndex);
  }
}
