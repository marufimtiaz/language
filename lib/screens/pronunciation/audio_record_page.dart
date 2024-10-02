// UI implementation
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:language/providers/pronunciation_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';

class AudioRecordingPage extends StatefulWidget {
  final String classId;
  final int pronunciationIndex;
  const AudioRecordingPage(
      {super.key, required this.classId, required this.pronunciationIndex});

  @override
  State<AudioRecordingPage> createState() => _AudioRecordingPageState();
}

class _AudioRecordingPageState extends State<AudioRecordingPage> {
  DateTime? endDate;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      audioProvider.deleteAllRecordings();
    });
  }

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
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<PronunciationProvider>(
          builder: (context, pronunciationProvider, child) {
            final pronunciationText =
                pronunciationProvider.pronunciations[widget.pronunciationIndex];
            return Text(
              pronunciationText,
              style: const TextStyle(fontSize: 18),
            );
          },
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
        waveStyle: WaveStyle(
          waveColor: Colors.green.shade700,
          extendWaveform: true,
          showMiddleLine: false,
        ),
      );
    } else if (audioProvider.isOfflinePlaying) {
      return AudioFileWaveforms(
        size: Size(width, 100),
        playerController: audioProvider.offlinePlayerController,
        enableSeekGesture: true,
        playerWaveStyle: PlayerWaveStyle(
          fixedWaveColor: Colors.green.shade300,
          liveWaveColor: Colors.green.shade700,
          seekLineColor: Colors.green.shade900,
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
            : audioProvider.isOfflinePlaying
                ? 'Playback Duration: ${audioProvider.offlinePlaybackDuration}'
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
              if (audioProvider.doneRecording)
                _buildCircularButton(
                  icon: audioProvider.isOfflinePlaying
                      ? (audioProvider.isOfflinePaused
                          ? Icons.play_arrow
                          : Icons.pause)
                      : Icons.play_arrow,
                  onPressed: () => _togglePlayback(context, audioProvider),
                ),
              if (audioProvider.isOfflinePlaying)
                _buildCircularButton(
                  icon: Icons.stop,
                  onPressed: () => _stopPlayback(context, audioProvider),
                ),
            ],
          ),
        if (!audioProvider.isRecording && !audioProvider.isOfflinePlaying)
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
      child: !audioProvider.doneRecording
          ? const SizedBox()
          : FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade100,
              ),
              child: Text(
                audioProvider.isUploading ? 'Uploading...' : 'Upload',
                style: TextStyle(color: Colors.green.shade800),
              ),
              onPressed: () =>
                  audioProvider.isUploading ? null : _pickEndDate(),
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
      await audioProvider.toggleOfflinePlayback();
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to play/stop recording: $e');
    }
  }

  void _stopPlayback(BuildContext context, AudioProvider audioProvider) async {
    try {
      await audioProvider.stopOfflinePlayback();
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to stop playback: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(
        () {
          endDate = DateTime(
              pickedDate.year, pickedDate.month, pickedDate.day, 23, 59, 59);
        },
      );
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      final _audioUrl = await audioProvider.uploadRecording(widget.classId);

      if (_audioUrl != null) {
        String audioUrl = _audioUrl;
        final pronunciationProvider =
            Provider.of<PronunciationProvider>(context, listen: false);
        final result = await pronunciationProvider.createPronunciation(
            widget.classId, widget.pronunciationIndex, audioUrl, endDate!);
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pronunciation created successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error creating pronunciation')),
          );
        }
      }
    }
  }
}
