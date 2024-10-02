import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/quiz_service.dart';

class QuizProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();
  List<Map<String, dynamic>> _quizzes = [];
  int _totalStudents = 0;
  List<String> _studentIds = [];
  List<int> _scores = [];
  List<Map<String, dynamic>> _studentList = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get quizzes => _quizzes;
  List<String> get studentIds => _studentIds;
  List<int> get scores => _scores;
  List<Map<String, dynamic>> get studentList => _studentList;
  int get totalStudents => _totalStudents;
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

  Future<bool> updateQuizDate(
      String classId, int quizIndex, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();
    try {
      bool result =
          await _quizService.updateQuizDate(classId, quizIndex, endDate);
      if (result) {
        await fetchQuizList(classId);
        _isLoading = false;
        notifyListeners();
      }
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      print('Error updating quiz date: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  //get submissionIds
  Future<List<String>> getSubmissionIds(String classId, int quizIndex) async {
    return await _quizService.getSubmissionIds(classId, quizIndex);
  }

  Future<List<int>> getScores(String classId, int quizIndex) async {
    _scores = await _quizService.getScores(classId, quizIndex);
    return _scores;
  }

  Future<void> getStudentList(
      {required String classId, required int quizIndex}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _studentIds = await _quizService.getSubmissionIds(classId, quizIndex);

      QuerySnapshot<Object?>? snapshot =
          await _quizService.studentDetails(_studentIds);
      _studentList = snapshot!.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        print('Student data: $data');
        return data;
      }).toList();
      if (_studentList.isEmpty) {
        _totalStudents = 0;
      } else {
        _totalStudents = _studentList.length;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error getting student list: $e');
      _totalStudents = 0;
      _studentList = [];
      _isLoading = false;
      notifyListeners();
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

  Future<QuerySnapshot?>? studentDetails(List<dynamic> studentIds) {
    try {
      return _quizService.studentDetails(studentIds);
    } catch (e) {
      print('Error getting student details: $e');
      return null;
    }
  }
}
