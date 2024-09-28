// UI implementation
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:language/providers/pronunciation_provider.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/class_provider.dart';

class AudioSubmitPage extends StatefulWidget {
  final String classId;
  final int pronunciationIndex;

  const AudioSubmitPage({
    super.key,
    required this.classId,
    required this.pronunciationIndex,
  });

  @override
  State<AudioSubmitPage> createState() => _AudioSubmitPageState();
}

class _AudioSubmitPageState extends State<AudioSubmitPage> {
  String? teacherAudioUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTeacherAudio();
    });
  }

  Future<void> _fetchTeacherAudio() async {
    final pronunciationProvider =
        Provider.of<PronunciationProvider>(context, listen: false);
    final url = await pronunciationProvider.fetchPronunciationAudio(
        widget.classId, widget.pronunciationIndex);
    print(url);
    setState(() {
      teacherAudioUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Recorder')),
      body: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          return Column(
            children: [
              Expanded(
                flex: 10,
                child: _buildInstructionCard(audioProvider, width),
              ),
              Expanded(
                  flex: 2, child: _buildAudioVisualizer(audioProvider, width)),
              _buildDurationDisplay(audioProvider),
              Expanded(
                  flex: 2, child: _buildControlButtons(context, audioProvider)),
              const Spacer(),
              if (audioProvider.savedRecordings.isNotEmpty)
                Expanded(
                    flex: 2, child: _buildUploadButton(context, audioProvider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInstructionCard(AudioProvider audioProvider, double width) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<PronunciationProvider>(
          builder: (context, pronunciationProvider, child) {
            final pronunciationText =
                pronunciationProvider.pronunciations[widget.pronunciationIndex];
            return Column(
              children: [
                Text(
                  pronunciationText,
                  style: const TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                _buildAudioVisualizer(audioProvider, width),
                _buildCircularButton(
                  icon: audioProvider.isPlaying
                      ? (audioProvider.isPaused
                          ? Icons.play_arrow
                          : Icons.pause)
                      : Icons.play_arrow,
                  onPressed: teacherAudioUrl != null
                      ? () => audioProvider.playOnlineAudio(teacherAudioUrl!)
                      : () {},
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ... (rest of the methods remain the same)

  Widget _buildAudioVisualizer(AudioProvider audioProvider, double width) {
    // final width = 300.0; // Adjust as needed
    if (audioProvider.isRecording) {
      return AudioWaveforms(
        size: Size(width, 100),
        recorderController: audioProvider.recorderController,
        waveStyle: const WaveStyle(
          waveColor: Colors.blue,
          extendWaveform: true,
          showMiddleLine: false,
        ),
      );
    } else if (audioProvider.isPlaying) {
      return AudioFileWaveforms(
        size: Size(width, 100),
        playerController: audioProvider.playerController,
        enableSeekGesture: true,
        playerWaveStyle: const PlayerWaveStyle(
          fixedWaveColor: Colors.grey,
          liveWaveColor: Colors.blue,
          seekLineColor: Colors.red,
          showSeekLine: true,
        ),
      );
    } else {
      return const SizedBox(height: 100);
    }
  }

  Widget _buildDurationDisplay(AudioProvider audioProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        audioProvider.isRecording
            ? 'Recording Duration: ${audioProvider.recordingDuration}'
            : audioProvider.isPlaying
                ? 'Playback Duration: ${audioProvider.playbackDuration}'
                : '', // Show playback duration when playing
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildControlButtons(
      BuildContext context, AudioProvider audioProvider) {
    print(audioProvider.savedRecordings);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!audioProvider.isRecording &&
            audioProvider.savedRecordings.isNotEmpty)
          Row(
            children: [
              _buildCircularButton(
                icon: audioProvider.isPlaying
                    ? (audioProvider.isPaused ? Icons.play_arrow : Icons.pause)
                    : Icons.play_arrow,
                onPressed: () => _togglePlayback(context, audioProvider),
              ),
              if (audioProvider.isPlaying)
                _buildCircularButton(
                  icon: Icons.stop,
                  onPressed: () => _stopPlayback(context, audioProvider),
                ),
            ],
          ),
        if (!audioProvider.isRecording && !audioProvider.isPlaying)
          _buildCircularButton(
            icon: Icons.mic,
            onPressed: () => _startRecording(context, audioProvider),
          ),
        if (audioProvider.isRecording)
          _buildCircularButton(
            icon: Icons.stop,
            onPressed: () => _stopRecording(context, audioProvider),
          ),
      ],
    );
  }

  Widget _buildUploadButton(BuildContext context, AudioProvider audioProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green.shade100,
        ),
        child: Text('Upload', style: TextStyle(color: Colors.green.shade800)),
        onPressed: () => _studentSubmit(),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green.shade100,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        child: Icon(icon, size: 30, color: Colors.green.shade600),
      ),
    );
  }

  // Widget _buildRecordingsList(AudioProvider audioProvider) {
  //   return Expanded(
  //     child: ListView.builder(
  //       itemCount: audioProvider.savedRecordings.length,
  //       itemBuilder: (context, index) {
  //         final recording = audioProvider.savedRecordings[index];
  //         return ListTile(
  //           title: Text('Recording ${index + 1}'),
  //           trailing: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               IconButton(
  //                 icon: const Icon(Icons.play_arrow),
  //                 onPressed: () => audioProvider.playRecording(recording),
  //               ),
  //               IconButton(
  //                 icon: const Icon(Icons.delete),
  //                 onPressed: () => audioProvider.deleteRecording(recording),
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  void _startRecording(
      BuildContext context, AudioProvider audioProvider) async {
    try {
      await audioProvider.startRecording();
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to start recording: $e');
    }
  }

  void _stopRecording(BuildContext context, AudioProvider audioProvider) async {
    try {
      await audioProvider.stopRecording();
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to stop recording: $e');
    }
  }

  void _togglePlayback(
      BuildContext context, AudioProvider audioProvider) async {
    try {
      await audioProvider.togglePlayback();
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to play/stop recording: $e');
    }
  }

  void _stopPlayback(BuildContext context, AudioProvider audioProvider) async {
    try {
      await audioProvider.stopPlayback();
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to stop playback: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _studentSubmit() async {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final _audioUrl = await audioProvider.uploadRecording();

    if (_audioUrl != null) {
      String audioUrl = _audioUrl;
      final pronunciationProvider =
          Provider.of<PronunciationProvider>(context, listen: false);
      final result = await pronunciationProvider.submitPronunciation(
          widget.classId, widget.pronunciationIndex, audioUrl);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pronunciation submitted successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error submitting pronunciation')),
        );
      }
    }
  }
}
