import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/class_service.dart';

class ClassProvider with ChangeNotifier {
  final ClassService _classService = ClassService();
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _studentList = [];
  int _totalStudents = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> get classes => _classes;
  List<Map<String, dynamic>> get studentList => _studentList;
  int get totalStudents => _totalStudents;
  bool get isLoading => _isLoading;

  Future<void> fetchClasses(String userId, String role) async {
    _isLoading = true;
    // notifyListeners();
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
        print('Classes fetched: $_classes');
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

  Future<void> deleteClass(String classId) async {
    try {
      await _classService.deleteClass(classId);
      notifyListeners();
    } catch (e) {
      print('Error deleting class: $e');
    }
  }

  Future<void> getStudentList({required String classId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      print('Fetching student list for class: $classId');
      QuerySnapshot<Object?>? snapshot =
          await _classService.getStudentDetails(classId);

      _studentList = snapshot!.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        print('Student data: $data');
        return data;
      }).toList();

      _totalStudents = _studentList.length;
      print('Fetched $_totalStudents students');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error getting student list: $e');
      _isLoading = false;
      _studentList = [];
      _totalStudents = 0;
      notifyListeners();
    }
  }
}
