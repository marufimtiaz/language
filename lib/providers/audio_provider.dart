import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

class AudioProvider extends ChangeNotifier {
  // Recorder
  late RecorderController _recorderController;
  bool _isRecording = false;
  bool _doneRecording = false;
  String _recordingDuration = '00:00';
  String? _recordedFilePath;

  // Offline Player
  late PlayerController _offlinePlayerController;
  bool _isOfflinePlaying = false;
  bool _isOfflinePaused = false;
  String _offlinePlaybackDuration = '00:00';

  // Online Player
  late AudioPlayer _onlinePlayer;
  bool _isOnlinePlaying = false;
  bool _isOnlinePaused = false;
  bool _isUploading = false;
  bool _isLoading = false;
  String _onlinePlaybackDuration = '00:00';
  String? _onlineAudioUrl;

  List<String> _savedRecordings = [];

  // Getters
  RecorderController get recorderController => _recorderController;
  PlayerController get offlinePlayerController => _offlinePlayerController;

  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  bool get doneRecording => _doneRecording;
  bool get isRecording => _isRecording;
  bool get isOfflinePlaying => _isOfflinePlaying;
  bool get isOfflinePaused => _isOfflinePaused;
  bool get isOnlinePlaying => _isOnlinePlaying;
  bool get isOnlinePaused => _isOnlinePaused;
  String get recordingDuration => _recordingDuration;
  String get offlinePlaybackDuration => _offlinePlaybackDuration;
  String get onlinePlaybackDuration => _onlinePlaybackDuration;
  List<String> get savedRecordings => _savedRecordings;
  String? get onlineAudioUrl => _onlineAudioUrl;

  AudioProvider() {
    _initControllers();
  }

  Future<void> _initControllers() async {
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;

    _offlinePlayerController = PlayerController();
    _onlinePlayer = AudioPlayer();
    await _loadSavedRecordings();
  }

  Future<void> _loadSavedRecordings() async {
    final directory = await getApplicationDocumentsDirectory();
    _savedRecordings = Directory(directory.path)
        .listSync()
        .where((file) => file.path.endsWith('.m4a'))
        .map((file) => file.path)
        .toList();
    notifyListeners();
  }

