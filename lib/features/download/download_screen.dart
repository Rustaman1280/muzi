import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/providers/app_providers.dart';

class DownloadScreen extends ConsumerWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        centerTitle: true,
      ),
      body: downloadState.queue.isEmpty && downloadState.completed.isEmpty
          ? _buildEmptyState(context)
          : _buildDownloadList(context, ref, downloadState),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDownloadDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Downloads',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a download',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadList(BuildContext context, WidgetRef ref, DownloadQueueState state) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Queue (${state.queue.length})'),
              Tab(text: 'Completed (${state.completed.length})'),
              Tab(text: 'Failed (${state.failed.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildQueueTab(context, ref, state.queue),
                _buildCompletedTab(context, state.completed),
                _buildFailedTab(context, ref, state.failed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueTab(BuildContext context, WidgetRef ref, List<DownloadItem> queue) {
    if (queue.isEmpty) {
      return const Center(child: Text('No downloads in queue'));
    }

    return ListView.builder(
      itemCount: queue.length,
      itemBuilder: (context, index) {
        final item = queue[index];
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.download),
          ),
          title: Text(item.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.url),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: item.progress / 100),
              Text('${item.progress.toStringAsFixed(1)}%'),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () {
              // TODO: Implement pause/resume functionality
            },
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab(BuildContext context, List<DownloadItem> completed) {
    if (completed.isEmpty) {
      return const Center(child: Text('No completed downloads'));
    }

    return ListView.builder(
      itemCount: completed.length,
      itemBuilder: (context, index) {
        final item = completed[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.check, color: Colors.white),
          ),
          title: Text(item.title),
          subtitle: Text(item.url),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'play',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Text('Play'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'play') {
                // TODO: Play the downloaded file
              } else if (value == 'delete') {
                // TODO: Delete the downloaded file
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildFailedTab(BuildContext context, WidgetRef ref, List<DownloadItem> failed) {
    if (failed.isEmpty) {
      return const Center(child: Text('No failed downloads'));
    }

    return ListView.builder(
      itemCount: failed.length,
      itemBuilder: (context, index) {
        final item = failed[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.red,
            child: Icon(Icons.error, color: Colors.white),
          ),
          title: Text(item.title),
          subtitle: Text(item.url),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Retry download
              final controller = ref.read(downloadQueueProvider.notifier);
              controller.addToQueue(item.copyWith(status: DownloadStatus.pending));
            },
          ),
        );
      },
    );
  }

  void _showAddDownloadDialog(BuildContext context, WidgetRef ref) {
    final urlController = TextEditingController();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Download'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                final controller = ref.read(downloadQueueProvider.notifier);
                controller.addToQueue(DownloadItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text,
                  url: urlController.text,
                ));
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
