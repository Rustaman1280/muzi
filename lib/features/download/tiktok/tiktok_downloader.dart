import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Very lightweight TikTok sound downloader.
/// Strategy:
/// 1. Fetch the TikTok page HTML.
/// 2. Locate JSON data containing music info ("music": { ... , "playUrl": "..." }).
/// 3. Extract playUrl (may be escaped) and download audio bytes.
/// 4. Save to local music folder.
/// NOTE: TikTok frequently changes structure; this is a best-effort simple parser.
class TikTokDownloader {
  static final _musicJsonRegex = RegExp(r'"music":\{(.*?)\}\,', dotAll: true);
  static final _playUrlRegex = RegExp(r'"playUrl":"(.*?)"');
  static final _titleRegex = RegExp(r'"title":"(.*?)"');

  Future<TikTokDownloadResult> fetchAudio(String url, {void Function(int received, int? total)? onProgress}) async {
    final page = await _get(url);
    final musicMatch = _musicJsonRegex.firstMatch(page);
    if (musicMatch == null) {
      throw Exception('Music data not found');
    }
    final musicBlock = musicMatch.group(0)!; // includes music:{...},
    final playMatch = _playUrlRegex.firstMatch(musicBlock);
    if (playMatch == null) {
      throw Exception('playUrl not found');
    }
    var playUrl = playMatch.group(1)!;
    playUrl = playUrl.replaceAll('\\u002F', '/').replaceAll('\\u0026', '&');

    final titleMatch = _titleRegex.firstMatch(musicBlock);
    final rawTitle = titleMatch?.group(1) ?? 'tiktok_audio';
    final title = _sanitize(rawTitle);

    final audioResp = await http.Client().send(http.Request('GET', Uri.parse(playUrl)));
    if (audioResp.statusCode >= 400) {
      throw Exception('Audio fetch failed ${audioResp.statusCode}');
    }
    final directory = await _resolveMusicDir();
    final file = File('${directory.path}/$title.m4a');
    final sink = file.openWrite();
    int received = 0;
    final total = audioResp.contentLength;
    await for (final chunk in audioResp.stream) {
      received += chunk.length;
      sink.add(chunk);
      onProgress?.call(received, total);
    }
    await sink.close();
    return TikTokDownloadResult(file: file, title: title, url: playUrl, size: received);
  }

  Future<Directory> _resolveMusicDir() async {
    // Attempt to use the user's public Downloads folder.
    // path_provider doesn't give Downloads directly on all platforms; we derive it.
    Directory? downloads; 
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, still use app documents to ensure access, but keep a downloads subfolder.
        final base = await getApplicationDocumentsDirectory();
        downloads = Directory('${base.path}/Downloads');
      } else if (Platform.isWindows) {
        final docs = await getDownloadsDirectory(); // Recently added API (may return null)
        downloads = docs ?? Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      } else if (Platform.isMacOS) {
        final home = Platform.environment['HOME'] ?? (await getApplicationDocumentsDirectory()).parent.path;
        downloads = Directory('$home/Downloads');
      } else if (Platform.isLinux) {
        final home = Platform.environment['HOME'] ?? (await getApplicationDocumentsDirectory()).path;
        downloads = Directory('$home/Downloads');
      }
    } catch (_) {
      // Fallback to app documents if anything fails.
    }
    downloads ??= await getApplicationDocumentsDirectory();
    if (!await downloads.exists()) await downloads.create(recursive: true);
    return downloads;
  }

  Future<String> _get(String url) async {
    final resp = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125 Safari/537.36'
    });
    if (resp.statusCode >= 400) throw Exception('Failed page load ${resp.statusCode}');
    return resp.body;
  }

  String _sanitize(String input) => input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}

class TikTokDownloadResult {
  final File file;
  final String title;
  final String url;
  final int size;
  TikTokDownloadResult({required this.file, required this.title, required this.url, required this.size});
}
