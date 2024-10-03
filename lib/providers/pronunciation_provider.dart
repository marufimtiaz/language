import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pronunciation_service.dart';

class PronunciationProvider extends ChangeNotifier {
  final PronunciationService _pronunciationService = PronunciationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _pronunciations = [];
  List<Map<String, dynamic>> _classPronunciations = [];
  String? _currentPronunciationText;
  int _currentPronunciationIndex = -1;

  int _totalStudents = 0;
  final List<String> _studentIds = [];
  List<int> _scores = [];
  List<String> _studentAudio = [];
  List<Map<String, dynamic>> _studentList = [];
  bool _isLoading = false;

  int get totalStudents => _totalStudents;
  List<String> get studentIds => _studentIds;
  List<int> get scores => _scores;
  List<String> get studentAudio => _studentAudio;
  List<Map<String, dynamic>> get studentList => _studentList;
  bool get isLoading => _isLoading;

  List<String> get pronunciations => _pronunciations;
  List<Map<String, dynamic>> get classPronunciations => _classPronunciations;
  String? get currentPronunciationText => _currentPronunciationText;
  int get currentPronunciationIndex => _currentPronunciationIndex;

  Future<void> fetchPronunciations() async {
    _pronunciations = await _pronunciationService.fetchPronunciations();
    notifyListeners();
  }

  Future<void> fetchClassPronunciations(String classId) async {
    _isLoading = true;
    try {
      _classPronunciations =
          await _pronunciationService.fetchPronunciationList(classId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching class pronunciations(provider): $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createPronunciation(String classId, int textIndex,
      String teacherAudio, DateTime endDate) async {
    try {
      String? result = await _pronunciationService.createPronunciation(
          classId, textIndex, teacherAudio, endDate);
      if (result != null) {
        await fetchClassPronunciations(classId);
      }
      return result;
    } catch (e) {
      print('Error creating pronunciation(provider): $e');
    }
    return null;
  }

  Future<bool> updatePronunciationDate(
      String classId, int pronunciationIndex, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();
    final result = await _pronunciationService.updatePronunciationDate(
        classId, pronunciationIndex, endDate);
    if (result) {
      await fetchClassPronunciations(classId);
      _isLoading = false;
      notifyListeners();
    }
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> deletePronunciation(
      String classId, int pronunciationIndex) async {
    final result = await _pronunciationService.deletePronunciation(
        classId, pronunciationIndex);
    if (result) {
      await fetchClassPronunciations(classId);
    }
  }

  Future<bool> submitPronunciation(
      String classId, int pronunciationIndex, String studentAudio) async {
    final result = await _pronunciationService.submitPronunciation(
        classId, pronunciationIndex, studentAudio);
    if (result) {
      await fetchClassPronunciations(classId);
    }
    return result;
  }

  Future<void> setCurrentPronunciation(String classId, int index) async {
    _currentPronunciationIndex = index;
    _currentPronunciationText =
        await _pronunciationService.fetchPronunciationText(classId, index);
    notifyListeners();
  }

  Future<String?> fetchPronunciationAudio(
      String classId, int pronunciationIndex) async {
    return await _pronunciationService.fetchPronunciationAudio(
        classId, pronunciationIndex);
  }

  // fetchpronunciationText
  Future<String?> fetchPronunciationText(
      String classId, int pronunciationIndex) async {
    return await _pronunciationService.fetchPronunciationText(
        classId, pronunciationIndex);
  }

  Future<bool> isPronunciationDone(
      String classId, int pronunciationIndex) async {
    return await _pronunciationService.isPronunciationDone(
        classId, pronunciationIndex);
  }

  bool isActive(Map<String, dynamic> pronunciation) {
    return _pronunciationService.isActive(pronunciation);
  }

  Future<int> getPronunciationSubmissionCount(
      String classId, int pronunciationIndex) async {
    return await _pronunciationService.getPronunciationSubmissionCount(
        classId, pronunciationIndex);
  }

  Future<List<String>> getSubmissionIds(
      String classId, int pronunciationIndex) async {
    return await _pronunciationService.getSubmissionIds(
        classId, pronunciationIndex);
  }

  Future<List<int>> getScores(String classId, int pronunciationIndex) async {
    _scores =
        await _pronunciationService.getScores(classId, pronunciationIndex);
    return _scores;
  }

  Future<List<String>> getStudentAudio(
      String classId, int pronunciationIndex) async {
    _studentAudio = await _pronunciationService.getStudentAudios(
        classId, pronunciationIndex);
    return _studentAudio;
  }

  Future<void> setScore(String classId, int pronunciationIndex,
      int submissionIndex, int score) async {
    _scores[submissionIndex] = score;
    notifyListeners();
    await _pronunciationService.setScore(
        classId, pronunciationIndex, submissionIndex, score);
    getScores(classId, pronunciationIndex);
    notifyListeners();
  }

  Future<void> getStudentList(
      {required String classId, required int pronunciationIndex}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _studentList = await _pronunciationService.getStudentList(
          classId: classId, pronunciationIndex: pronunciationIndex);
      _totalStudents = _studentList.length;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error getting student list(provider): $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> getStudentScore(String classId, int pronunciationIndex) async {
    _isLoading = true;
    notifyListeners();
    int studentScore = await _pronunciationService.getStudentScore(
        classId, pronunciationIndex);
    _isLoading = false;
    notifyListeners();
    return studentScore;
  }

  String? get currentUserId => _auth.currentUser?.uid;
}
