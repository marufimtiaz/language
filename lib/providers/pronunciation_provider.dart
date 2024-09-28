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

  bool _isLoading = false;

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

  String? get currentUserId => _auth.currentUser?.uid;
}
