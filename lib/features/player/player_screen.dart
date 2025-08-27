import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/providers/app_providers.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String title;
  final String artist;
  final ImageProvider artwork;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final VoidCallback? onFavorite;
  final VoidCallback? onMenu;
  final bool isFavorite;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.artwork,
    required this.duration,
    required this.position,
    required this.isPlaying,
    this.onPlayPause,
    this.onNext,
    this.onPrev,
    this.onFavorite,
    this.onMenu,
    this.isFavorite = false,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> with SingleTickerProviderStateMixin {
  Color _top = const Color(0xFF0E121B);
  Color _accent = const Color(0xFF1E2533);
  List<Color> _gradientColors = const [Color(0xFF000000), Color(0xFF101317)];
  double? _temporarySeek; // while user drags slider

  @override
  void initState() {
    super.initState();
    _extract();
  }

  @override
  void didUpdateWidget(covariant PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artwork != widget.artwork) {
      _extract();
    }
  }

  Future<void> _extract() async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        widget.artwork,
        size: const Size(300, 300),
        maximumColorCount: 16,
      );
  final dominant = palette.dominantColor?.color ?? _top;
  final vibrant = palette.vibrantColor?.color ?? dominant;
  // Accent keeps original hue; top/bottom will be mostly black
  _accent = vibrant;
  // Slightly shift for a soft tint (not too bright)
  Color a = _shift(dominant, -0.15);
      // Collect candidate colors
      final candidates = <Color>{
        dominant,
        vibrant,
        if(palette.darkVibrantColor!=null) palette.darkVibrantColor!.color,
        if(palette.lightVibrantColor!=null) palette.lightVibrantColor!.color,
        if(palette.mutedColor!=null) palette.mutedColor!.color,
        if(palette.darkMutedColor!=null) palette.darkMutedColor!.color,
        if(palette.lightMutedColor!=null) palette.lightMutedColor!.color,
      }.toList();
      // Helper to mix with black so it doesn't overpower UI
      Color tone(Color c, double strength){
        return Color.lerp(Colors.black, c, strength)!.withOpacity(1);
      }
      final picked = <Color>[];
      for(final c in candidates){
        if(picked.length>=4) break;
        if(picked.every((p)=> (p.value - c.value).abs() > 0x202020)){
          // choose different enough
          picked.add(c);
        }
      }
      if(picked.isEmpty){
        picked.add(dominant);
      }
      // Map to gradient stops (dark -> mid -> accent -> deep)
      final mapped = <Color>[];
      for(int i=0;i<picked.length;i++){
        final strength = 0.35 + (i / (picked.length-1).clamp(1, 999))*0.45; // 0.35..0.8
        mapped.add(tone(picked[i], strength));
      }
      // Ensure start & end are very dark to frame content
      final gradientList = <Color>[Colors.black, ...mapped, Colors.black];
      setState(() {
        _top = a;
        _gradientColors = gradientList;
      });
    } catch (_) {
      // ignore extraction failure
    }
  }

  Color _shift(Color c, double amount){
    final hsl = HSLColor.fromColor(c);
    final l = (hsl.lightness + amount).clamp(0.05, 0.9);
    return hsl.withLightness(l.toDouble()).toColor();
  }

  double _progress(Duration position, Duration duration){
    if(duration.inMilliseconds==0) return 0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioControllerProvider);
    final controller = ref.read(audioControllerProvider.notifier);
    final isPlaying = audioState.playing;
    final duration = audioState.duration ?? widget.duration;
    final position = _temporarySeek != null && duration.inMilliseconds>0
        ? Duration(milliseconds: (_temporarySeek! * duration.inMilliseconds).round())
        : audioState.position;
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _gradientColors,
        ),
      ),
      child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _buildTopBar(theme),
                  const SizedBox(height: 32),
                  _buildArtwork(),
                  const SizedBox(height: 36),
                  _buildTitle(theme, audioState.current?.title ?? widget.title),
                  const SizedBox(height: 8),
                  _buildArtist(theme, audioState.current?.artist ?? widget.artist),
                  const Spacer(),
                  _buildSlider(theme, position, duration, onSeek: (d)=> controller.seek(d)),
                  const SizedBox(height: 20),
                  _buildControls(theme, isPlaying: isPlaying, onPlayPause: () async {
                    if(isPlaying){
                      await controller.pause();
                    } else {
                      await controller.play();
                    }
                  }, onNext: controller.next, onPrev: controller.previous),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTopBar(ThemeData theme){
    return Row(
      children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white)),
        const SizedBox(width: 4),
        Expanded(child: Text('Now Playing', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70, letterSpacing: .5))),
        IconButton(onPressed: widget.onFavorite, icon: Icon(widget.isFavorite? Icons.favorite: Icons.favorite_border, color: widget.isFavorite? Colors.pinkAccent : Colors.white70)),
        IconButton(onPressed: widget.onMenu, icon: const Icon(Icons.more_vert, color: Colors.white70)),
      ],
    );
  }

  Widget _buildArtwork(){
    return Hero(
      tag: widget.artwork,
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(.5),
              blurRadius: 55,
              spreadRadius: -8,
              offset: const Offset(0, 30),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image(image: widget.artwork, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, String title){
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [Shadow(blurRadius: 12, color: Colors.black54)],
      ),
    );
  }

  Widget _buildArtist(ThemeData theme, String artist){
    return Text(
      artist,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: Colors.white70,
        letterSpacing: .3,
      ),
    );
  }

  Widget _buildSlider(ThemeData theme, Duration position, Duration duration, {required void Function(Duration) onSeek}){
    String fmt(Duration d){
      final m = d.inMinutes.remainder(60).toString().padLeft(2,'0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2,'0');
      return '$m:$s';
    }
    final remaining = duration - position;
    final prog = _progress(position, duration).clamp(0.0, 1.0);
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            inactiveTrackColor: Colors.white24,
            activeTrackColor: Colors.white,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: prog.isNaN? 0: prog,
            onChanged: duration.inMilliseconds==0 ? null : (v){
              setState(()=> _temporarySeek = v); // show immediate feedback
            },
            onChangeEnd: duration.inMilliseconds==0 ? null : (v){
              setState(()=> _temporarySeek = null);
              final target = Duration(milliseconds: (v * duration.inMilliseconds).round());
              onSeek(target);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              Text(fmt(position), style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
              const Spacer(),
              Text('-${fmt(remaining)}', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(ThemeData theme, {required bool isPlaying, required VoidCallback onPlayPause, required Future<void> Function() onNext, required Future<void> Function() onPrev}){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 30,
          color: Colors.white70,
          onPressed: (){ onPrev(); },
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(.92),
                  Colors.white.withOpacity(.75),
                ],
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 30, offset: const Offset(0,20)),
              ],
            ),
            child: Icon(isPlaying? Icons.pause_rounded : Icons.play_arrow_rounded, size: 48, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          iconSize: 30,
          color: Colors.white70,
          onPressed: (){ onNext(); },
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }
}
