import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> createQuiz(
      String classId, List<int> questionIds, DateTime endDate) async {
    var user = _auth.currentUser;
    if (user == null) return null;

    try {
      DocumentReference classRef =
          _firestore.collection('classes').doc(classId);
      DocumentSnapshot classDoc = await classRef.get();
      if (!classDoc.exists) return null;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      if (classData['teacherId'] != user.uid) return null;

      Map<String, dynamic> quizData = {
        'questions': questionIds,
        'dateCreated': DateTime.now(),
        'dateEnd': Timestamp.fromDate(endDate),
        'scores': {},
      };

      await classRef.update({
        'quizList': FieldValue.arrayUnion([quizData]),
        'dateCreated': FieldValue.serverTimestamp()
      });

      return 'Quiz created successfully';
    } catch (e) {
      print('Error creating quiz: $e');
      return null;
    }
  }

  Future<bool> updateQuizDate(
      String classId, int quizIndex, DateTime endDate) async {
    var user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentReference classRef =
          _firestore.collection('classes').doc(classId);
      DocumentSnapshot classDoc = await classRef.get();
      if (!classDoc.exists) return false;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      if (classData['teacherId'] != user.uid) return false;

      List<dynamic> quizList = classData['quizList'] ?? [];
      if (quizIndex < 0 || quizIndex >= quizList.length) return false;

      Map<String, dynamic> quiz = quizList[quizIndex];
      quiz['dateEnd'] = Timestamp.fromDate(endDate);
      await classRef.update({'quizList': quizList});

      return true;
    } catch (e) {
      print('Error updating quiz date: $e');
      return false;
    }
  }

  //get submissions
  Future<List<String>> getSubmissionIds(String classId, int quizIndex) async {
    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return [];

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> quizList = classData['quizList'] ?? [];
      if (quizIndex < 0 || quizIndex >= quizList.length) return [];

      Map<String, dynamic> quiz = quizList[quizIndex];
      Map<String, dynamic> scores = quiz['scores'] ?? {};

      return scores.keys.toList().cast<String>();
    } catch (e) {
      print('Error getting submissions: $e');
      return [];
    }
  }

  Future<List<int>> getScores(String classId, int quizIndex) async {
    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return [];

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> quizList = classData['quizList'] ?? [];
      if (quizIndex < 0 || quizIndex >= quizList.length) return [];

      Map<String, dynamic> quiz = quizList[quizIndex];
      Map<String, dynamic> scores = quiz['scores'] ?? {};

      return scores.values.toList().cast<int>();
    } catch (e) {
      print('Error getting scores: $e');
      return [];
    }
  }

  //get user details from studentIds array
  Future<QuerySnapshot?> studentDetails(List<dynamic> studentIds) async {
    try {
      print('Fetching students: $studentIds');

      if (studentIds.isEmpty) {
        print('No students submitted');
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

  Future<bool> deleteQuiz(String classId, int quizIndex) async {
    var user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentReference classRef =
          _firestore.collection('classes').doc(classId);
      DocumentSnapshot classDoc = await classRef.get();
      if (!classDoc.exists) return false;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      if (classData['teacherId'] != user.uid) return false;

      List<dynamic> quizList = classData['quizList'] ?? [];
      if (quizIndex < 0 || quizIndex >= quizList.length) return false;

      quizList.removeAt(quizIndex);
      await classRef.update({'quizList': quizList});

      return true;
    } catch (e) {
      print('Error deleting quiz: $e');
      return false;
    }
  }

  Future<bool> submitQuiz(String classId, int quizIndex, int score) async {
    var user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentReference classRef =
          _firestore.collection('classes').doc(classId);
      DocumentSnapshot classDoc = await classRef.get();
      if (!classDoc.exists) return false;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> quizList = classData['quizList'] ?? [];
      if (quizIndex < 0 || quizIndex >= quizList.length) return false;

      Map<String, dynamic> quiz = quizList[quizIndex];
      if (quiz['scores'][user.uid] != null) return false;

      quiz['scores'][user.uid] = score;
      await classRef.update({'quizList': quizList});

      return true;
    } catch (e) {
      print('Error submitting quiz: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchQuestions() async {
    try {
      DocumentSnapshot questionDoc =
          await _firestore.collection('questions').doc('FREEQUESTIONS').get();
      if (!questionDoc.exists) return [];

      Map<String, dynamic> questionData =
          questionDoc.data() as Map<String, dynamic>;

      // The questionSet is an array of maps
      List<dynamic> questionSet = questionData['questionSet'] as List<dynamic>;

      // Convert each item in the array to the desired format
      List<Map<String, dynamic>> questions = questionSet.map((question) {
        return {
          'questionText': question['questionText'] as String,
          'options': List<String>.from(question['options']),
          'answer': question['answer'] as int
        };
      }).toList();

      return questions;
    } catch (e) {
      print('Error fetching questions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchQuizQuestions(
      String classId, int quizIndex) async {
    try {
      Map<String, dynamic>? quiz = await fetchQuizIndex(classId, quizIndex);
      if (quiz == null) return [];

      List<int> questionIds = List<int>.from(quiz['questions'] ?? []);

      DocumentSnapshot questionDoc =
          await _firestore.collection('questions').doc('FREEQUESTIONS').get();
      if (!questionDoc.exists) return [];

      Map<String, dynamic> questionData =
          questionDoc.data() as Map<String, dynamic>;
      List<dynamic> questionSet = questionData['questionSet'] as List<dynamic>;

      List<Map<String, dynamic>> questions = [];
      for (var id in questionIds) {
        if (id < questionSet.length) {
          var question = questionSet[id];
          questions.add({
            'questionText': question['questionText'] as String,
            'options': List<String>.from(question['options']),
            'answer': question['answer'] as int
          });
        }
      }

      return questions;
    } catch (e) {
      print('Error fetching quiz questions: $e');
      return [];
    }
  }

  Future<bool> isQuizDone(String classId, int quizIndex) async {
    var user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return false;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> quizList = classData['quizList'] ?? [];
      if (quizIndex < 0 || quizIndex >= quizList.length) return false;

      Map<String, dynamic> quiz = quizList[quizIndex];
      return quiz['scores'][user.uid] != null;
    } catch (e) {
      print('Error checking if quiz is done: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchQuizList(String classId) async {
    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return [];

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(classData['quizList'] ?? []);
    } catch (e) {
      print('Error fetching quiz list: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchQuizIndex(
      String classId, int quizIndex) async {
    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return null;
      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> quizList = classData['quizList'] ?? [];
      if (quizIndex < 0 || quizIndex >= quizList.length) return null;
      return Map<String, dynamic>.from(quizList[quizIndex]);
    } catch (e) {
      print('Error fetching quiz: $e');
      return null;
    }
  }

  bool isActive(Map<String, dynamic> quiz) {
    Timestamp endDate = quiz['dateEnd'];
    return endDate.toDate().isAfter(DateTime.now());
  }

  Future<int> getQuizSubmissionCount(String classId, int quizIndex) async {
    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return 0;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> quizList = classData['quizList'] ?? [];
      if (quizIndex < 0 || quizIndex >= quizList.length) return 0;

      Map<String, dynamic> quiz = quizList[quizIndex];
      Map<String, dynamic> scores = quiz['scores'] ?? {};

      return scores.length;
    } catch (e) {
      print('Error getting quiz submission count: $e');
      return 0;
    }
  }

  //Get student scores for a quiz
  Future<int> getStudentScore(String classId, int quizIndex) async {
    var user = _auth.currentUser;
    if (user == null) return 0;

    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return 0;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> quizList = classData['quizList'] ?? [];
      if (quizIndex < 0 || quizIndex >= quizList.length) return 0;

      Map<String, dynamic> quiz = quizList[quizIndex];
      Map<String, dynamic> scores = quiz['scores'] ?? {};

      int score = scores[user.uid] ?? 0;

      print('Scores: $score');

      return score;
    } catch (e) {
      print('Error getting student score: $e');
      return 0;
    }
  }

  Future<int> fetchTotalQuizQuestions(String classId, int quizIndex) async {
    try {
      Map<String, dynamic>? quiz = await fetchQuizIndex(classId, quizIndex);
      if (quiz == null) return 0;

      List<int> questionIds = List<int>.from(quiz['questions'] ?? []);
      return questionIds.length;
    } catch (e) {
      print('Error fetching total quiz questions: $e');
      return 0;
    }
  }
}
