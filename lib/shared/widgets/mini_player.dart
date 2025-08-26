import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/app_providers.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(audioControllerProvider);
  final controller = ref.read(audioControllerProvider.notifier);

  if (state.current == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Album Art
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            
            // Song Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.current!.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    state.current!.artist,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _PositionBar(duration: state.duration),
                ],
              ),
            ),
            
            // Controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(state.playing ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    if (state.playing) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.stop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionBar extends ConsumerWidget {
  final Duration? duration;
  const _PositionBar({required this.duration});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(audioControllerProvider.notifier);
    final position = ref.watch(audioControllerProvider).position;
    final total = duration ?? Duration.zero;
    final value = total.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / total.inMilliseconds)
            .clamp(0.0, 1.0);
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(trackHeight: 2),
      child: Slider(
        value: value,
        onChanged: (v) {
          if (total.inMilliseconds > 0) {
            final seekPos = Duration(
                milliseconds: (total.inMilliseconds * v).round());
            controller.seek(seekPos);
          }
        },
      ),
    );
  }
}
