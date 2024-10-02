import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PronunciationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> createPronunciation(String classId, int textIndex,
      String teacherAudio, DateTime endDate) async {
    var user = _auth.currentUser;
    if (user == null) return null;

    try {
      DocumentReference classRef =
          _firestore.collection('classes').doc(classId);
      print('classRef: $classRef');
      DocumentSnapshot classDoc = await classRef.get();
      if (!classDoc.exists) return null;
      print('classDoc: $classDoc');
      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      if (classData['teacherId'] != user.uid) return null;
      print('classData: $classData');
      Map<String, dynamic> pronunciationData = {
        'textIndex': textIndex,
        'teacherAudio': teacherAudio,
        'dateCreated': DateTime.now(),
        'dateEnd': Timestamp.fromDate(endDate),
        'submissions': {},
      };

      await classRef.update({
        'pronunciationList': FieldValue.arrayUnion([pronunciationData]),
        'dateCreated': FieldValue.serverTimestamp()
      });

      return 'Pronunciation created successfully';
    } catch (e) {
      print('Error creating Pronunciation (service): $e');
      return null;
    }
  }

  Future<bool> updatePronunciationDate(
      String classId, int pronunciationIndex, DateTime endDate) async {
    var user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentReference classRef =
          _firestore.collection('classes').doc(classId);
      DocumentSnapshot classDoc = await classRef.get();
      if (!classDoc.exists) return false;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      if (classData['teacherId'] != user.uid) return false;

      List<dynamic> pronunciationList = classData['pronunciationList'] ?? [];
      if (pronunciationIndex < 0 ||
          pronunciationIndex >= pronunciationList.length) return false;

      Map<String, dynamic> pronunciation =
          pronunciationList[pronunciationIndex];
      pronunciation['dateEnd'] = Timestamp.fromDate(endDate);
      await classRef.update({'pronunciationList': pronunciationList});

      return true;
    } catch (e) {
      print('Error updating Pronunciation date: $e');
      return false;
    }
  }

  Future<bool> deletePronunciation(
      String classId, int pronunciationIndex) async {
    var user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentReference classRef =
          _firestore.collection('classes').doc(classId);
      DocumentSnapshot classDoc = await classRef.get();
      if (!classDoc.exists) return false;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      if (classData['teacherId'] != user.uid) return false;

      List<dynamic> pronunciationList = classData['pronunciationList'] ?? [];
      if (pronunciationIndex < 0 ||
          pronunciationIndex >= pronunciationList.length) return false;

      pronunciationList.removeAt(pronunciationIndex);
      await classRef.update({'pronunciationList': pronunciationList});

      return true;
    } catch (e) {
      print('Error deleting Pronunciation: $e');
      return false;
    }
  }

  Future<bool> submitPronunciation(
      String classId, int pronunciationIndex, String studentAudio) async {
    var user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentReference classRef =
          _firestore.collection('classes').doc(classId);
      DocumentSnapshot classDoc = await classRef.get();
      if (!classDoc.exists) return false;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> pronunciationList = classData['pronunciationList'] ?? [];
      if (pronunciationIndex < 0 ||
          pronunciationIndex >= pronunciationList.length) return false;

      Map<String, dynamic> pronunciation =
          pronunciationList[pronunciationIndex];
      if (pronunciation['submissions'][user.uid] != null) return false;

      pronunciation['submissions'][user.uid] = studentAudio;
      await classRef.update({'pronunciationList': pronunciationList});

      return true;
    } catch (e) {
      print('Error submitting Pronunciation: $e');
      return false;
    }
  }

  Future<List<String>> fetchPronunciations() async {
    try {
      DocumentSnapshot questionDoc =
          await _firestore.collection('questions').doc('FREEQUESTIONS').get();
      if (!questionDoc.exists) return [];

      Map<String, dynamic> questionData =
          questionDoc.data() as Map<String, dynamic>;

      List<String> pronunciations =
          List<String>.from(questionData['pronunciations'] ?? []);

      return pronunciations;
    } catch (e) {
      print('Error fetching pronunciations: $e');
      return [];
    }
  }

  Future<String?> fetchPronunciationText(
      String classId, int pronunciationIndex) async {
    try {
      Map<String, dynamic>? pronunciation =
          await fetchPronunciationIndex(classId, pronunciationIndex);
      if (pronunciation == null) return null;

      int textIndex = pronunciation['textIndex'] as int;

      DocumentSnapshot questionDoc =
          await _firestore.collection('questions').doc('FREEQUESTIONS').get();
      if (!questionDoc.exists) return null;

      Map<String, dynamic> questionData =
          questionDoc.data() as Map<String, dynamic>;
      List<String> pronunciations =
          List<String>.from(questionData['pronunciations'] ?? []);

      if (textIndex < 0 || textIndex >= pronunciations.length) return null;

      return pronunciations[textIndex];
    } catch (e) {
      print('Error fetching Pronunciation text: $e');
      return null;
    }
  }

  //Fetch pronunciation teacherAudio url
  Future<String?> fetchPronunciationAudio(
      String classId, int pronunciationIndex) async {
    try {
      Map<String, dynamic>? pronunciation =
          await fetchPronunciationIndex(classId, pronunciationIndex);
      if (pronunciation == null) return null;

      return pronunciation['teacherAudio'];
    } catch (e) {
      print('Error fetching Pronunciation audio: $e');
      return null;
    }
  }

  Future<bool> isPronunciationDone(
      String classId, int pronunciationIndex) async {
    var user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return false;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> pronunciationList = classData['pronunciationList'] ?? [];
      if (pronunciationIndex < 0 ||
          pronunciationIndex >= pronunciationList.length) return false;

      Map<String, dynamic> pronunciation =
          pronunciationList[pronunciationIndex];
      Map<String, dynamic> submissions = pronunciation['submissions'] ?? {};

      return submissions.containsKey(user.uid);
    } catch (e) {
      print('Error checking if Pronunciation is done: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPronunciationList(
      String classId) async {
    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return [];

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(
          classData['pronunciationList'] ?? []);
    } catch (e) {
      print('Error fetching Pronunciation list: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchPronunciationIndex(
      String classId, int pronunciationIndex) async {
    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return null;
      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> pronunciationList = classData['pronunciationList'] ?? [];
      if (pronunciationIndex < 0 ||
          pronunciationIndex >= pronunciationList.length) return null;
      return Map<String, dynamic>.from(pronunciationList[pronunciationIndex]);
    } catch (e) {
      print('Error fetching Pronunciation: $e');
      return null;
    }
  }

  bool isActive(Map<String, dynamic> pronunciation) {
    Timestamp endDate = pronunciation['dateEnd'];
    return endDate.toDate().isAfter(DateTime.now());
  }

  Future<int> getPronunciationSubmissionCount(
      String classId, int pronunciationIndex) async {
    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return 0;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> pronunciationList = classData['pronunciationList'] ?? [];
      if (pronunciationIndex < 0 ||
          pronunciationIndex >= pronunciationList.length) return 0;

      Map<String, dynamic> pronunciation =
          pronunciationList[pronunciationIndex];
      Map<String, dynamic> submissions = pronunciation['submissions'] ?? {};

      return submissions.length;
    } catch (e) {
      print('Error getting Pronunciation submission count: $e');
      return 0;
    }
  }
}
