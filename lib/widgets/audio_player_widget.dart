import 'package:flutter/material.dart';
import '../providers/audio_provider.dart';

class AudioPlayerWidget extends StatelessWidget {
  final AudioProvider audioProvider;
  final VoidCallback? onClose;

  const AudioPlayerWidget({
    super.key,
    required this.audioProvider,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Play/Pause Button
          IconButton(
            onPressed: () {
              if (audioProvider.isPlaying) {
                audioProvider.pause();
              } else {
                audioProvider.resume();
              }
            },
            icon: Icon(
              audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 32,
            ),
          ),
          
          // Progress and Time
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress Bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: audioProvider.progressPercentage,
                    onChanged: (value) {
                      if (audioProvider.totalDuration.inMilliseconds > 0) {
                        final position = Duration(
                          milliseconds: (value * audioProvider.totalDuration.inMilliseconds).round(),
                        );
                        audioProvider.seekTo(position);
                      }
                    },
                  ),
                ),
                
                // Time Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      audioProvider.formatDuration(audioProvider.currentPosition),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      audioProvider.formatDuration(audioProvider.totalDuration),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Close Button
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}

