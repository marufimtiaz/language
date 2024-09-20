import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> createQuiz(String classId,
      List<Map<String, dynamic>> questions, DateTime endDate) async {
    var uuid = const Uuid().v4().substring(0, 8);
    var quizId = uuid.toUpperCase();

    var user = _auth.currentUser;

    if (user != null) {
      try {
        await _firestore.collection('quizzes').doc(quizId).set({
          'quizId': quizId,
          'classId': classId,
          'teacherId': user.uid,
          'questions': questions,
          'dateCreated': FieldValue.serverTimestamp(),
          'endDate': endDate,
          'doneCount': 0,
        });

        // Add quizId to the class document
        await _firestore.collection('classes').doc(classId).update({
          'quizIds': FieldValue.arrayUnion([quizId])
        });

        return quizId;
      } catch (e) {
        Fluttertoast.showToast(msg: "Error creating quiz: $e");
        return null;
      }
    } else {
      Fluttertoast.showToast(msg: "Error: User not found");
      return null;
    }
  }

  Future<void> deleteQuiz(String quizId, String classId) async {
    try {
      await _firestore.collection('quizzes').doc(quizId).delete();

      // Remove quizId from the class document
      await _firestore.collection('classes').doc(classId).update({
        'quizIds': FieldValue.arrayRemove([quizId])
      });

      Fluttertoast.showToast(msg: "Quiz deleted successfully");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error deleting quiz: $e");
    }
  }

  Stream<QuerySnapshot> getClassQuizzes(String classId) {
    return _firestore
        .collection('quizzes')
        .where('classId', isEqualTo: classId)
        .orderBy('dateCreated', descending: true)
        .snapshots();
  }

  Future<void> submitQuiz(String quizId, String studentId,
      List<Map<String, dynamic>> answers) async {
    try {
      await _firestore.collection('quizSubmissions').add({
        'quizId': quizId,
        'studentId': studentId,
        'answers': answers,
        'submissionDate': FieldValue.serverTimestamp(),
      });

      // Increment the doneCount
      await _firestore
          .collection('quizzes')
          .doc(quizId)
          .update({'doneCount': FieldValue.increment(1)});

      Fluttertoast.showToast(msg: "Quiz submitted successfully");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error submitting quiz: $e");
    }
  }

  Future<Map<String, dynamic>?> getQuizDetails(String quizId) async {
    try {
      DocumentSnapshot quizDoc =
          await _firestore.collection('quizzes').doc(quizId).get();
      if (quizDoc.exists) {
        return quizDoc.data() as Map<String, dynamic>;
      } else {
        Fluttertoast.showToast(msg: "Quiz not found");
        return null;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching quiz details: $e");
      return null;
    }
  }

  Future<bool> isQuizDone(String quizId, String studentId) async {
    QuerySnapshot submissions = await FirebaseFirestore.instance
        .collection('quizSubmissions')
        .where('quizId', isEqualTo: quizId)
        .where('studentId', isEqualTo: studentId)
        .get();

    return submissions.docs.isNotEmpty;
  }
}
