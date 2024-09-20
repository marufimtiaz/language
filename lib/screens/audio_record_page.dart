import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecordingPage extends StatefulWidget {
  const AudioRecordingPage({super.key});

  @override
  _AudioRecordingPageState createState() => _AudioRecordingPageState();
}

class _AudioRecordingPageState extends State<AudioRecordingPage> {
  late final RecorderController recorderController;
  late final PlayerController playerController;
  bool isRecording = false;
  bool isRecordingCompleted = false;
  String recordingDuration = '00:00';

  Future<void> _checkPermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
    playerController = PlayerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
      ),
      body: Column(
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'),
            ),
          ),
          const Spacer(),
          if (!isRecording && !isRecordingCompleted)
            TextButton(
              onPressed: () async {
                await recorderController.record();
                setState(() {
                  isRecording = true;
                });
              },
              child: const Icon(Icons.mic, size: 50),
            ),
          if (isRecording)
            AudioWaveforms(
              size: Size(MediaQuery.of(context).size.width, 500),
              recorderController: recorderController,
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
          if (isRecording)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text('Recording voice $recordingDuration'),
            ),
          if (isRecording)
            ElevatedButton(
              onPressed: () async {
                await recorderController.stop();
                setState(() {
                  isRecording = false;
                  isRecordingCompleted = true;
                });
              },
              child: const Text('Stop'),
            ),
          if (isRecordingCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text('Total Length $recordingDuration'),
            ),
          if (isRecordingCompleted)
            AudioWaveforms(
              size: Size(MediaQuery.of(context).size.width, 100),
              recorderController: recorderController,
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
          if (isRecordingCompleted)
            IconButton(
              onPressed: () {
                // Play functionality
              },
              icon: const Icon(Icons.play_circle),
            ),
          if (isRecordingCompleted)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Upload functionality
                  },
                  child: const Text('Upload'),
                ),
                const SizedBox(width: 16.0),
                IconButton(
                  onPressed: () {
                    setState(() {
                      isRecordingCompleted = false;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          const Spacer(),
        ],
      ),
    );
  }
}
