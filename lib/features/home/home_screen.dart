import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/models/song.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final audio = ref.read(audioControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muziek'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    'Your Library',
                    'Browse your music',
                    Icons.library_music,
                    () {
                      // TODO: Navigate to library
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    'Recently Played',
                    'Your recent tracks',
                    Icons.history,
                    () {
                      // TODO: Navigate to recent
                    },
                  ),
                ),
              ],
            ),
          ),

          // Demo Music Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Demo Songs',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _getDemoSongs().length,
                      itemBuilder: (context, index) {
                        final song = _getDemoSongs()[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.music_note,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(song.title),
                          subtitle: Text(song.artist),
                          trailing: const Icon(Icons.more_vert),
                          onTap: () {
                            audio.loadAndPlay(_getDemoSongs(), startIndex: index);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Song> _getDemoSongs() {
    return [
      Song(
        id: '1',
        title: 'Demo Song 1',
        artist: 'Demo Artist',
        album: 'Demo Album',
        filePath: '/demo/song1.mp3',
        duration: const Duration(minutes: 3, seconds: 30),
      ),
      Song(
        id: '2',
        title: 'Another Demo Track',
        artist: 'Another Artist',
        album: 'Another Album',
        filePath: '/demo/song2.mp3',
        duration: const Duration(minutes: 4, seconds: 15),
      ),
      Song(
        id: '3',
        title: 'Third Demo Song',
        artist: 'Third Artist',
        album: 'Third Album',
        filePath: '/demo/song3.mp3',
        duration: const Duration(minutes: 2, seconds: 45),
      ),
    ];
  }
}
