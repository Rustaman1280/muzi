import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/app_providers.dart';
import 'package:go_router/go_router.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(audioControllerProvider);
  final controller = ref.read(audioControllerProvider.notifier);

  if (state.current == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Navigate via go_router so it works with MaterialApp.router
        context.push('/player', extra: {
          'title': state.current!.title,
          'artist': state.current!.artist,
          'artwork': const AssetImage('assets/images/foto (1).jpg'),
          'duration': state.duration ?? Duration.zero,
          'position': state.position,
          'playing': state.playing,
        });
      },
      child: ClipRRect(
        child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            border: const Border(top: BorderSide(color: Colors.white24, width: 0.6)),
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
                color: Theme.of(context).colorScheme.primary.withOpacity(.25),
              ),
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            
            // Song Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text(state.current!.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black54)]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
          Text(state.current!.artist,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  _ProgressBar(duration: state.duration),
                ],
              ),
            ),
            
                // Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(state.playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
                      onPressed: () {
                        if (state.playing) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () {
                        controller.stop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _ProgressBar extends ConsumerWidget {
  final Duration? duration;
  const _ProgressBar({required this.duration});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(audioControllerProvider).position;
    final total = duration ?? Duration.zero;
    final value = total.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / total.inMilliseconds)
            .clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 4,
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        valueColor: AlwaysStoppedAnimation(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
