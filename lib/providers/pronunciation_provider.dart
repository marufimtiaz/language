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
  String _currentClassId = '';

  List<String> get pronunciations => _pronunciations;
  List<Map<String, dynamic>> get classPronunciations => _classPronunciations;
  String? get currentPronunciationText => _currentPronunciationText;
  int get currentPronunciationIndex => _currentPronunciationIndex;

  Future<void> fetchPronunciations() async {
    _pronunciations = await _pronunciationService.fetchPronunciations();
    notifyListeners();
  }

  Future<void> fetchClassPronunciations(String classId) async {
    _currentClassId = classId;
    _classPronunciations =
        await _pronunciationService.fetchPronunciationList(classId);
    notifyListeners();
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

  Future<void> deletePronunciation(int pronunciationIndex) async {
    final result = await _pronunciationService.deletePronunciation(
        _currentClassId, pronunciationIndex);
    if (result) {
      await fetchClassPronunciations(_currentClassId);
    }
  }

  Future<void> submitPronunciation(
      int pronunciationIndex, String studentAudio) async {
    final result = await _pronunciationService.submitPronunciation(
        _currentClassId, pronunciationIndex, studentAudio);
    if (result) {
      await fetchClassPronunciations(_currentClassId);
    }
  }

  Future<void> setCurrentPronunciation(int index) async {
    _currentPronunciationIndex = index;
    _currentPronunciationText = await _pronunciationService
        .fetchPronunciationText(_currentClassId, index);
    notifyListeners();
  }

  Future<bool> isPronunciationDone(int pronunciationIndex) async {
    return await _pronunciationService.isPronunciationDone(
        _currentClassId, pronunciationIndex);
  }

  bool isActive(Map<String, dynamic> pronunciation) {
    return _pronunciationService.isActive(pronunciation);
  }

  Future<int> getPronunciationSubmissionCount(int pronunciationIndex) async {
    return await _pronunciationService.getPronunciationSubmissionCount(
        _currentClassId, pronunciationIndex);
  }

  String? get currentUserId => _auth.currentUser?.uid;
}
