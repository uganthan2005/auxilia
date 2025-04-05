import 'package:flutter/material.dart';
import 'package:auxilia/home_page.dart';
import 'package:auxilia/scan_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // Import speech_to_text

// Import Firebase Core
import 'package:firebase_core/firebase_core.dart';
// Import the generated Firebase options
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _requestPermissions();
  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  await Permission.camera.request();
  await Permission.microphone.request(); // Ensure microphone permission
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroGuide Prototype',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Define routes for potential named navigation later if needed
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/home': (context) => const HomePage(), // Optional named route
        '/scan': (context) => const ScanPage(), // Optional named route
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final stt.SpeechToText _speech = stt.SpeechToText(); // Speech instance
  bool _isListening = false;
  String _voiceStatus = "Press mic to give command";

  // List of pages remains the same
  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    ScanPage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeechRecognizer();
  }

  Future<void> _initializeSpeechRecognizer() async {
    bool available = await _speech.initialize(
      onError: (error) {
        print("Speech recognition error: $error");
        setState(() => _voiceStatus = "Speech error: $error");
      },
      onStatus: (status) {
        print("Speech recognition status: $status");
        setState(() => _voiceStatus = "Status: $status");
        if (status == 'notListening' || status == 'done') {
          setState(() => _isListening = false);
        }
      },
    );
    if (available) {
      setState(() => _voiceStatus = "Mic ready. Press to command.");
    } else {
      setState(() => _voiceStatus = "Speech recognition not available.");
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- Voice Command Handling ---
  void _listenForNavigation() async {
    if (!_isListening && _speech.isAvailable) {
      setState(() {
        _isListening = true;
        _voiceStatus = "Listening...";
      });
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            String command = result.recognizedWords.toLowerCase();
            print("Final command: $command");
            _handleCommand(command);
            setState(() => _isListening = false); // Reset after final result
          } else {
            // Optional: Show partial results while listening
            // setState(() => _voiceStatus = "Heard: ${result.recognizedWords}");
          }
        },
        listenFor: const Duration(seconds: 5), // Adjust duration as needed
        pauseFor: const Duration(seconds: 3),
        partialResults: true, // Set true to get intermediate results if needed
        localeId: "en_US", // Specify locale if needed
        onSoundLevelChange: (level) => print("Mic level: $level"), // Optional
      );
    } else if (_isListening){
      _stopListening(); // Allow tapping mic again to stop
    } else {
      print("Speech recognition not available or already listening.");
      setState(() => _voiceStatus = "Speech not ready. Try again.");
      // Optionally try re-initializing: await _initializeSpeechRecognizer();
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
        _voiceStatus = "Mic ready. Press to command.";
      });
    }
  }

  void _handleCommand(String command) {
    setState(() => _voiceStatus = "Processing: $command"); // Feedback
    bool navigated = false;
    if (command.contains("home") || command.contains("task") || command.contains("summary")) {
      if (_selectedIndex != 0) {
        setState(() => _selectedIndex = 0);
        navigated = true;
      }
    } else if (command.contains("scan") || command.contains("recognize") || command.contains("camera") || command.contains("vision")) {
      if (_selectedIndex != 1) {
        setState(() => _selectedIndex = 1);
        navigated = true;
      }
    }

    if (navigated) {
      setState(() => _voiceStatus = "Navigated. Mic ready.");
    } else {
      setState(() => _voiceStatus = "Command understood, but already on page or not recognized.");
      // Consider adding TTS feedback here: "Already on Home page" or "Command not recognized"
    }
    // Reset listening state potentially after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) { // Check if widget is still in the tree
        setState(() {
          _isListening = false; // Ensure listening state is reset
          if (!navigated) _voiceStatus = "Command not recognized for navigation.";
          else _voiceStatus = "Mic ready. Press to command."; // Reset prompt
        });
      }
    });
  }
  // --- End Voice Command Handling ---


  @override
  void dispose() {
    _speech.stop(); // Ensure speech listener is stopped
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Use IndexedStack to keep page state when switching tabs
        child: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        // child: _widgetOptions.elementAt(_selectedIndex), // Simpler, but resets page state
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Scan',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal[800],
        onTap: _onItemTapped,
      ),
      // Add Floating Action Button for Voice Commands
      floatingActionButton: FloatingActionButton(
        onPressed: _listenForNavigation,
        tooltip: 'Voice Command',
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
        backgroundColor: _isListening ? Colors.red : Colors.teal,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Place FAB nicely
    );
  }
}