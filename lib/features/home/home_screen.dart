import 'package:flutter/material.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/models/song.dart';
import '../../core/repository/library_repository.dart' as librepo;
import '../../core/models/library_models.dart';
import '../../core/repository/playlist_repository.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../ads/native_inline_ad.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.read(audioControllerProvider.notifier);
    final repo = ref.read(librepo.libraryRepositoryProvider);
    return _HomeContent(audio: audio, repo: repo);
  }
}

class _HomeContent extends StatefulWidget {
  final dynamic audio;
  final dynamic repo; // LibraryRepository
  const _HomeContent({required this.audio, required this.repo});
  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final ScrollController _scrollCtrl = ScrollController();
  List<Track> _all = [];
  List<Playlist> _playlists = [];
  final _albumPlaceholders = const [
  'assets/images/foto (1).jpg','assets/images/foto (2).jpg','assets/images/foto (3).jpg','assets/images/foto (4).jpg',
  'assets/images/foto (5).jpg','assets/images/foto (6).jpg','assets/images/foto (7).jpg','assets/images/foto (8).jpg',
  'assets/images/foto (9).jpg','assets/images/foto (10).jpg','assets/images/foto (11).jpg','assets/images/foto (12).jpg',
  'assets/images/foto (13).jpg','assets/images/foto (14).jpg','assets/images/foto (15).jpg','assets/images/foto (16).jpg','assets/images/foto (17).jpg',
  'assets/images/foto (18).jpg','assets/images/foto (19).jpg','assets/images/foto (20).jpg','assets/images/foto (21).jpg','assets/images/foto (22).jpg',
  'assets/images/foto (23).jpg','assets/images/foto (24).jpg','assets/images/foto (25).jpg','assets/images/foto (26).jpg','assets/images/foto (27).jpg',
  'assets/images/foto (28).jpg','assets/images/foto (29).jpg','assets/images/foto (30).jpg','assets/images/foto (31).jpg','assets/images/foto (32).jpg',
  'assets/images/foto (33).jpg','assets/images/foto (34).jpg','assets/images/foto (35).jpg','assets/images/foto (36).jpg','assets/images/foto (37).jpg',
  'assets/images/foto (38).jpg','assets/images/foto (39).jpg','assets/images/foto (40).jpg','assets/images/foto (41).jpg','assets/images/foto (42).jpg',
  'assets/images/foto (43).jpg','assets/images/foto (44).jpg',
  ];
  final _artistPlaceholder = 'assets/images/foto (1).jpg';
  bool _loading = true;
  String _sort = 'title';
  String _filter = '';
  bool _ascending = true;
  late final PlaylistRepository _playlistRepo;
  late final int _sessionSalt; // randomizes placeholder selection per app session
  // Single random banner ad
  static const _bannerAdUnitId = 'ca-app-pub-9165746388253869/7287719572';
  BannerAd? _singleBanner;
  int? _adInsertIndex; // index in combined list
  bool _adLoading = false;

  @override
  void initState() {
    super.initState();
    _playlistRepo = PlaylistRepository();
  _sessionSalt = Random().nextInt(1<<30);
  _load();
  }

  // (Removed multi-slot banner logic; single random banner used instead)

