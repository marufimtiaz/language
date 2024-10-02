import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/list_audio_provider.dart';
import '../../providers/pronunciation_provider.dart';
import '../../utils/ui_utils.dart';

class PronunciationSubmissionList extends StatefulWidget {
  final String classId;
  final int pronunciationIndex;

  const PronunciationSubmissionList(
      {super.key, required this.classId, required this.pronunciationIndex});

  @override
  State<PronunciationSubmissionList> createState() =>
      _PronunciationSubmissionListState();
}

class _PronunciationSubmissionListState
    extends State<PronunciationSubmissionList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pronunciationProvider =
          Provider.of<PronunciationProvider>(context, listen: false);
      pronunciationProvider.getStudentList(
          classId: widget.classId,
          pronunciationIndex: widget.pronunciationIndex);
      pronunciationProvider.getScores(
          widget.classId, widget.pronunciationIndex);
      pronunciationProvider.getStudentAudio(
          widget.classId, widget.pronunciationIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pronunciationProvider = Provider.of<PronunciationProvider>(context);
    var pronunciation =
        pronunciationProvider.classPronunciations[widget.pronunciationIndex];
    bool isActive = pronunciationProvider.isActive(pronunciation);
    final audioProvider =
        Provider.of<ListAudioProvider>(context, listen: false);

    print('Pronunciation: $pronunciation, isActive: $isActive');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pronunciation Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            onPressed: () {
              // Implement edit functionality
              _changeEndDate(pronunciation["dateEnd"].toDate(),
                  widget.pronunciationIndex, isActive);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Implement delete functionality
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete Pronunciation'),
                    content: const Text(
                        'Are you sure you want to delete this pronunciation? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Delete quiz
                          pronunciationProvider.deletePronunciation(
                              widget.classId, widget.pronunciationIndex);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await pronunciationProvider.getStudentList(
            classId: widget.classId,
            pronunciationIndex: widget.pronunciationIndex,
          );
          await pronunciationProvider.getScores(
              widget.classId, widget.pronunciationIndex);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Student List",
                  style: Theme.of(context).textTheme.titleLarge),
              Text(
                "Total ${pronunciationProvider.totalStudents} submissions",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: _buildStudentList(pronunciationProvider, audioProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreDropdown(
    PronunciationProvider pronunciationProvider,
    int? score,
    int index,
  ) {
    final List<Map<String, int>> scores = [
      {'code': 1, 'name': 1},
      {'code': 2, 'name': 2},
      {'code': 3, 'name': 3},
      {'code': 4, 'name': 4},
      {'code': 5, 'name': 5},
    ];

    return DropdownButton<int>(
      borderRadius: BorderRadius.circular(10),
      isExpanded: false,
      hint: Text(score == 0 ? 'Set Score' : score.toString()),
      value: score == 0 ? null : score,
      underline: const SizedBox(),
      items: scores.map((scoreItem) {
        return DropdownMenuItem<int>(
          value: scoreItem['code'],
          child: Text(scoreItem['name']!.toString()),
        );
      }).toList(),
      onChanged: (int? newValue) {
        pronunciationProvider.setScore(
          widget.classId,
          widget.pronunciationIndex,
          index,
          newValue!,
        );
      },
    );
  }

  Widget _buildStudentList(
    PronunciationProvider pronunciationProvider,
    ListAudioProvider audioProvider,
  ) {
    if (pronunciationProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (pronunciationProvider.studentList.isEmpty) {
      return const Center(
        child: Text("No students have submitted this pronunciation yet."),
      );
    } else {
      return ListView.builder(
        itemCount: pronunciationProvider.studentList.length,
        itemBuilder: (context, index) {
          var student = pronunciationProvider.studentList[index];
          String studentAudio =
              pronunciationProvider.studentAudio.length > index
                  ? pronunciationProvider.studentAudio[index]
                  : "";
          var score = pronunciationProvider.scores.length > index
              ? pronunciationProvider.scores[index]
              : null;

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                radius: 15,
                backgroundImage: student["profileImageUrl"] != null
                    ? NetworkImage(student["profileImageUrl"]!)
                    : null,
                child: student["profileImageUrl"] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(
                student["name"] ?? "Unknown",
                style: const TextStyle(fontSize: 18),
              ),
              subtitle: _buildScoreDropdown(
                pronunciationProvider,
                score,
                index,
              ),
              trailing: _buildPlayButton(
                audioProvider,
                index,
                studentAudio,
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _changeEndDate(
      DateTime date, int pronunciationIndex, bool isActive) async {
    DateTime? endDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isActive ? date : DateTime.now(),
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
      bool result =
          await Provider.of<PronunciationProvider>(context, listen: false)
              .updatePronunciationDate(
                  widget.classId, pronunciationIndex, endDate!);
      if (result) {
        UIUtils.showToast("Deadline updated");
      } else {
        UIUtils.showToast("Error updating deadline");
      }
    }
  }

  Widget _buildPlayButton(
    ListAudioProvider audioProvider,
    int index,
    String audioUrl,
  ) {
    return Consumer<ListAudioProvider>(
      builder: (context, provider, child) {
        return FilledButton.tonal(
          onPressed: () => provider.playAudio(index, audioUrl),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade100,
            shape: const CircleBorder(),
          ),
          child: Icon(
            provider.isPlaying(index)
                ? (provider.isPaused(index) ? Icons.play_arrow : Icons.pause)
                : Icons.play_arrow,
            size: 30,
            color: Colors.green.shade600,
          ),
        );
      },
    );
  }

  // Widget _buildInstructionCard(AudioProvider audioProvider, double width) {
  //   return Card(
  //     color: Colors.white,
  //     margin: const EdgeInsets.all(16),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: pronunciationText == null
  //           ? const Center(child: CircularProgressIndicator())
  //           : Column(
  //               children: [
  //                 Text(
  //                   pronunciationText!,
  //                   style: const TextStyle(fontSize: 18),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 Padding(
  //                   padding: const EdgeInsets.only(top: 16.0),
  //                   child: _buildCircularButton(
  //                     icon: audioProvider.isOnlinePlaying
  //                         ? (audioProvider.isOnlinePaused
  //                             ? Icons.play_arrow
  //                             : Icons.pause)
  //                         : Icons.play_arrow,
  //                     onPressed: teacherAudioUrl != null
  //                         ? () => audioProvider.isOnlinePlaying
  //                             ? (audioProvider.isOnlinePaused
  //                                 ? audioProvider
  //                                     .playOnlineAudio(teacherAudioUrl!)
  //                                 : audioProvider.pauseOnlinePlayback())
  //                             : audioProvider.playOnlineAudio(teacherAudioUrl!)
  //                         : () {},
  //                   ),
  //                 ),
  //               ],
  //             ),
  //     ),
  //   );
  // }
}
