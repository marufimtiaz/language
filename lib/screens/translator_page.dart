import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class TranslatorPage extends StatefulWidget {
  @override
  _TranslatorPageState createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  final translator = GoogleTranslator();
  final TextEditingController _controller = TextEditingController();
  String _outputText = '';
  String? _selectedLanguage;
  String _error = '';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'de', 'name': 'German'},
    {'code': 'it', 'name': 'Italian'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'ru', 'name': 'Russian'},
    {'code': 'zh-cn', 'name': 'Chinese (Simplified)'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'ko', 'name': 'Korean'},
    {'code': 'ar', 'name': 'Arabic'},
    {'code': 'hi', 'name': 'Hindi'},
  ];

  @override
  void initState() {
    super.initState();

    // Add listener to controller
    _controller.addListener(() {
      if (_selectedLanguage != null) {
        _translateText();
      }
    });
  }

  void _translateText() async {
    String inputText = _controller.text;

    if (inputText.isNotEmpty && _selectedLanguage != null) {
      setState(() {
        _error = '';
        _outputText = 'Translating...';
      });
      try {
        var translation =
            await translator.translate(inputText, to: _selectedLanguage!);
        setState(() {
          _outputText = translation.text;
        });
      } catch (e) {
        setState(() {
          _error = 'Translation failed: ${e.toString()}';
          _outputText = '';
        });
      }
    } else {
      setState(() {
        _outputText = ''; // Clear output if input is empty
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Translator'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Enter text to translate',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: DropdownButton(
                  isExpanded: false,
                  hint: const Text('Select Language'),
                  value: _selectedLanguage,
                  underline: const SizedBox(),
                  items: _languages.map((language) {
                    return DropdownMenuItem(
                      value: language['code'],
                      child: Text(language['name']!),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLanguage = newValue;
                      // Trigger translation when language is selected
                      if (_controller.text.isNotEmpty) {
                        _translateText();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_error.isNotEmpty)
                Text(_error, style: const TextStyle(color: Colors.red)),
              if (_outputText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(_outputText),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is removed from the widget tree
    _controller.dispose();
    super.dispose();
  }
}
