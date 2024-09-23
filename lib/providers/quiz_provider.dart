import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/quiz_service.dart';

class QuizProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();
  List<Map<String, dynamic>> _quizzes = [];
  Map<String, dynamic>? _currentQuizDetails;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get quizzes => _quizzes;
  Map<String, dynamic>? get currentQuizDetails => _currentQuizDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchQuizzes(String classId) async {
    _isLoading = true;
    // notifyListeners();

    try {
      Stream<QuerySnapshot> quizStream = _quizService.getClassQuizzes(classId);

      quizStream.listen((snapshot) {
        _quizzes = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _isLoading = false;
        notifyListeners();
        print('Quizzes fetched: $_quizzes');
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error fetching quizzes: $e');
    }
  }

  Future<String?> createQuiz(String classId,
      List<Map<String, dynamic>> questions, DateTime endDate) async {
    try {
      String? quizId =
          await _quizService.createQuiz(classId, questions, endDate);
      if (quizId != null) {
        Map<String, dynamic> newQuiz = {
          'quizId': quizId,
          'classId': classId,
          'questions': questions,
          'endDate': endDate,
          'dateCreated': DateTime.now(),
        };
        _quizzes.add(newQuiz);
        notifyListeners();
      }
      return quizId;
    } catch (e) {
      _error = 'Failed to create quiz: $e';
      notifyListeners();
      print('Error creating quiz: $e');
      return null;
    }
  }

  Future<bool> isQuizDone(String quizId, String studentId) async {
    return await _quizService.isQuizDone(quizId, studentId);
  }

  Future<void> fetchQuizDetails(String quizId) async {
    _isLoading = true;
    _error = null;
    // notifyListeners();

    try {
      _currentQuizDetails = await _quizService.getQuizDetails(quizId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load quiz details: $e';
      notifyListeners();
      print('Error fetching quiz details: $e');
    }
  }

  Future<void> submitQuiz(String quizId, String studentId,
      List<Map<String, dynamic>> answers) async {
    try {
      await _quizService.submitQuiz(quizId, studentId, answers);
      int quizIndex = _quizzes.indexWhere((quiz) => quiz['quizId'] == quizId);
      if (quizIndex != -1) {
        _quizzes[quizIndex]['doneCount'] =
            (_quizzes[quizIndex]['doneCount'] ?? 0) + 1;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to submit quiz: $e';
      notifyListeners();
      print('Error submitting quiz: $e');
    }
  }

  void clearCurrentQuizDetails() {
    _currentQuizDetails = null;
    notifyListeners();
  }
}
