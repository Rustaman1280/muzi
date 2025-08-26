import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/repository/library_repository.dart';

class LibraryScanWidget extends ConsumerStatefulWidget {
  const LibraryScanWidget({super.key});

  @override
  ConsumerState<LibraryScanWidget> createState() => _LibraryScanWidgetState();
}

class _LibraryScanWidgetState extends ConsumerState<LibraryScanWidget> {
  double _progress = 0.0;
  bool _scanning = false;
  String _status = 'Waiting for permission';

  Future<void> _start() async {
    setState(() {
      _scanning = true;
      _status = 'Requesting permissions';
    });
    final repo = ref.read(libraryRepositoryProvider);
    final ok = await repo.ensurePermissions();
    if (!ok) {
      setState(() {
        _status = 'Permission denied. Please enable in settings.';
        _scanning = false;
      });
      return;
    }
    setState(() => _status = 'Scanning library...');
    await repo.refreshLibrary(onProgress: (p) {
      setState(() {
        _progress = p;
      });
    });
    setState(() {
      _status = 'Completed';
      _scanning = false;
      _progress = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Library Setup', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_status),
            const SizedBox(height: 12),
            if (_scanning)
              LinearProgressIndicator(value: _progress == 0 ? null : _progress),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _scanning ? null : _start,
                  child: Text(_scanning ? 'Scanning...' : 'Start Scan'),
                ),
                const SizedBox(width: 12),
                if (_progress > 0 && _progress < 1)
                  Text('${(_progress * 100).toStringAsFixed(0)}%'),
              ],
            )
          ],
        ),
      ),
    );
  }
}
