import 'dart:convert';
import 'dart:async'; // For Future.delayed
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import TTS
import 'package:http/http.dart' as http; // Import HTTP

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  String _scanResultText = 'Initialize camera to start scanning.'; // For UI feedback
  bool _isBusy = false; // To prevent multiple scans/analyses

  // --- Vision Analyzer Logic Integrated ---
  final FlutterTts _flutterTts = FlutterTts(); // TTS instance

  // Access Vision API Key via --dart-define
  static const String _visionApiKey = String.fromEnvironment(
      'VISION_API_KEY',
      defaultValue: 'NO_KEY_PROVIDED');
  final String _visionApiUrl = "https://vision.googleapis.com/v1/images:annotate";

  @override
  void initState() {
    super.initState();
    _initializeCameraAndTts();
  }

  Future<void> _initializeCameraAndTts() async {
     // Initialize Camera (as before)
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _scanResultText = "Error: No cameras found.");
        return;
      }
      _controller = CameraController(_cameras![0], ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _scanResultText = 'Camera ready. Press button to scan.';
      });
    } catch (e) {
      print("Error initializing camera: $e");
      setState(() => _scanResultText = "Error initializing camera: ${e.toString()}");
      _isCameraInitialized = false;
    }
     // Initialize TTS
     await _setupTts();
  }

  Future<void> _setupTts() async {
     try {
       // Basic TTS setup (add more config like rate, pitch, language checks if needed)
       await _flutterTts.awaitSpeakCompletion(true); // Wait for speaks to finish
       await _flutterTts.setLanguage("en-US"); // Set language
       await _flutterTts.setPitch(1.0);
       await _flutterTts.setSpeechRate(0.5);
       print("TTS Initialized");
     } catch (e) {
       print("Error initializing TTS: $e");
       setState(() { _scanResultText = "TTS Error: $e";});
     }
  }


  // --- Speak using TTS ---
  Future<void> _speak(String text) async {
    // Update UI text as well
    if (mounted) {
       setState(() {
          _scanResultText = text;
       });
    }
    try {
      await _flutterTts.speak(text);
    } catch (e) {
       print("TTS Speak Error: $e");
        // Optionally update UI about TTS error
       if (mounted) setState(() => _scanResultText = "TTS Speak Error. Check Logs.");
    }
  }

  // --- Analyze Image with Vision API ---
  Future<void> _analyzeImageWithVision(XFile imageFile) async {
    if (_visionApiKey == 'NO_KEY_PROVIDED') {
      await _speak("Error: Vision API Key not provided via --dart-define.");
      return;
    }

    setState(() => _isBusy = true); // Indicate processing
    await _speak("Analyzing image...");

    try {
      final bytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(bytes);

      String requestJson = jsonEncode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "OBJECT_LOCALIZATION", "maxResults": 5},
              {"type": "FACE_DETECTION", "maxResults": 5},
              {"type": "LABEL_DETECTION", "maxResults": 5}
            ]
          }
        ]
      });

      // ⚠️ WARNING: Use backend in production! Key in URL is insecure.
      // Even with --dart-define, this client-side call isn't fully secure.
      final response = await http.post(
        Uri.parse("$_visionApiUrl?key=$_visionApiKey"),
        headers: {"Content-Type": "application/json"},
        body: requestJson,
      ).timeout(const Duration(seconds: 30)); // Add timeout

      if (!mounted) return; // Check if widget is still valid

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // print("Vision API Response: $data"); // Debugging

        if (data['responses'] == null || data['responses'].isEmpty) {
          await _speak("Could not analyze the image. No response data.");
        } else {
          var analysis = data['responses'][0];
          String description = _parseVisionResponse(analysis);
          await _speak(description.isNotEmpty ? description : "I couldn't identify specific details.");
        }
      } else {
        print("Vision API Error: ${response.statusCode} ${response.body}");
        await _speak("Error analyzing image. Status: ${response.statusCode}");
      }
    } catch (e) {
       if (!mounted) return;
       print("Error during image analysis: $e");
        if (e is TimeoutException) {
           await _speak("Analysis timed out. Please try again.");
        } else {
           await _speak("An error occurred while analyzing.");
        }
    } finally {
       if (mounted) setState(() => _isBusy = false); // Re-enable button
    }
  }

  // --- Parse Vision Response (same helper function as before) ---
  String _parseVisionResponse(Map<String, dynamic> analysis) {
     List<String> parts = [];
     Set<String> seenObjects = {}; // Avoid duplicate object reporting

     // Object Localization
     if (analysis.containsKey('localizedObjectAnnotations')) {
        List<dynamic> objects = analysis['localizedObjectAnnotations'];
         objects.forEach((o) {
            String name = o['name']?.toLowerCase() ?? 'unknown object';
            if (name != 'unknown object' && !seenObjects.contains(name)) {
               seenObjects.add(name);
            }
         });
        if (seenObjects.isNotEmpty) {
           parts.add("I see objects like ${seenObjects.join(', ')}.");
        }
     }

      // Face Detection
     if (analysis.containsKey('faceAnnotations')) {
        List<dynamic> faces = analysis['faceAnnotations'];
        if (faces.isNotEmpty) {
           int faceCount = faces.length;
           String faceText = faceCount == 1 ? "a person" : "$faceCount people";
           String emotion = "";
           // Check primary face for basic emotion
           if (faces[0]['joyLikelihood'] == 'VERY_LIKELY' || faces[0]['joyLikelihood'] == 'LIKELY') {
              emotion = " who seems happy";
           } else if (faces[0]['sorrowLikelihood'] == 'VERY_LIKELY' || faces[0]['sorrowLikelihood'] == 'LIKELY') {
              emotion = " who seems sad";
           } else if (faces[0]['angerLikelihood'] == 'VERY_LIKELY' || faces[0]['angerLikelihood'] == 'LIKELY') {
              emotion = " who seems angry";
           } else if (faces[0]['surpriseLikelihood'] == 'VERY_LIKELY' || faces[0]['surpriseLikelihood'] == 'LIKELY') {
              emotion = " who seems surprised";
           }
           parts.add("I detected $faceText$emotion.");
        }
     }

      // Label Detection (Fallback/General Context)
      if (parts.isEmpty && analysis.containsKey('labelAnnotations')) {
        List<dynamic> labels = analysis['labelAnnotations'];
        if (labels.isNotEmpty) {
           String labelNames = labels.take(3).map((l) => l['description'].toLowerCase()).join(', ');
           parts.add("The scene includes $labelNames.");
        }
      }

     return parts.join(' ');
  }

  // --- Button Press Handler ---
  void _onScanButtonPressed() async {
    if (_controller == null || !_controller!.value.isInitialized || _isBusy) {
       print("Camera not ready or analysis in progress.");
       return;
    }

    try {
      // Capture image
      XFile imageFile = await _controller!.takePicture();

      if (!mounted) return; // Check again after await

      // Analyze and speak
      await _analyzeImageWithVision(imageFile);

    } catch (e) {
      print("Error taking picture: $e");
       if(mounted) await _speak("Error capturing image.");
    }
    // Note: _isBusy state is handled within _analyzeImageWithVision's finally block
  }


  @override
  void dispose() {
    _controller?.dispose(); // Dispose camera
    _flutterTts.stop(); // Stop TTS
    print("ScanPage disposed and resources released.");
    super.dispose();
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Recognize (Vision API)'),
      ),
      body: Column(
        children: [
          // Camera Preview Area
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: _isCameraInitialized && _controller != null
                    ? CameraPreview(_controller!)
                    : Column( // Show status text while initializing
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 10),
                          Text(_scanResultText, style: const TextStyle(color: Colors.white)),
                       ],
                    ),
              ),
            ),
          ),
          // Control and Result Area
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Column(
              children: [
                ElevatedButton.icon(
                  // Use the new handler and disable button when busy
                  onPressed: _isCameraInitialized && !_isBusy ? _onScanButtonPressed : null,
                  icon: _isBusy
                       ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(strokeWidth: 3))
                       : const Icon(Icons.camera),
                  label: Text(_isBusy ? 'Analyzing...' : 'Analyze Scene'), // Update label
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
                const SizedBox(height: 10),
                // Display the text that was spoken (or current status)
                Text(
                  _scanResultText,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}