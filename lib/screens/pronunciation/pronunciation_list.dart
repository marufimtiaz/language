import 'package:flutter/material.dart';
import 'package:language/screens/pronunciation/audio_record_page.dart';
import 'package:provider/provider.dart';

import '../../providers/audio_provider.dart';
import '../../providers/pronunciation_provider.dart';

class PronunciationListPage extends StatelessWidget {
  final String classId;
  const PronunciationListPage({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pronunciation Texts'),
      ),
      body: Consumer<PronunciationProvider>(
        builder: (context, provider, child) {
          if (provider.pronunciations.isEmpty) {
            provider.fetchPronunciations();
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: provider.pronunciations.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(
                      provider.pronunciations[index],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider(
                            create: (context) => AudioProvider(),
                            child: AudioRecordingPage(
                                classId: classId, pronunciationIndex: index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
