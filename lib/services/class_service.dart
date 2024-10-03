import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

import '../utils/ui_utils.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> createClass(String className) async {
    var uuid = const Uuid().v4().substring(0, 8);
    var classId = uuid.toUpperCase();

    var user = _auth.currentUser;

    if (user != null) {
      try {
        await _firestore.collection('classes').doc(classId).set({
          'name': className,
          'classId': classId,
          'teacherId': user.uid,
          'studentIds': [],
          'dateCreated': FieldValue.serverTimestamp(),
        });
        return classId;
      } catch (e) {
        UIUtils.showToast(msg: "Error creating class: $e");
        return null;
      }
    } else {
      UIUtils.showToast(msg: "Error: User not found");
      return null;
    }
  }

  Future<void> deleteClass(String classId) async {
    try {
      final FirebaseStorage _storage = FirebaseStorage.instance;
      await _storage.ref('audio/$classId/').listAll().then((result) {
        for (var file in result.items) {
          file.delete();
        }
        for (var folder in result.prefixes) {
          folder.listAll().then((subResult) {
            for (var subFile in subResult.items) {
              subFile.delete();
            }
          });
        }
      });

      await _firestore.collection('classes').doc(classId).delete();
      UIUtils.showToast(msg: "Class deleted successfully");
    } catch (e) {
      UIUtils.showToast(msg: "Error deleting class: $e");
    }
  }

  Future<void> renameClass(String classId, String newClassName) async {
    try {
      await _firestore.collection('classes').doc(classId).update({
        'name': newClassName,
      });
      UIUtils.showToast(msg: "Class renamed successfully");
    } catch (e) {
      UIUtils.showToast(msg: "Error renaming class: $e");
    }
  }

  Future<String?> getClassName(String classId) async {
    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        return null;
      }
      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      return classData['name'];
    } catch (e) {
      UIUtils.showToast(msg: "Error getting class name: $e");
      return null;
    }
  }

  Stream<QuerySnapshot> getTeacherClasses(String? teacherId) {
    return _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('dateCreated', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getStudentClasses(String? studentId) {
    return _firestore
        .collection('classes')
        .where('studentIds', arrayContains: studentId)
        .orderBy('dateCreated', descending: true)
        .snapshots();
  }

  Future<bool> joinClass(String classId) async {
    var user = _auth.currentUser;
    if (user == null) {
      UIUtils.showToast(msg: "Error: User not found");
      return false;
    }

    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();

      if (!classDoc.exists) {
        UIUtils.showToast(msg: "Error: Class not found");
        return false;
      }

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> studentIds = classData['studentIds'] ?? [];

      if (studentIds.contains(user.uid)) {
        UIUtils.showToast(msg: "You are already in this class");
        return false;
      }

      await _firestore.collection('classes').doc(classId).update({
        'studentIds': FieldValue.arrayUnion([user.uid])
      });

      UIUtils.showToast(msg: "Successfully joined the class");
      return true;
    } catch (e) {
      UIUtils.showToast(msg: "Error joining class: $e");
      return false;
    }
  }

  Future<bool> removeStudentFromClass(String classId, String studentId) async {
    var user = _auth.currentUser;
    if (user == null) {
      UIUtils.showToast(msg: "Error: User not found");
      return false;
    }

    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();

      if (!classDoc.exists) {
        UIUtils.showToast(msg: "Error: Class not found");
        return false;
      }

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;

      // Check if the current user is the teacher of the class
      if (classData['teacherId'] != user.uid) {
        UIUtils.showToast(msg: "Error: Only the teacher can remove students");
        return false;
      }

      List<dynamic> studentIds = classData['studentIds'] ?? [];

      if (!studentIds.contains(studentId)) {
        UIUtils.showToast(msg: "Student is not in this class");
        return false;
      }

      await _firestore.collection('classes').doc(classId).update({
        'studentIds': FieldValue.arrayRemove([studentId])
      });

      UIUtils.showToast(msg: "Student removed from the class successfully");
      return true;
    } catch (e) {
      UIUtils.showToast(msg: "Error removing student from class: $e");
      return false;
    }
  }

  Future<bool> leaveClass(String classId) async {
    var user = _auth.currentUser;
    if (user == null) {
      UIUtils.showToast(msg: "Error: User not found");
      return false;
    }

    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();

      if (!classDoc.exists) {
        UIUtils.showToast(msg: "Error: Class not found");
        return false;
      }

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> studentIds = classData['studentIds'] ?? [];

      if (!studentIds.contains(user.uid)) {
        UIUtils.showToast(msg: "You are not in this class");
        return false;
      }

      await _firestore.collection('classes').doc(classId).update({
        'studentIds': FieldValue.arrayRemove([user.uid])
      });

      UIUtils.showToast(msg: "Successfully left the class");
      return true;
    } catch (e) {
      UIUtils.showToast(msg: "Error leaving class: $e");
      return false;
    }
  }

  Future<QuerySnapshot?> getStudentDetails(String classId) async {
    try {
      print('Fetching students for class: $classId');

      // First, get the class document to retrieve the list of student IDs
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();

      if (!classDoc.exists) {
        print('Class document does not exist for ID: $classId');
        return null;
      }
      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> studentIds = classData['studentIds'] ?? [];

      print('Student IDs found in class: $studentIds');

      if (studentIds.isEmpty) {
        print('No students in this class');
        return null;
      }

      // Now fetch the user documents for these student IDs
      QuerySnapshot studentDocs = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: studentIds)
          .get();

      print('Fetched ${studentDocs.docs.length} student documents');

      return studentDocs;
    } catch (e) {
      print('Error in getStudentDetails: $e');
      rethrow;
    }
  }

  //get total students from cllasses collection studentIds array
  Future<int> getTotalStudents(String classId) async {
    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        return 0;
      }
      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> studentIds = classData['studentIds'] ?? [];
      return studentIds.length;
    } catch (e) {
      UIUtils.showToast(msg: "Error getting total students: $e");
      return 0;
    }
  }
}
