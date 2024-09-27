// UI implementation
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class AudioRecordingPage extends StatefulWidget {
  const AudioRecordingPage({super.key});

  @override
  State<AudioRecordingPage> createState() => _AudioRecordingPageState();
}

class _AudioRecordingPageState extends State<AudioRecordingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Recorder')),
      body: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          return Column(
            children: [
              _buildInstructionCard(),
              _buildAudioVisualizer(audioProvider),
              _buildDurationDisplay(audioProvider),
              _buildControlButtons(context, audioProvider),
              const Spacer(),
              if (audioProvider.savedRecordings.isNotEmpty)
                // _buildRecordingsList(audioProvider),
                _buildUploadButton(context, audioProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInstructionCard() {
    return const Card(
      color: Colors.white,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Tap the microphone button to start recording. '
          'You can play back your recording or save it for later.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildAudioVisualizer(AudioProvider audioProvider) {
    final width = 300.0; // Adjust as needed
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
      child: _buildCircularButton(
        icon: Icons.upload,
        onPressed: () async {
          try {
            await audioProvider.uploadRecording();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Audio uploaded successfully!')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload audio: $e')),
            );
          }
        },
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
}
