import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/class_service.dart';

class ClassProvider with ChangeNotifier {
  final ClassService _classService = ClassService();
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get classes => _classes;
  bool get isLoading => _isLoading;

  Future<void> fetchClasses(String userId, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      Stream<QuerySnapshot> classStream = role == 'Teacher'
          ? _classService.getTeacherClasses(userId)
          : _classService.getStudentClasses(userId);

      classStream.listen((snapshot) {
        _classes = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error fetching classes: $e');
    }
  }

  Future<String?> createClass(String className) async {
    try {
      return await _classService.createClass(className);
    } catch (e) {
      print('Error creating class: $e');
      return null;
    }
  }

  Future<void> joinClass(String classId) async {
    try {
      await _classService.joinClass(classId);
      notifyListeners();
    } catch (e) {
      print('Error joining class: $e');
    }
  }

  Stream<Map<String, dynamic>> getClassStream(String classId) {
    return _classService.getClassStream(classId);
  }
}
