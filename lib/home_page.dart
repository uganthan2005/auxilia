import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class Task {
  String title;
  bool isCompleted;
  
  Task({required this.title, this.isCompleted = false});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Task> _tasks = [];
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _summarizeController = TextEditingController();
  String _summaryResult = '';
  bool _isSummarizing = false;

  static const String _geminiApiKey = String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: 'NO_KEY_PROVIDED');

  Future<void> _summarizeTextWithGemini() async {
    if (_summarizeController.text.isEmpty) {
      setState(() {
        _summaryResult = 'Please enter text or a URL to summarize.';
      });
      return;
    }

    if (_geminiApiKey == 'NO_KEY_PROVIDED') {
      setState(() {
        _summaryResult =
            'Error: Gemini API Key not provided via --dart-define during build.';
        _isSummarizing = false;
      });
      return;
    }

    setState(() {
      _isSummarizing = true;
      _summaryResult = '';
    });
    FocusScope.of(context).unfocus();

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: _geminiApiKey,
      );
      final prompt =
          "Summarize the following text concisely, focusing on the main points:\n\n${_summarizeController.text}";
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      setState(() {
        _summaryResult = response.text ?? "Could not get summary.";
        _isSummarizing = false;
      });
    } catch (e) {
      print("Error calling Gemini API: $e");
      setState(() {
        _summaryResult = "Error summarizing: ${e.toString()}";
        _isSummarizing = false;
      });
    }
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(Task(title: _taskController.text));
        _taskController.clear();
      });
    }
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
  }

  @override
  void dispose() {
    _taskController.dispose();
    _summarizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home - Tasks & Summaries'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('Simplify Information (with Gemini)', 
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            TextField(
              controller: _summarizeController,
              decoration: const InputDecoration(
                hintText: 'Enter text to summarize...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isSummarizing ? null : _summarizeTextWithGemini,
              icon: _isSummarizing 
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.summarize),
              label: Text(_isSummarizing ? 'Summarizing...' : 'Summarize with AI'),
            ),
            const SizedBox(height: 10),
            if (_summaryResult.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(_summaryResult),
              ),
            const Divider(height: 30),
            Text('Task Management',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            TextField(
              controller: _taskController,
              decoration: const InputDecoration(
                hintText: 'Add a new task...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addTask(),
            ),
            const SizedBox(height: 10),
            ..._tasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              return ListTile(
                leading: Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => _toggleTask(index),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}