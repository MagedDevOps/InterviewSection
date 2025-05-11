// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Added for text-to-speech
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../constants/colors.dart';
import '../utils/background_decorations.dart';
import '../models/interview_model.dart';
import '../services/fixed_api_service.dart';
import 'score_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class InterviewScreen extends StatefulWidget {
  final String field;
  final List<String> technologies;
  final String difficulty;

  const InterviewScreen({
    super.key,
    required this.field,
    required this.technologies,
    required this.difficulty,
  });

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen>
    with SingleTickerProviderStateMixin {
  int seconds = 59;
  int minutes = 0; // Changed to 1 minute per question
  late Timer timer;
  late AnimationController _waveformController;
  late Animation<double> _waveformAnimation;
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  List<double> _waveformData = List.generate(12, (index) => 0.0);
  Timer? _waveformTimer;
  bool _isTimeUp = false;

  // Text to speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  // Interview state
  InterviewModel? _interviewModel;
  bool _isLoading = true;
  String? _currentRecordingPath;
  bool _isEvaluating = false;
  String _statusMessage = 'Loading questions...';
  bool _hasError = false;

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _transcribedText = '';

  bool _isButtonLoading = false;
  Timer? _loadingTimeoutTimer;
  DateTime? _lastRecordTap;

  @override
  void initState() {
    super.initState();
    _initWaveformAnimation();
    _setupTextToSpeech();
    _initSpeechToText();
    _requestPermissions();
    _loadInterviewQuestions();
    _loadingTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _statusMessage =
              'Loading timed out. Please check your connection and try again.';
        });
      }
    });
  }

  // Setup text to speech with male voice
  Future<void> _setupTextToSpeech() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(1);
    await _flutterTts.setVolume(0.7);
    await _flutterTts.setPitch(0.9); // Lower pitch for male voice

    // Set up completion listener
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  // Speak text with TTS
  Future<void> _speakQuestion(String question) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
      return;
    }

    setState(() {
      _isSpeaking = true;
    });

    await _flutterTts.speak(question);
  }

  // Initialize speech to text
  Future<void> _initSpeechToText() async {
    if (kIsWeb) {
      // Show a message or use a web alternative
      return;
    }
    bool available = await _speech.initialize(
      onError: (error) => print('Speech to text error: $error'),
      onStatus: (status) => print('Speech to text status: $status'),
    );
    if (!available) {
      print('Speech to text not available');
    }
  }

  // Start listening for speech
  Future<void> _startListening() async {
    if (kIsWeb) {
      // Show a message or use a web alternative
      return;
    }
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _transcribedText = '';
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _transcribedText = result.recognizedWords;
            });
          },
          localeId: 'en_US',
        );
      }
    }
  }

  // Stop listening for speech
  Future<void> _stopListening() async {
    if (kIsWeb) {
      // Show a message or use a web alternative
      return;
    }
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  // Request all necessary permissions
  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      // Show a message or use a web alternative
      return;
    }
    await [Permission.microphone, Permission.storage].request();
  }

  // Check if microphone permission is granted
  Future<bool> _checkMicPermission() async {
    if (kIsWeb) {
      // Show a message or use a web alternative
      return false;
    }
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    } else {
      // Request permission again with proper error handling
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
  }

  // Load interview questions from API
  Future<void> _loadInterviewQuestions() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading questions...';
      _hasError = false;
    });
    try {
      List<String> questions;
      if (kIsWeb) {
        questions = [
          "What are your primary strengths in ${widget.field} development?",
          "Describe a challenging project you worked on with ${widget.technologies.join(', ')}.",
          "How do you approach debugging issues in your code?",
          "What development methodologies are you familiar with?",
          "How do you stay updated with the latest technologies in your field?",
        ];
      } else {
        questions = await FixedApiService.generateInterviewQuestions(
          field: widget.field,
          technologies: widget.technologies,
          difficulty: widget.difficulty,
        );
      }
      final interviewQuestions =
          questions.map((q) => InterviewQuestion(question: q)).toList();
      if (!mounted) return;
      setState(() {
        _interviewModel = InterviewModel(
          field: widget.field,
          technologies: widget.technologies,
          difficulty: widget.difficulty,
          questions: interviewQuestions,
        );
        _isLoading = false;
        _hasError = false;
        startTimer();
        if (interviewQuestions.isNotEmpty) {
          _speakQuestion(interviewQuestions[0].question);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _statusMessage = 'Error loading questions: $e';
      });
    } finally {
      _loadingTimeoutTimer?.cancel();
    }
  }

  void _initWaveformAnimation() {
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _waveformAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _waveformController, curve: Curves.easeInOut),
    );

    _waveformController.repeat(reverse: true);
  }

  Future<String> _getAudioFilePath() async {
    if (kIsWeb) {
      throw UnsupportedError('Audio recording is not supported on web.');
    }
    // Use a simple timestamp-based filename
    return 'recording_${DateTime.now().millisecondsSinceEpoch}.aac';
  }

  Future<void> _startRecording() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording is not supported on web.')),
      );
      return;
    }
    // Debounce rapid taps
    final now = DateTime.now();
    if (_lastRecordTap != null &&
        now.difference(_lastRecordTap!) < const Duration(seconds: 1)) {
      return;
    }
    _lastRecordTap = now;
    setState(() => _isButtonLoading = true);
    try {
      bool hasPermission = await _checkMicPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission denied. Please enable it in app settings.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => _isButtonLoading = false);
        return;
      }
      if (_isSpeaking) {
        await _flutterTts.stop();
        if (mounted)
          setState(() {
            _isSpeaking = false;
          });
      }
      await _startListening();
      final path = await _getAudioFilePath();
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _currentRecordingPath = path;
        _isButtonLoading = false;
      });
      _startWaveformUpdate();
    } catch (e) {
      print('Recording error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
        setState(() => _isButtonLoading = false);
      }
    }
  }

  Future<void> _stopRecording() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording is not supported on web.')),
      );
      return;
    }
    setState(() => _isButtonLoading = true);
    try {
      final path = await _audioRecorder.stop();
      await _stopListening();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isButtonLoading = false;
      });
      _stopWaveformUpdate();
      print('Recording saved to: $path');
      if (_interviewModel != null && path != null) {
        await _evaluateAnswer(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error stopping recording: $e')));
        setState(() => _isButtonLoading = false);
      }
    }
  }

  // Evaluate the recorded answer
  Future<void> _evaluateAnswer(String audioPath) async {
    if (_interviewModel == null) return;

    setState(() {
      _isEvaluating = true;
      _statusMessage = 'Evaluating your answer...';
    });

    try {
      // Use the transcribed text instead of placeholder
      final transcribedAnswer =
          _transcribedText.isNotEmpty
              ? _transcribedText
              : "No speech was detected. Please try recording your answer again.";

      // Save the answer to the current question
      _interviewModel!.currentQuestion.answer = transcribedAnswer;

      // Evaluate the answer using the API
      final evaluation = await FixedApiService.evaluateAnswer(
        question: _interviewModel!.currentQuestion.question,
        answer: transcribedAnswer,
        field: widget.field,
        technologies: widget.technologies,
        difficulty: widget.difficulty,
      );

      // Update the question with the evaluation results
      setState(() {
        _interviewModel!.currentQuestion.score = evaluation['score'];
        _interviewModel!.currentQuestion.feedback = evaluation['feedback'];
        _isEvaluating = false;
        _transcribedText = ''; // Reset transcribed text
      });
    } catch (e) {
      setState(() {
        _isEvaluating = false;
        _statusMessage = 'Error evaluating answer: $e';
      });
    }
  }

  // Skip the current question
  void _skipQuestion() {
    if (_interviewModel == null) return;

    // If recording, stop it first
    if (_isRecording) {
      _stopRecording();
      return;
    }

    // Stop TTS if it's speaking
    if (_isSpeaking) {
      _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
    }

    if (_interviewModel!.hasNextQuestion) {
      _nextQuestion();
    } else {
      _finishInterview();
    }
  }

  // Move to the next question or finish the interview
  void _nextQuestion() {
    if (_interviewModel == null) return;

    // Stop TTS if it's speaking
    if (_isSpeaking) {
      _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
    }

    if (_interviewModel!.hasNextQuestion) {
      setState(() {
        _interviewModel!.nextQuestion();
        // Reset timer for the new question
        minutes = 0;
        seconds = 59;
        _isTimeUp = false;

        // Speak the new question
        _speakQuestion(_interviewModel!.currentQuestion.question);
      });
    } else {
      _finishInterview();
    }
  }

  // Finish the interview and navigate to the score screen
  void _finishInterview() {
    if (_interviewModel == null) return;

    // Stop TTS if it's speaking
    if (_isSpeaking) {
      _flutterTts.stop();
    }

    setState(() {
      _interviewModel!.isCompleted = true;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreScreen(interviewModel: _interviewModel!),
      ),
    );
  }

  void _startWaveformUpdate() {
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _waveformData = List.generate(12, (index) {
          // Simulate audio levels with random values
          return (0.2 +
              (0.8 * (index % 3) / 2) +
              (0.2 * _waveformAnimation.value));
        });
      });
    });
  }

  void _stopWaveformUpdate() {
    _waveformTimer?.cancel();
    setState(() {
      _waveformData = List.generate(12, (index) => 0.0);
    });
  }

  @override
  void dispose() {
    timer.cancel();
    _waveformController.dispose();
    _waveformTimer?.cancel();
    _audioRecorder.dispose();
    _flutterTts.stop();
    _flutterTts.setCompletionHandler(() {});
    _speech.stop();
    _loadingTimeoutTimer?.cancel();
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (seconds > 0) {
          seconds--;
        } else {
          if (minutes > 0) {
            minutes--;
            seconds = 59;
          } else {
            timer.cancel();
            _isTimeUp = true;

            // Auto-skip when time is up
            if (!_isEvaluating && _interviewModel != null) {
              // If recording was in progress, stop it first
              if (_isRecording) {
                _stopRecording();
              } else {
                // Skip to next question
                _skipQuestion();
              }
            }
          }
        }
      });
    });
  }

  String formatTime() {
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          const BackgroundDecorations(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child:
                _isLoading
                    ? Center(
                      key: const ValueKey('loading'),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primaryPurple,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                    : _hasError
                    ? Center(
                      key: const ValueKey('error'),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadInterviewQuestions,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _interviewModel != null
                    ? SafeArea(
                      key: const ValueKey('content'),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timer and progress indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Question progress
                                Text(
                                  'Question ${_interviewModel!.currentQuestionIndex + 1}/${_interviewModel!.questions.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Timer
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _isTimeUp
                                            ? Colors.red
                                            : AppColors.darkPurple,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.timer,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Question card
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Question
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkPurple,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Question:',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.primaryPurple,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              // Text-to-speech toggle button
                                              IconButton(
                                                onPressed: () {
                                                  _speakQuestion(
                                                    _interviewModel!
                                                        .currentQuestion
                                                        .question,
                                                  );
                                                },
                                                icon: Icon(
                                                  _isSpeaking
                                                      ? Icons.volume_off
                                                      : Icons.volume_up,
                                                  color: Colors.white,
                                                ),
                                                tooltip:
                                                    _isSpeaking
                                                        ? 'Stop Speaking'
                                                        : 'Speak Question',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _interviewModel!
                                                .currentQuestion
                                                .question,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Evaluation results if available
                                    if (_interviewModel!
                                            .currentQuestion
                                            .score !=
                                        null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.darkPurple,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primaryPurple,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Evaluation:',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.primaryPurple,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _getScoreColor(
                                                      _interviewModel!
                                                          .currentQuestion
                                                          .score!,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Score: ${_interviewModel!.currentQuestion.score}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _interviewModel!
                                                      .currentQuestion
                                                      .feedback ??
                                                  '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // Recording status and controls
                            if (_isEvaluating) ...[
                              Center(
                                child: Column(
                                  children: [
                                    const CircularProgressIndicator(
                                      color: AppColors.primaryPurple,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _statusMessage,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Waveform visualization
                              if (_isRecording) ...[
                                Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.darkPurple,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(
                                      _waveformData.length,
                                      (index) => AnimatedBuilder(
                                        animation: _waveformAnimation,
                                        builder: (context, child) {
                                          return Container(
                                            width: 4,
                                            height:
                                                10 +
                                                (_waveformData[index] * 40),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryPurple,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Action buttons
                              if (!kIsWeb) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (_interviewModel!
                                            .currentQuestion
                                            .score !=
                                        null) ...[
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isButtonLoading
                                                  ? null
                                                  : _nextQuestion,
                                          icon:
                                              _isButtonLoading
                                                  ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                  : const Icon(
                                                    Icons.navigate_next,
                                                  ),
                                          label: Text(
                                            _interviewModel!.hasNextQuestion
                                                ? 'Next Question'
                                                : 'Finish Interview',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryPurple,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isButtonLoading
                                                  ? null
                                                  : (_isRecording
                                                      ? _stopRecording
                                                      : _startRecording),
                                          icon:
                                              _isButtonLoading
                                                  ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                  : Icon(
                                                    _isRecording
                                                        ? Icons.stop
                                                        : Icons.mic,
                                                  ),
                                          label: Text(
                                            _isRecording
                                                ? 'Stop Recording'
                                                : 'Start Recording',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                _isRecording
                                                    ? Colors.red
                                                    : AppColors.primaryPurple,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isButtonLoading
                                                  ? null
                                                  : _skipQuestion,
                                          icon: const Icon(Icons.skip_next),
                                          label: const Text('Skip Question'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.darkPurple,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // Helper function to get color based on score
  Color _getScoreColor(int score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
