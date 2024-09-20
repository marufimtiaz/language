import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

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
        Fluttertoast.showToast(msg: "Error creating class: $e");
        return null;
      }
    } else {
      Fluttertoast.showToast(msg: "Error: User not found");
      return null;
    }
  }

  Future<void> deleteClass(String classId) async {
    try {
      await _firestore.collection('classes').doc(classId).delete();
      Fluttertoast.showToast(msg: "Class deleted successfully");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error deleting class: $e");
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
      Fluttertoast.showToast(msg: "Error: User not found");
      return false;
    }

    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();

      if (!classDoc.exists) {
        Fluttertoast.showToast(msg: "Error: Class not found");
        return false;
      }

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> studentIds = classData['studentIds'] ?? [];

      if (studentIds.contains(user.uid)) {
        Fluttertoast.showToast(msg: "You are already in this class");
        return false;
      }

      await _firestore.collection('classes').doc(classId).update({
        'studentIds': FieldValue.arrayUnion([user.uid])
      });

      Fluttertoast.showToast(msg: "Successfully joined the class");
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: "Error joining class: $e");
      return false;
    }
  }

  Future<bool> removeStudentFromClass(String classId, String studentId) async {
    var user = _auth.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: "Error: User not found");
      return false;
    }

    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();

      if (!classDoc.exists) {
        Fluttertoast.showToast(msg: "Error: Class not found");
        return false;
      }

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;

      // Check if the current user is the teacher of the class
      if (classData['teacherId'] != user.uid) {
        Fluttertoast.showToast(
            msg: "Error: Only the teacher can remove students");
        return false;
      }

      List<dynamic> studentIds = classData['studentIds'] ?? [];

      if (!studentIds.contains(studentId)) {
        Fluttertoast.showToast(msg: "Student is not in this class");
        return false;
      }

      await _firestore.collection('classes').doc(classId).update({
        'studentIds': FieldValue.arrayRemove([studentId])
      });

      Fluttertoast.showToast(
          msg: "Student removed from the class successfully");
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: "Error removing student from class: $e");
      return false;
    }
  }

  Future<bool> leaveClass(String classId) async {
    var user = _auth.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: "Error: User not found");
      return false;
    }

    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();

      if (!classDoc.exists) {
        Fluttertoast.showToast(msg: "Error: Class not found");
        return false;
      }

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> studentIds = classData['studentIds'] ?? [];

      if (!studentIds.contains(user.uid)) {
        Fluttertoast.showToast(msg: "You are not in this class");
        return false;
      }

      await _firestore.collection('classes').doc(classId).update({
        'studentIds': FieldValue.arrayRemove([user.uid])
      });

      Fluttertoast.showToast(msg: "Successfully left the class");
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: "Error leaving class: $e");
      return false;
    }
  }

  Future<List<Map<String, String>>> getStudentDetails(String classId) async {
    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      List<String> studentIds = List<String>.from(classDoc['studentIds'] ?? []);

      List<Map<String, String>> studentDetails = [];
      for (String studentId in studentIds) {
        DocumentSnapshot studentDoc =
            await _firestore.collection('users').doc(studentId).get();
        Map<String, dynamic> userData =
            studentDoc.data() as Map<String, dynamic>;
        studentDetails.add({
          'id': studentId,
          'name': userData['name'] ?? 'Unknown',
          'email': userData['email'] ?? 'No email'
        });
      }

      return studentDetails;
    } catch (e) {
      print('Error fetching student details: $e');
      return [];
    }
  }

  Stream<Map<String, dynamic>> getClassStream(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .snapshots()
        .asyncMap((classSnapshot) async {
      if (!classSnapshot.exists) {
        return {};
      }

      Map<String, dynamic> classData =
          classSnapshot.data() as Map<String, dynamic>;
      List<Map<String, String>> studentDetails =
          await getStudentDetails(classId);

      classData['studentDetails'] = studentDetails;
      return classData;
    });
  }

  Future<int> getTotalStudents(String classId) async {
    DocumentSnapshot classSnapshot =
        await _firestore.collection('classes').doc(classId).get();
    if (!classSnapshot.exists) {
      return 0;
    }

    Map<String, dynamic> classData =
        classSnapshot.data() as Map<String, dynamic>;
    List<dynamic> studentIds = classData['studentIds'] ?? [];
    return studentIds.length;
  }
}
