import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioProvider extends ChangeNotifier {
  late RecorderController _recorderController;
  late PlayerController _playerController;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  String _recordingDuration = '00:00';
  String _playbackDuration = '00:00';
  String? _recordedFilePath;
  List<String> _savedRecordings = [];

  String? _onlineAudioUrl; // URL for online audio playback

  RecorderController get recorderController => _recorderController;
  PlayerController get playerController => _playerController;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  String get recordingDuration => _recordingDuration;
  String get playbackDuration => _playbackDuration;
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

    _playerController = PlayerController();
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
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        throw Exception('Microphone permission not granted');
      }

      await _deleteAllRecordings(); // Delete all previous recordings

      await _setFilePath();
      await _recorderController.record(path: _recordedFilePath);
      _isRecording = true;
      notifyListeners();
      _updateRecordingDuration();
    } catch (e) {
      print('Error starting recording: $e');
      rethrow;
    }
  }

  Future<void> _deleteAllRecordings() async {
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

  Future<void> stopRecording() async {
    try {
      final path = await _recorderController.stop();
      _isRecording = false;
      if (_recordedFilePath != null) {
        _savedRecordings.add(_recordedFilePath!);
      }
      notifyListeners();
    } catch (e) {
      print('Error stopping recording: $e');
      rethrow;
    }
  }

  // Local audio playback functions
  Future<void> playRecording([String? filePath]) async {
    final pathToPlay = filePath ?? _recordedFilePath;
    if (pathToPlay != null && File(pathToPlay).existsSync()) {
      try {
        _playerController = PlayerController();
        await _playerController.preparePlayer(
          path: pathToPlay,
          shouldExtractWaveform: true,
          noOfSamples: 100,
          volume: 1.0,
        );
        await _playerController.startPlayer();
        _isPlaying = true;
        _isPaused = false;
        notifyListeners();

        // Listen to playback duration changes
        _playerController.onCurrentDurationChanged.listen((duration) {
          _playbackDuration = _formatDuration(Duration(milliseconds: duration));
          notifyListeners();
        });

        _playerController.onCompletion.listen((_) {
          _isPlaying = false;
          _playbackDuration = '00:00'; // Reset playback duration
          notifyListeners();
        });
      } catch (e) {
        print('Error playing recording: $e');
        _isPlaying = false;
        notifyListeners();
        rethrow;
      }
    } else {
      throw Exception('No recorded file found');
    }
  }

  // Online audio playback
  Future<void> playOnlineAudio(String url) async {
    try {
      _onlineAudioUrl = url;
      _playerController = PlayerController();
      await _playerController.preparePlayer(
        path: _onlineAudioUrl!,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1.0,
      );
      await _playerController.startPlayer();
      _isPlaying = true;
      _isPaused = false;
      notifyListeners();

      // Listen to playback duration changes
      _playerController.onCurrentDurationChanged.listen((duration) {
        _playbackDuration = _formatDuration(Duration(milliseconds: duration));
        notifyListeners();
      });

      _playerController.onCompletion.listen((_) {
        _isPlaying = false;
        _playbackDuration = '00:00'; // Reset playback duration
        notifyListeners();
      });
    } catch (e) {
      print('Error playing online audio: $e');
      rethrow;
    }
  }

  // Function to upload recorded audio
  Future<String?> uploadRecording() async {
    if (_recordedFilePath == null) {
      throw Exception('No recording available to upload.');
    }

    final file = File(_recordedFilePath!);
    final fileName =
        'audio/${DateTime.now().millisecondsSinceEpoch}.m4a'; // Upload to 'audio' folder with timestamp

    try {
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
      //delete the file from local storage after uploading to Firebase
      await _deleteAllRecordings();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  Future<void> pausePlayback() async {
    try {
      await _playerController.pausePlayer();
      _isPaused = true;
      notifyListeners();
    } catch (e) {
      print('Error stopping playback: $e');
      rethrow;
    }
  }

  Future<void> togglePlayback() async {
    if (_isPlaying) {
      if (_isPaused) {
        // Resume playback if paused
        await _playerController.startPlayer();
        _isPaused = false;
      } else {
        // Pause playback if playing
        await pausePlayback();
      }
    } else {
      // Start playback if not playing or paused
      await playRecording();
    }
    notifyListeners();
  }

  Future<void> stopPlayback() async {
    if (_isPlaying) {
      try {
        await _playerController.stopPlayer();
        _isPlaying = false;
        _isPaused = false; // Reset pause state
        notifyListeners();
      } catch (e) {
        print('Error stopping playback: $e');
        rethrow;
      }
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
    _playerController.dispose();
    super.dispose();
  }
}
