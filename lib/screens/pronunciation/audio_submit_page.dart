import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:language/providers/pronunciation_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';

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
  String? pronunciationText;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deleteAllRecordings();
      _fetchTeacherAudio();
      _fetchPronunciationText();
    });
  }

  Future<void> _deleteAllRecordings() async {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    await audioProvider.deleteAllRecordings();
  }

  Future<void> _fetchTeacherAudio() async {
    final pronunciationProvider =
        Provider.of<PronunciationProvider>(context, listen: false);
    final url = await pronunciationProvider.fetchPronunciationAudio(
        widget.classId, widget.pronunciationIndex);
    setState(() {
      teacherAudioUrl = url;
    });
    if (url != null) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      audioProvider.setOnlineAudioUrl(url);
    }
  }

  Future<void> _fetchPronunciationText() async {
    final pronunciationProvider =
        Provider.of<PronunciationProvider>(context, listen: false);
    final text = await pronunciationProvider.fetchPronunciationText(
        widget.classId, widget.pronunciationIndex);
    setState(() {
      pronunciationText = text;
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
                flex: 6,
                child: _buildInstructionCard(audioProvider, width),
              ),
              Expanded(
                flex: 2,
                child: _buildAudioVisualizer(audioProvider, width),
              ),
              _buildDurationDisplay(audioProvider),
              Expanded(
                flex: 2,
                child: _buildControlButtons(context, audioProvider),
              ),
              const Spacer(),
              if (audioProvider.savedRecordings.isNotEmpty)
                _buildUploadButton(context, audioProvider),
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
        child: pronunciationText == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Text(
                    pronunciationText!,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  if (!isSubmitting)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: _buildCircularButton(
                        icon: audioProvider.isOnlinePlaying
                            ? (audioProvider.isOnlinePaused
                                ? Icons.play_arrow
                                : Icons.pause)
                            : Icons.play_arrow,
                        onPressed: teacherAudioUrl != null
                            ? () => audioProvider.isOnlinePlaying
                                ? (audioProvider.isOnlinePaused
                                    ? audioProvider
                                        .playOnlineAudio(teacherAudioUrl!)
                                    : audioProvider.pauseOnlinePlayback())
                                : audioProvider
                                    .playOnlineAudio(teacherAudioUrl!)
                            : () {},
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildAudioVisualizer(AudioProvider audioProvider, double width) {
    if (audioProvider.isRecording) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: AudioWaveforms(
          size: Size(width, 100),
          recorderController: audioProvider.recorderController,
          waveStyle: WaveStyle(
            waveColor: Colors.green.shade700,
            extendWaveform: true,
            showMiddleLine: false,
          ),
        ),
      );
    } else if (audioProvider.isOfflinePlaying) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: AudioFileWaveforms(
          size: Size(width, 100),
          playerController: audioProvider.offlinePlayerController,
          enableSeekGesture: true,
          playerWaveStyle: PlayerWaveStyle(
            fixedWaveColor: Colors.green.shade300,
            liveWaveColor: Colors.green.shade700,
            seekLineColor: Colors.green.shade900,
            showSeekLine: true,
          ),
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
                // : audioProvider.isOnlinePlaying
                //     ? 'Playback Duration: ${audioProvider.onlinePlaybackDuration}'
                : '',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildControlButtons(
      BuildContext context, AudioProvider audioProvider) {
    if (isSubmitting) {
      return const Center(
        child:
            Text('Submitting Pronunciation...', style: TextStyle(fontSize: 20)),
      );
    } else {
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
                    onPressed: () => audioProvider.toggleOfflinePlayback(),
                  ),
                if (audioProvider.isOfflinePlaying)
                  _buildCircularButton(
                    icon: Icons.stop,
                    onPressed: () => audioProvider.stopOfflinePlayback(),
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
              child: Text(audioProvider.isUploading ? 'Uploading...' : 'Upload',
                  style: TextStyle(color: Colors.green.shade800)),
              onPressed: () =>
                  audioProvider.isUploading ? null : _studentSubmit(),
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

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _studentSubmit() async {
    setState(() {
      isSubmitting = true;
    });
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final _audioUrl = await audioProvider.uploadRecording(widget.classId);

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
        setState(() {
          isSubmitting = false;
        });
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error submitting pronunciation')),
        );
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }
}
