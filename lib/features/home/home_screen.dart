import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/models/song.dart';
import '../../core/repository/library_repository.dart' as librepo;
import '../../core/models/library_models.dart';
import '../../core/repository/playlist_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final audio = ref.read(audioControllerProvider.notifier);
  final repo = ref.read(librepo.libraryRepositoryProvider);

  // Gunakan FutureBuilder sederhana untuk memuat track dari Hive.
  return _HomeContent(audio: audio, repo: repo);
  }

  // (Card cepat dihapus karena tidak digunakan lagi)
}

class _HomeContent extends StatefulWidget {
  final dynamic audio;
  final dynamic repo; // LibraryRepository
  const _HomeContent({required this.audio, required this.repo});
  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  List<Track> _all = [];
  List<Playlist> _playlists = [];
  List<String> _artists = [];
  // Ambil semua gambar album/artist default dari folder; daftar hardcode awal
  final _albumPlaceholders = const [
    'assets/images/foto (1).jpg',
    'assets/images/foto (2).jpg',
    'assets/images/foto (3).jpg',
    'assets/images/foto (4).jpg',
    'assets/images/foto (5).jpg',
    'assets/images/foto (6).jpg',
    'assets/images/foto (7).jpg',
    'assets/images/foto (8).jpg',
    'assets/images/foto (9).jpg',
    'assets/images/foto (10).jpg',
    'assets/images/foto (11).jpg',
    'assets/images/foto (12).jpg',
    'assets/images/foto (13).jpg',
    'assets/images/foto (14).jpg',
    'assets/images/foto (15).jpg',
    'assets/images/foto (16).jpg',
    'assets/images/foto (17).jpg',
  ];
  final _artistPlaceholder = 'assets/images/foto (1).jpg';
  bool _loading = true;
  String _sort = 'title';
  String _filter = '';
  bool _ascending = true;

  late final PlaylistRepository _playlistRepo;

  @override
  void initState() {
    super.initState();
    _playlistRepo = PlaylistRepository();
    _load();
  }

