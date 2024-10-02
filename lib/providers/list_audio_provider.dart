import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class ListAudioProvider extends ChangeNotifier {
  final Map<int, AudioPlayer> _players = {};
  final Map<int, bool> _isPlaying = {};
  final Map<int, bool> _isPaused = {};

  bool isPlaying(int index) => _isPlaying[index] ?? false;
  bool isPaused(int index) => _isPaused[index] ?? false;

  Future<void> playAudio(int index, String url) async {
    if (!_players.containsKey(index)) {
      _players[index] = AudioPlayer();
    }

    if (_isPlaying[index] == true) {
      if (_isPaused[index] == true) {
        await _players[index]!.resume();
        _isPaused[index] = false;
      } else {
        await _players[index]!.pause();
        _isPaused[index] = true;
      }
    } else {
      await _players[index]!.play(UrlSource(url));
      _isPlaying[index] = true;
      _isPaused[index] = false;
    }

    notifyListeners();

    _players[index]!.onPlayerComplete.listen((_) {
      _isPlaying[index] = false;
      _isPaused[index] = false;
      notifyListeners();
    });
  }

  void stopAllPlayers() {
    for (var player in _players.values) {
      player.stop();
    }
    _isPlaying.clear();
    _isPaused.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    for (var player in _players.values) {
      player.dispose();
    }
    super.dispose();
  }
}
