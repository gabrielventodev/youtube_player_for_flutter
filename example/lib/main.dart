import 'package:flutter/material.dart';
import 'package:youtube_player_for_flutter/youtube_player_for_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Player Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.red,
        useMaterial3: true,
      ),
      home: const PlayerScreen(),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final YoutubePlayerController _controller;
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      videoId: 'B1y7jC9xlD0',
      autoPlay: false,
      showControls: true,
    );
    _controller.addListener(_onPlayerValueChanged);
  }

  void _onPlayerValueChanged() {
    if (mounted) setState(() {});
  }

  static String? extractVideoId(String url) {
    final patterns = [
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com.*[?&]v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'^([a-zA-Z0-9_-]{11})$'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url.trim());
      if (match != null) return match.group(1);
    }
    return null;
  }

  void _loadFromUrl() {
    final videoId = extractVideoId(_urlController.text);
    if (videoId != null) {
      _controller.loadVideo(videoId);
      _urlController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _controller.removeListener(_onPlayerValueChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerValue = _controller.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Player Demo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
          // Player
          YoutubePlayerWidget(controller: _controller),

          const SizedBox(height: 12),

          // URL input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'Pega un link de YouTube...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _loadFromUrl(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loadFromUrl,
                  child: const Text('Cargar'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado del reproductor',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Ready: ${playerValue.isReady}'),
                    Text('State: ${playerValue.playerState.name}'),
                    Text('Quality: ${playerValue.playbackQuality.name}'),
                    Text('Fullscreen: ${playerValue.isFullscreen}'),
                    Text('Short: ${playerValue.isShort}'),
                    if (playerValue.error != YoutubeError.none)
                      Text(
                        'Error: ${playerValue.error.name}',
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _controller.play,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                ),
                FilledButton.icon(
                  onPressed: _controller.pause,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _controller.seekTo(const Duration(seconds: 30)),
                  icon: const Icon(Icons.forward_30),
                  label: const Text('Seek 30s'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _controller.loadVideo('jNQXAC9IVRw'),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Load otro video'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quality selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Calidad:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(width: 12),
                DropdownButton<PlaybackQuality>(
                  value: playerValue.playbackQuality,
                  onChanged: (quality) {
                    if (quality != null) {
                      _controller.setPlaybackQuality(quality);
                    }
                  },
                  items: PlaybackQuality.values
                      .map(
                        (q) => DropdownMenuItem(
                          value: q,
                          child: Text(q.name),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