  @override
  void dispose(){
  _singleBanner?.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final tracks = await widget.repo.getAllTracks();
    setState(() {
      _all = tracks;
      _playlists = _playlistRepo.getAllPlaylists();
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
    final firstStart = widget.audio.state.current == null; // audio controller accessed via state
    widget.audio.loadAndPlay(songs, startIndex: index).then((_) {
      if((firstStart || mounted) && mounted){
        final current = songs[index];
  context.push('/player', extra: {
          'title': current.title,
          'artist': current.artist,
          'artwork': AssetImage(_pickAlbumImage(current.album, seed: current.id.hashCode)),
          'duration': current.duration,
          'position': Duration.zero,
          'playing': true,
        });
      }
    });
  }

  void _showTrackMenu(Track t){
    showModalBottomSheet(context: context, builder: (_) {
      return SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.play_arrow), title: const Text('Play'), onTap: () { Navigator.pop(context); _playTracks([t],0); }),
          ListTile(leading: const Icon(Icons.playlist_add), title: const Text('Add to Playlist'), onTap: () { Navigator.pop(context); _pickPlaylistAndAdd(t); }),
          ListTile(leading: const Icon(Icons.info_outline), title: const Text('Info'), onTap: () { Navigator.pop(context); _showInfo(t); }),
        ]),
      );
    });
  }

  void _showInfo(Track t){
    showDialog(context: context, builder: (_)=> AlertDialog(
      title: Text(t.title),
      content: Text('Artist: ${t.artist}\nAlbum: ${t.album}\nDurasi: ${(t.durationMs/1000).round()}s'),
      actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Tutup'))],
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
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E1A30), Color(0xFF0D1524), Color(0xFF0B111C)],
          ),
        ),
        child: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 4),
              child: _buildHeader(context),
            ),
          ),
            SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: _buildSearchField(),
            ),
          ),
          SliverToBoxAdapter(child: _SectionHeader('Recommendation', action: _seeAllButton(_filteredSorted, title: 'Recommendation'))),
          SliverToBoxAdapter(child: _buildRecommendations()),
          SliverToBoxAdapter(child: _SectionHeader('Trending This Weeks', action: _seeAllButton(_recent, title: 'Trending'))),
          SliverToBoxAdapter(child: _buildTrending()),
          SliverToBoxAdapter(child: _SectionHeader('All Songs', action: IconButton(onPressed: _scrollToTop, icon: const Icon(Icons.arrow_upward, size: 18)) )),
          SliverList.builder(
            itemCount: _withAdsItemCount(),
            itemBuilder: (c,i){
              if(_isAdIndex(i)){
                return _buildAdTile();
              }
              final dataIndex = _dataIndexFor(i);
              final t = _filteredSorted[dataIndex];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(_pickAlbumImage(t.album, seed: t.id.hashCode), width: 44, height: 44, fit: BoxFit.cover),
                ),
                title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                subtitle: Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                onTap: ()=> _playTracks(_filteredSorted, dataIndex),
                onLongPress: ()=> _showTrackMenu(t),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
        ),
      ),
    );
  }

  Widget _buildSearchField(){
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search music or artist',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      ),
      onChanged: (v)=> setState(()=> _filter = v),
    );
  }

  Widget _buildHeader(BuildContext context){
    final hour = DateTime.now().hour;
    final greet = hour<12? 'Pagi' : hour<18? 'Sore' : 'Malam';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
  Text('Hi, wibu', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white, shadows: const [Shadow(blurRadius: 6, color: Colors.black54, offset: Offset(0,2))])),
        const SizedBox(height: 4),
  Text('Selamat $greet – ayo dengarkan musik hari ini 🔥', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
      ],
    );
  }

  Widget _buildRecommendations(){
    final byAlbum = <String, List<Track>>{};
    for(final t in _all){ byAlbum.putIfAbsent(t.album, ()=> []).add(t); }
    final albums = byAlbum.entries.toList();
    albums.sort((a,b)=> b.value.length.compareTo(a.value.length));
    final cards = albums.take(7).toList(); // leave room for ad as first card
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: cards.length + 1, // +1 for ad
        separatorBuilder: (_, __)=> const SizedBox(width: 14),
        itemBuilder: (c,i){
          if(i==0){
            return SizedBox(
              width: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: const NativeInlineAd(padding: EdgeInsets.zero),
              ),
            );
          }
          final e = cards[i-1];
          final img = _pickAlbumImage(e.key, seed: e.key.hashCode + i);
          return GestureDetector(
            onTap: (){ _playTracks(e.value, 0); },
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.35),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(children: [
                Positioned.fill(child: Image.asset(img, fit: BoxFit.cover, color: Colors.black26, colorBlendMode: BlendMode.darken)),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.play_circle_fill, size: 34, color: Theme.of(context).colorScheme.primary),
                      const Spacer(),
                      Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
                      Text('${e.value.length} Lagu', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70, shadows: const [Shadow(blurRadius: 4, color: Colors.black54)])),
                    ],
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrending(){
    final trending = [..._recent];
    if(trending.isEmpty) return const SizedBox(height: 0);
    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: trending.length,
        separatorBuilder: (_, __)=> const SizedBox(width: 14),
        itemBuilder: (c,i){
          final t = trending[i];
          return SizedBox(
            width: 120,
            child: GestureDetector(
              onTap: ()=> _playTracks(trending, i),
              onLongPress: ()=> _showTrackMenu(t),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.asset(_pickAlbumImage(t.album, seed: t.id.hashCode), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
                  Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Playlist strip removed per request; playlist features remain accessible via long-press menu.

  Widget _seeAllButton(List<Track> list, {required String title}){
    return TextButton(onPressed: (){}, child: const Text('See all', style: TextStyle(color: Colors.white70)));
  }

  void _scrollToTop(){
    _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  String _pickAlbumImage(String album, {int? seed}){
    if(_albumPlaceholders.isEmpty) return _artistPlaceholder;
  final base = (seed ?? album.hashCode);
  final h = (base ^ _sessionSalt).abs(); // xor with session salt for new mapping each app launch
  return _albumPlaceholders[h % _albumPlaceholders.length];
  }

  bool _isAdIndex(int listIndex){
    return _adInsertIndex != null && listIndex == _adInsertIndex;
  }

  int _withAdsItemCount(){
    _planAdIfNeeded();
    if(_filteredSorted.isEmpty) return 0;
    if(_adInsertIndex != null) return _filteredSorted.length + 1; // reserve slot even if not loaded
    return _filteredSorted.length;
  }

  int _dataIndexFor(int listIndex){
    if(_isAdIndex(listIndex)) return 0; // unused path
    if(_adInsertIndex != null && listIndex > _adInsertIndex!){
      return listIndex - 1;
    }
    return listIndex;
  }

  void _planAdIfNeeded(){
    if(_filteredSorted.isEmpty) return;
    // Ensure index valid
    if(_adInsertIndex == null || (_adInsertIndex! >= _filteredSorted.length)){
      _adInsertIndex = Random().nextInt(_filteredSorted.length); // 0..len-1
    }
    if(_singleBanner == null && !_adLoading){
      _adLoading = true;
      final ad = BannerAd(
        size: AdSize.banner,
        adUnitId: _bannerAdUnitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad){ if(mounted) setState((){ _singleBanner = ad as BannerAd; _adLoading = false; }); },
          onAdFailedToLoad: (ad, error){ ad.dispose(); if(mounted) setState((){ _adLoading = false; }); },
        ),
      );
      ad.load();
    }
  }

  Widget _buildAdTile(){
    if(_singleBanner == null){
      // placeholder height similar to banner
      return const SizedBox(height: 60);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SizedBox(
        height: _singleBanner!.size.height.toDouble(),
        width: double.infinity,
        child: AdWidget(ad: _singleBanner!),
      ),
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

