import 'package:flutter/foundation.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioProvider extends ChangeNotifier {
  late RecorderController _recorderController;
  late PlayerController _playerController;
  bool _isRecording = false;
  bool _isRecordingCompleted = false;
  bool _isPlaying = false;
  String _recordingDuration = '00:00';
  String? _recordedFilePath;

  RecorderController get recorderController => _recorderController;
  bool get isRecording => _isRecording;
  bool get isRecordingCompleted => _isRecordingCompleted;
  bool get isPlaying => _isPlaying;
  String get recordingDuration => _recordingDuration;

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
    await _setFilePath();
  }

  Future<void> _setFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    _recordedFilePath =
        '${directory.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    print('File will be saved at: $_recordedFilePath');
  }

  Future<bool> _requestPermissions() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<void> startRecording() async {
    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        throw Exception('Microphone permission not granted');
      }

      await _setFilePath(); // Set a new file path for each recording
      await _recorderController.record(path: _recordedFilePath);
      print('Recording started. File path: $_recordedFilePath');
      _isRecording = true;
      _isRecordingCompleted = false;
      notifyListeners();
      _updateRecordingDuration();
    } catch (e) {
      print('Error starting recording: $e');
      rethrow;
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _recorderController.stop();
      print('Recording stopped. File path: $path');
      _isRecording = false;
      _isRecordingCompleted = true;
      notifyListeners();

      // Verify if the file exists
      if (_recordedFilePath != null && File(_recordedFilePath!).existsSync()) {
        print('Recorded file exists at: $_recordedFilePath');
      } else {
        print('Recorded file not found at: $_recordedFilePath');
      }
    } catch (e) {
      print('Error stopping recording: $e');
      rethrow;
    }
  }

  Future<void> playRecording() async {
    if (_recordedFilePath != null && File(_recordedFilePath!).existsSync()) {
      try {
        print('Attempting to play file: $_recordedFilePath');
        await _playerController.preparePlayer(path: _recordedFilePath!);
        await _playerController.startPlayer();
        _isPlaying = true;
        notifyListeners();

        _playerController.onCompletion.listen((_) {
          _isPlaying = false;
          notifyListeners();
        });
      } catch (e) {
        print('Error playing recording: $e');
        _isPlaying = false;
        notifyListeners();
        rethrow;
      }
    } else {
      print('No recorded file found at: $_recordedFilePath');
      throw Exception('No recorded file found');
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _playerController.stopPlayer();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      print('Error stopping playback: $e');
      rethrow;
    }
  }

  void resetRecording() {
    _isRecording = false;
    _isRecordingCompleted = false;
    _isPlaying = false;
    _recordingDuration = '00:00';
    if (_recordedFilePath != null && File(_recordedFilePath!).existsSync()) {
      File(_recordedFilePath!).deleteSync();
      print('Deleted file: $_recordedFilePath');
    }
    _recordedFilePath = null;
    notifyListeners();
  }

  void _updateRecordingDuration() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording) {
        return false;
      }
      final duration = _recorderController.recordedDuration;
      _recordingDuration = _formatDuration(duration);
      notifyListeners();
      return _isRecording;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _playerController.dispose();
    super.dispose();
  }
}
