import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/audio_provider.dart';

class AudioRecordingPage extends StatelessWidget {
  const AudioRecordingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
      ),
      body: Column(
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Tap the microphone to start recording.'),
            ),
          ),
          const Spacer(),
          if (!audioProvider.isRecording && !audioProvider.isRecordingCompleted)
            TextButton(
              onPressed: () async {
                try {
                  await audioProvider.startRecording();
                } catch (e) {
                  String errorMessage = 'Failed to start recording';
                  if (e.toString().contains('Permissions not granted')) {
                    errorMessage =
                        'Microphone permission is required to record audio';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }
              },
              child: const Icon(Icons.mic, size: 50),
            ),
          if (audioProvider.isRecording)
            AudioWaveforms(
              size: Size(MediaQuery.of(context).size.width, 200),
              recorderController: audioProvider.recorderController,
              enableGesture: true,
              waveStyle: const WaveStyle(
                waveColor: Colors.black,
                extendWaveform: true,
                showMiddleLine: false,
                scaleFactor: 50.0,
              ),
              padding: const EdgeInsets.only(left: 18),
              margin: const EdgeInsets.symmetric(horizontal: 15),
            ),
          if (audioProvider.isRecording)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text('Recording... ${audioProvider.recordingDuration}'),
            ),
          if (audioProvider.isRecording)
            ElevatedButton(
              onPressed: () async {
                try {
                  await audioProvider.stopRecording();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to stop recording: $e')),
                  );
                }
              },
              child: const Text('Stop Recording'),
            ),
          if (audioProvider.isRecordingCompleted && !audioProvider.isPlaying)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child:
                  Text('Recording length: ${audioProvider.recordingDuration}'),
            ),
          if (audioProvider.isRecordingCompleted)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    try {
                      if (audioProvider.isPlaying) {
                        await audioProvider.stopPlayback();
                      } else {
                        await audioProvider.playRecording();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Failed to play/stop recording: $e')),
                      );
                    }
                  },
                  icon: Icon(
                      audioProvider.isPlaying ? Icons.stop : Icons.play_arrow),
                  iconSize: 50,
                ),
                const SizedBox(width: 16.0),
                IconButton(
                  onPressed: () {
                    audioProvider.resetRecording();
                  },
                  icon: const Icon(Icons.refresh),
                  iconSize: 50,
                ),
              ],
            ),
          const Spacer(),
        ],
      ),
    );
  }
}
