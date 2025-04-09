import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/voice_service.dart';
import '../models/task.dart';

class VoiceInputButton extends StatefulWidget {
  final Function(Task?) onTaskRecognized;
  final double size;
  final Color? color;

  const VoiceInputButton({
    super.key,
    required this.onTaskRecognized,
    this.size = 56.0,
    this.color,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  String _transcription = '';
  bool _isProcessing = false;
  bool _isAvailable = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    final isAvailable = await _voiceService.init();
    setState(() {
      _isAvailable = isAvailable;
    });
  }

  Future<void> _toggleListening() async {
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    if (_isListening) {
      await _voiceService.stopListening();
      _animationController.stop();
    } else {
      setState(() {
        _transcription = '';
        _isListening = true;
      });
      
      _animationController.repeat(reverse: true);
      
      await _voiceService.startListening(
        onResult: (text) {
          setState(() {
            _transcription = text;
            _isProcessing = true;
          });
          _processVoiceCommand(text);
        },
        onComplete: () {
          setState(() {
            _isListening = false;
          });
          _animationController.stop();
        },
      );
    }
  }

  Future<void> _processVoiceCommand(String text) async {
    // Parse voice command to create a task
    final task = _voiceService.parseVoiceCommand(text);
    
    // Pass the task back to the parent
    widget.onTaskRecognized(task);
    
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Transcription display
        if (_transcription.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _transcription,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
          ),
          
        // Voice input button
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening 
                ? Colors.red
                : color,
              boxShadow: [
                BoxShadow(
                  color: (_isListening ? Colors.red : color).withOpacity(0.3),
                  blurRadius: _isListening ? 12.0 : 8.0,
                  spreadRadius: _isListening ? 4.0 : 2.0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isProcessing ? null : _toggleListening,
                customBorder: const CircleBorder(),
                child: Center(
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                              size: _isListening
                                  ? 24 + (_animationController.value * 4)
                                  : 24,
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 