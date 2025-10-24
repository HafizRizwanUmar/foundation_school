import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

enum AudioState { stopped, playing, paused, loading }

class AudioProvider with ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  AudioState _state = AudioState.stopped;
  String _currentText = '';
  String? _currentAudioUrl;
  double _speechRate = 0.5;
  double _speechPitch = 1.0;
  double _speechVolume = 0.8;
  String _selectedVoice = '';
  List<Map<String, String?>> _availableVoices = []; // Changed to allow nullable values
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isInitialized = false;

  // Getters
  AudioState get state => _state;
  String get currentText => _currentText;
  String? get currentAudioUrl => _currentAudioUrl;
  double get speechRate => _speechRate;
  double get speechPitch => _speechPitch;
  double get speechVolume => _speechVolume;
  String get selectedVoice => _selectedVoice;
  List<Map<String, String?>> get availableVoices => _availableVoices; // Updated type
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _state == AudioState.playing;
  bool get isPaused => _state == AudioState.paused;
  bool get isStopped => _state == AudioState.stopped;

  // Initialize audio services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize TTS
      await _initializeTts();
      
      // Initialize Audio Player
      await _initializeAudioPlayer();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing audio services: $e');
    }
  }

  // Initialize Text-to-Speech
  Future<void> _initializeTts() async {
    // Set TTS completion handler
    _flutterTts.setCompletionHandler(() {
      _state = AudioState.stopped;
      _currentText = '';
      notifyListeners();
    });

    // Set TTS error handler
    _flutterTts.setErrorHandler((message) {
      debugPrint('TTS Error: $message');
      _state = AudioState.stopped;
      notifyListeners();
    });

    // Get available voices
    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        // Store voices as-is, allowing nullable values
        _availableVoices = (voices as List<dynamic>)
            .cast<Map<dynamic, dynamic>>()
            .map((voice) => Map<String, String?>.from(
                voice.map((key, value) => MapEntry(key.toString(), value?.toString()))))
            .where((voice) => voice['name'] != null && voice['locale'] != null)
            .toList();

        // Set default voice (prefer English voices)
        final englishVoices = _availableVoices.where((voice) => 
            voice['locale']?.contains('en') == true).toList();
        
        if (englishVoices.isNotEmpty) {
          _selectedVoice = englishVoices.first['name'] ?? '';
          await _flutterTts.setVoice({
            'name': englishVoices.first['name'] ?? '',
            'locale': englishVoices.first['locale'] ?? ''
          });
        } else if (_availableVoices.isNotEmpty) {
          _selectedVoice = _availableVoices.first['name'] ?? '';
          await _flutterTts.setVoice({
            'name': _availableVoices.first['name'] ?? '',
            'locale': _availableVoices.first['locale'] ?? ''
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting voices: $e');
    }

    // Set default TTS settings
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_speechPitch);
    await _flutterTts.setVolume(_speechVolume);
  }

  // Initialize Audio Player
  Future<void> _initializeAudioPlayer() async {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      switch (state) {
        case PlayerState.playing:
          _state = AudioState.playing;
          break;
        case PlayerState.paused:
          _state = AudioState.paused;
          break;
        case PlayerState.stopped:
          _state = AudioState.stopped;
          _currentPosition = Duration.zero;
          break;
        case PlayerState.completed:
          _state = AudioState.stopped;
          _currentPosition = Duration.zero;
          break;
        case PlayerState.disposed:
          _state = AudioState.stopped;
          _currentPosition = Duration.zero;
          _currentAudioUrl = null;
          break;
      }
      notifyListeners();
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((Duration position) {
      _currentPosition = position;
      notifyListeners();
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _totalDuration = duration;
      notifyListeners();
    });
  }

  // Speak text using TTS
  Future<void> speakText(String text) async {
    if (!_isInitialized) await initialize();

    try {
      // Stop any current playback
      await stop();

      _currentText = text;
      _state = AudioState.loading;
      notifyListeners();

      await _flutterTts.speak(text);
      _state = AudioState.playing;
      notifyListeners();
    } catch (e) {
      debugPrint('Error speaking text: $e');
      _state = AudioState.stopped;
      notifyListeners();
    }
  }

  // Play audio from URL
  Future<void> playAudio(String audioUrl) async {
    if (!_isInitialized) await initialize();

    try {
      // Stop any current playback
      await stop();

      _currentAudioUrl = audioUrl;
      _state = AudioState.loading;
      notifyListeners();

      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _state = AudioState.stopped;
      notifyListeners();
    }
  }

  // Pause current playback
  Future<void> pause() async {
    try {
      if (_currentAudioUrl != null) {
        await _audioPlayer.pause();
      } else {
        await _flutterTts.pause();
      }
      _state = AudioState.paused;
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing: $e');
    }
  }

  // Resume playback
  Future<void> resume() async {
    try {
      if (_currentAudioUrl != null) {
        await _audioPlayer.resume();
      } else {
        // TTS doesn't support resume, restart from beginning
        if (_currentText.isNotEmpty) {
          await speakText(_currentText);
        }
      }
    } catch (e) {
      debugPrint('Error resuming: $e');
    }
  }

  // Stop playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      await _flutterTts.stop();
      
      _state = AudioState.stopped;
      _currentText = '';
      _currentAudioUrl = null;
      _currentPosition = Duration.zero;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping: $e');
    }
  }

  // Seek to position (for audio files only)
  Future<void> seekTo(Duration position) async {
    if (_currentAudioUrl != null) {
      try {
        await _audioPlayer.seek(position);
      } catch (e) {
        debugPrint('Error seeking: $e');
      }
    }
  }

  // Set speech rate
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    await _flutterTts.setSpeechRate(_speechRate);
    notifyListeners();
  }

  // Set speech pitch
  Future<void> setSpeechPitch(double pitch) async {
    _speechPitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_speechPitch);
    notifyListeners();
  }

  // Set speech volume
  Future<void> setSpeechVolume(double volume) async {
    _speechVolume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_speechVolume);
    notifyListeners();
  }

  // Set voice
  Future<void> setVoice(String voiceName) async {
    try {
      final voice = _availableVoices.firstWhere(
        (voice) => voice['name'] == voiceName,
        orElse: () => {'name': null, 'locale': null},
      );
      
      if (voice['name'] != null && voice['locale'] != null) {
        await _flutterTts.setVoice({
          'name': voice['name']!,
          'locale': voice['locale']!
        });
        _selectedVoice = voiceName;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting voice: $e');
    }
  }

  // Get progress percentage
  double get progressPercentage {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  // Format duration for display
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // Dispose resources
  @override
  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}