  Future<void> _setFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    _recordedFilePath =
        '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<bool> _requestPermissions() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  // Recording related functions
  Future<void> startRecording() async {
    try {
      _isLoading = true; // Start loading
      notifyListeners();

      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        throw Exception('Microphone permission not granted');
      }

      await deleteAllRecordings(); // Delete all previous recordings

      await _setFilePath();
      await _recorderController.record(path: _recordedFilePath);
      _isRecording = true;
      _doneRecording = false;
      _isLoading = false; // Stop loading after recording starts
      notifyListeners();
      _updateRecordingDuration();
    } catch (e) {
      _isLoading = false; // Stop loading if error occurs
      notifyListeners();
      print('Error starting recording: $e');
      rethrow;
    }
  }

  Future<void> stopRecording() async {
    try {
      _isLoading = true; // Start loading
      notifyListeners();

      final path = await _recorderController.stop();
      _isRecording = false;
      _doneRecording = true;
      if (_recordedFilePath != null) {
        _savedRecordings.add(path!);
      }
      _isLoading = false; // Stop loading after recording stops
      notifyListeners();
    } catch (e) {
      _isLoading = false; // Stop loading if error occurs
      notifyListeners();
      print('Error stopping recording: $e');
      rethrow;
    }
  }

  Future<void> deleteAllRecordings() async {
    try {
      for (var filePath in _savedRecordings) {
        File(filePath).deleteSync();
      }
      _savedRecordings.clear();
      notifyListeners();
    } catch (e) {
      print('Error deleting previous recordings: $e');
      rethrow;
    }
  }

  // Offline playback methods
  Future<void> playOfflineRecording([String? filePath]) async {
    final pathToPlay = filePath ?? _recordedFilePath;
    if (pathToPlay != null && File(pathToPlay).existsSync()) {
      try {
        await _offlinePlayerController.preparePlayer(
          path: pathToPlay,
          shouldExtractWaveform: true,
          noOfSamples: 100,
          volume: 1.0,
        );
        await _offlinePlayerController.startPlayer();
        _isOfflinePlaying = true;
        _isOfflinePaused = false;
        notifyListeners();

        _offlinePlayerController.onCurrentDurationChanged.listen((duration) {
          _offlinePlaybackDuration =
              _formatDuration(Duration(milliseconds: duration));
          notifyListeners();
        });

        _offlinePlayerController.onCompletion.listen((_) {
          _isOfflinePlaying = false;
          _offlinePlaybackDuration = '00:00';
          notifyListeners();
        });
      } catch (e) {
        print('Error playing offline recording: $e');
        _isOfflinePlaying = false;
        notifyListeners();
        rethrow;
      }
    } else {
      throw Exception('No recorded file found');
    }
  }

  Future<void> pauseOfflinePlayback() async {
    try {
      await _offlinePlayerController.pausePlayer();
      _isOfflinePaused = true;
      notifyListeners();
    } catch (e) {
      print('Error pausing offline playback: $e');
      rethrow;
    }
  }

  Future<void> resumeOfflinePlayback() async {
    try {
      await _offlinePlayerController.startPlayer();
      _isOfflinePaused = false;
      notifyListeners();
    } catch (e) {
      print('Error resuming offline playback: $e');
      rethrow;
    }
  }

  Future<void> stopOfflinePlayback() async {
    if (_isOfflinePlaying) {
      try {
        await _offlinePlayerController.stopPlayer();
        _isOfflinePlaying = false;
        _isOfflinePaused = false;
        notifyListeners();
      } catch (e) {
        print('Error stopping offline playback: $e');
        rethrow;
      }
    }
  }

  Future<void> toggleOfflinePlayback() async {
    if (_isOfflinePlaying) {
      if (_isOfflinePaused) {
        await resumeOfflinePlayback();
      } else {
        await pauseOfflinePlayback();
      }
    } else {
      await playOfflineRecording();
    }
  }

  // Online playback methods

  //set the online audio URL
  void setOnlineAudioUrl(String url) {
    _onlineAudioUrl = url;
  }

  Future<void> playOnlineAudio(String url) async {
    try {
      _isLoading = true; // Start loading
      notifyListeners();

      _onlineAudioUrl = url;
      await _onlinePlayer.play(UrlSource(url));

      _isOnlinePlaying = true;
      _isOnlinePaused = false;

      _isLoading = false; // Stop loading when audio starts
      notifyListeners();

      _onlinePlayer.onDurationChanged.listen((duration) {
        _onlinePlaybackDuration = _formatDuration(duration);
        notifyListeners();
      });

      _onlinePlayer.onPlayerComplete.listen((_) {
        _isOnlinePlaying = false;
        _onlinePlaybackDuration = '00:00';
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false; // Stop loading if error occurs
      notifyListeners();
      print('Error playing online audio: $e');
      rethrow;
    }
  }

  Future<void> pauseOnlinePlayback() async {
    try {
      await _onlinePlayer.pause();
      _isOnlinePaused = true;
      notifyListeners();
    } catch (e) {
      print('Error pausing online playback: $e');
      rethrow;
    }
  }

  Future<void> resumeOnlinePlayback() async {
    try {
      await _onlinePlayer.resume();
      _isOnlinePaused = false;
      notifyListeners();
    } catch (e) {
      print('Error resuming online playback: $e');
      rethrow;
    }
  }

  Future<void> stopOnlinePlayback() async {
    if (_isOnlinePlaying) {
      try {
        await _onlinePlayer.stop();
        _isOnlinePlaying = false;
        _isOnlinePaused = false;
        notifyListeners();
      } catch (e) {
        print('Error stopping online playback: $e');
        rethrow;
      }
    }
  }

  Future<void> toggleOnlinePlayback() async {
    if (_isOnlinePlaying) {
      if (_isOnlinePaused) {
        await resumeOnlinePlayback();
      } else {
        await pauseOnlinePlayback();
      }
    } else {
      if (_onlineAudioUrl != null) {
        await playOnlineAudio(_onlineAudioUrl!);
      } else {
        throw Exception('No online audio URL set');
      }
    }
  }

  // Function to upload recorded audio
  Future<String?> uploadRecording(String classId) async {
    if (_recordedFilePath == null) {
      throw Exception('No recording available to upload.');
    }

    final file = File(_recordedFilePath!);
    final fileName =
        'audio/$classId/${DateTime.now().millisecondsSinceEpoch}.m4a'; // Upload to 'audio' folder with timestamp

    try {
      _isUploading = true; // Start uploading
      notifyListeners();

      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = storageRef.putFile(file);

      // Optional: Listen to upload progress
      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        print('Upload progress: ${progress * 100}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('Uploaded successfully. Download URL: $downloadUrl');
      // Delete the file from local storage after uploading to Firebase
      await deleteAllRecordings();

      _isUploading = false; // Stop uploading
      notifyListeners();

      return downloadUrl;
    } catch (e) {
      _isUploading = false; // Stop uploading if error occurs
      notifyListeners();
      print('Error uploading file: $e');
      rethrow;
    }
  }

  void _updateRecordingDuration() {
    _recorderController.onCurrentDuration.listen((duration) {
      _recordingDuration = _formatDuration(duration);
      notifyListeners();
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  Future<void> deleteRecording(String filePath) async {
    try {
      File(filePath).deleteSync();
      _savedRecordings.remove(filePath);
      notifyListeners();
    } catch (e) {
      print('Error deleting recording: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _offlinePlayerController.dispose();
    _onlinePlayer.dispose();
    super.dispose();
  }
}