  Future<void> _load() async {
    final tracks = await widget.repo.getAllTracks();
    setState(() {
      _all = tracks;
      _playlists = _playlistRepo.getAllPlaylists();
  _artists = ({ for(final t in tracks) t.artist }..removeWhere((e)=> e.trim().isEmpty)).map((e)=> e as String).toList()..sort();
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    setState(()=>_loading = true);
    await widget.repo.refreshLibrary();
    await _load();
  }

  List<Track> get _recent {
    final list = [..._all];
    list.sort((a,b)=> b.addedAt.compareTo(a.addedAt));
    return list.take(12).toList();
  }

  List<Track> get _filteredSorted {
    Iterable<Track> list = _all;
    if(_filter.isNotEmpty){
      final q = _filter.toLowerCase();
      list = list.where((t)=> t.title.toLowerCase().contains(q) || t.artist.toLowerCase().contains(q));
    }
    final l = list.toList();
    l.sort((a,b){
      int cmp;
      switch(_sort){
        case 'artist': cmp = a.artist.compareTo(b.artist); break;
        case 'album': cmp = a.album.compareTo(b.album); break;
        case 'added': cmp = a.addedAt.compareTo(b.addedAt); break;
        default: cmp = a.title.compareTo(b.title);
      }
      return _ascending ? cmp : -cmp;
    });
    return l;
  }

  void _playTracks(List<Track> tracks, int index){
    final songs = tracks.map((t)=> Song(
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album,
      filePath: t.path,
      duration: Duration(milliseconds: t.durationMs),
      albumArt: t.artworkPath,
    )).toList();
    widget.audio.loadAndPlay(songs, startIndex: index);
  }

  void _showTrackMenu(Track t){
    showModalBottomSheet(context: context, builder: (_) {
      return SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Play'),
            onTap: () { Navigator.pop(context); _playTracks([t],0); },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to Playlist'),
            onTap: () { Navigator.pop(context); _pickPlaylistAndAdd(t); },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Info'),
            onTap: () { Navigator.pop(context); _showInfo(t); },
          ),
        ]),
      );
    });
  }

  void _showInfo(Track t){
    showDialog(context: context, builder: (_)=> AlertDialog(
      title: Text(t.title),
      content: Text('Artist: ${t.artist}\nAlbum: ${t.album}\nDurasi: ${(t.durationMs/1000).round()}s'),
      actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Tutup'))],
    ));
  }

  Future<void> _pickPlaylistAndAdd(Track t) async {
    final pl = await showModalBottomSheet<Playlist>(context: context, builder: (_){
      return SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Pilih Playlist')), 
          ..._playlists.map((p)=> ListTile(
            title: Text(p.name),
            subtitle: Text('${p.trackIds.length} lagu'),
            onTap: ()=> Navigator.pop(context, p),
          )),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Playlist Baru'),
            onTap: () async {
              final name = await _promptText('Nama Playlist');
              if(name!=null && name.trim().isNotEmpty){
                final newPl = await _playlistRepo.createPlaylist(name.trim());
                setState(()=> _playlists = _playlistRepo.getAllPlaylists());
                Navigator.pop(context, newPl);
              }
            },
          )
        ],
      ));
    });
    if(pl!=null){
      await _playlistRepo.addTrack(pl, t.id);
      setState(()=> _playlists = _playlistRepo.getAllPlaylists());
    }
  }

  Future<String?> _promptText(String title) async {
    final ctrl = TextEditingController();
    return showDialog<String>(context: context, builder: (_)=> AlertDialog(
      title: Text(title),
      content: TextField(controller: ctrl, autofocus: true),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: ()=> Navigator.pop(context, ctrl.text), child: const Text('OK')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if(_loading){
      return const Center(child: CircularProgressIndicator());
    }
    if(_all.isEmpty){
      return _EmptyLibrary(onScan: _refresh);
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Koleksi Musik'),
            actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
          ),
          // Hero / Best of Week Carousel (placeholder picks first few songs)
          SliverToBoxAdapter(child: _buildHeroCarousel()),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16,12,16,4),
            child: _buildSearchAndSort(),
          )),
          if(_artists.isNotEmpty)
            SliverToBoxAdapter(child: _SectionHeader('Artis Populer')),
          if(_artists.isNotEmpty)
            SliverToBoxAdapter(child: SizedBox(
              height: 86,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _artists.take(12).length,
                separatorBuilder: (_, __)=> const SizedBox(width: 14),
                itemBuilder: (c,i){
                  final name = _artists[i];
                  return Column(
                    children: [
                      CircleAvatar(radius: 28, backgroundImage: AssetImage(_pickArtistImage(name))),
                      const SizedBox(height: 4),
                      SizedBox(width: 70, child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)))
                    ],
                  );
                },
              ),
            )),
          SliverToBoxAdapter(child: _SectionHeader('Rilisan Baru')),
          SliverToBoxAdapter(child: _buildNewReleases()),
          SliverToBoxAdapter(child: _SectionHeader('Recently Added')),
          SliverToBoxAdapter(child: SizedBox(
            height: 120,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _recent.length,
              separatorBuilder: (_, __)=> const SizedBox(width: 12),
              itemBuilder: (c,i){
                final t = _recent[i];
                return GestureDetector(
                  onTap: ()=> _playTracks(_recent, i),
                  onLongPress: ()=> _showTrackMenu(t),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Center(child: Icon(Icons.music_note, size: 36, color: Theme.of(context).colorScheme.onPrimaryContainer))),
                        Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          )),
          SliverToBoxAdapter(child: _SectionHeader('Playlists', action: IconButton(onPressed: () async {
            final name = await _promptText('Nama Playlist');
            if(name!=null && name.trim().isNotEmpty){
              await _playlistRepo.createPlaylist(name.trim());
              setState(()=> _playlists = _playlistRepo.getAllPlaylists());
            }
          }, icon: const Icon(Icons.add)) )),
          SliverToBoxAdapter(child: SizedBox(
            height: 140,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _playlists.length,
              separatorBuilder: (_, __)=> const SizedBox(width: 12),
              itemBuilder: (c,i){
                final p = _playlists[i];
                return GestureDetector(
                  onTap: () async {
                    // play whole playlist
                    final tracks = _playlistRepo.getTracksOf(p);
                    if(tracks.isNotEmpty){
                      _playTracks(tracks, 0);
                    }
                  },
                  onLongPress: () async {
                    final newName = await _promptText('Rename Playlist');
                    if(newName!=null && newName.trim().isNotEmpty){
                      await _playlistRepo.renamePlaylist(p, newName.trim());
                      setState(()=> _playlists = _playlistRepo.getAllPlaylists());
                    }
                  },
                  child: Container(
                    width: 110,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Center(child: Icon(Icons.album, size: 40, color: Theme.of(context).colorScheme.primary))),
                        Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${p.trackIds.length} lagu', style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          )),
          SliverToBoxAdapter(child: _SectionHeader('All Songs')),
          SliverList.builder(
            itemCount: _filteredSorted.length,
            itemBuilder: (c,i){
              final t = _filteredSorted[i];
              return ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: ()=> _playTracks(_filteredSorted, i),
                onLongPress: ()=> _showTrackMenu(t),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)), // space for MiniPlayer
        ],
      ),
    );
  }
  Widget _buildSearchAndSort(){
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Cari judul atau artist...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
            isDense: true,
          ),
          onChanged: (v)=> setState(()=> _filter = v),
        ),
        const SizedBox(height: 8),
        Row(children: [
          DropdownButton<String>(
            value: _sort,
            items: const [
              DropdownMenuItem(value: 'title', child: Text('Judul')),
              DropdownMenuItem(value: 'artist', child: Text('Artist')),
              DropdownMenuItem(value: 'album', child: Text('Album')),
              DropdownMenuItem(value: 'added', child: Text('Ditambahkan')),
            ],
            onChanged: (v){ if(v!=null) setState(()=> _sort = v); },
          ),
          IconButton(onPressed: ()=> setState(()=> _ascending = !_ascending), icon: Icon(_ascending? Icons.arrow_upward: Icons.arrow_downward)),
        ])
      ],
    );
  }

  String _pickAlbumImage(String album, {int? seed}){
    if(_albumPlaceholders.isEmpty) return _artistPlaceholder;
    final h = (seed ?? album.hashCode).abs();
    return _albumPlaceholders[h % _albumPlaceholders.length];
  }

  String _pickArtistImage(String artist){
    // Could later map to persistent selection; now deterministic via hash.
    return _pickAlbumImage(artist);
  }

  Widget _buildHeroCarousel(){
    final items = _all.take(5).toList();
    if(items.isEmpty) return const SizedBox();
    return SizedBox(
      height: 190,
      child: PageView.builder(
        controller: PageController(viewportFraction: .88),
        itemCount: items.length,
        itemBuilder: (c,i){
          final t = items[i];
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: ()=> _playTracks(items, i),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ]),
                  ),
                  child: Stack(
                    children:[
                      Positioned.fill(child: Opacity(
                        opacity: .18,
                        child: Image.asset(_pickAlbumImage(items[i].album, seed: i), fit: BoxFit.cover),
                      )),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pilihan Minggu Ini', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                            const Spacer(),
                            Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 12),
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: const Icon(Icons.play_arrow, color: Colors.white),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewReleases(){
    // treat most recently added as 'new releases'
    final recent = [..._all]..sort((a,b)=> b.addedAt.compareTo(a.addedAt));
    final items = recent.take(6).toList();
    return Column(
      children: [
        for(final t in items)
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(_pickAlbumImage(t.album, seed: t.id.hashCode), width: 48, height: 48, fit: BoxFit.cover),
            ),
            title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(icon: const Icon(Icons.more_vert), onPressed: ()=> _showTrackMenu(t)),
            onTap: ()=> _playTracks(items, items.indexOf(t)),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title; final Widget? action; const _SectionHeader(this.title,{this.action});
  @override
  Widget build(BuildContext context){
    return Padding(
      padding: const EdgeInsets.fromLTRB(16,16,16,8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          if(action!=null) action!,
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  final Future<void> Function() onScan;
  const _EmptyLibrary({required this.onScan});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_music, size: 64),
            const SizedBox(height: 16),
            const Text('Belum ada lagu. Mulai scan untuk memuat musik lokal.'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Musik'),
            ),
          ],
        ),
      ),
    );
  }
}

