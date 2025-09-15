import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'Admob/interstitial_ads.dart';

class Highlight {
  final String videoUrl;
  final String thumbnailUrl;

  Highlight({
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      videoUrl: json['video_url'],
      thumbnailUrl: json['thumbnail_url'],
    );
  }
}

class HighlightsPage extends StatefulWidget {
  @override
  _HighlightsPageState createState() => _HighlightsPageState();
}

class _HighlightsPageState extends State<HighlightsPage> {
  late Future<List<Highlight>> highlights;

  @override
  void initState() {
    super.initState();
    highlights = loadHighlights();
    InterstitialAdManager.initialize();
  }

  Future<List<Highlight>> loadHighlights() async {
    final response =
        await http.get(Uri.parse('http://20.115.89.23/highlights2025.json'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Highlight.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load highlights');
    }
  }

  /// ✅ Proper two-step interstitial ads before playing video
  void _handleHighlightTap(Highlight highlight) {
    InterstitialAdManager.showInterstitialAd(onAdDismissed: () {
      // After first ad, show second ad
      InterstitialAdManager.showInterstitialAd(onAdDismissed: () {
        // After second ad, open video
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(videoUrl: highlight.videoUrl),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.background;
    final textColor = theme.colorScheme.onBackground;

    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<List<Highlight>>(
        future: highlights,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFootballWithText());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No highlights available.',
                style: TextStyle(color: textColor),
              ),
            );
          }

          final highlights = snapshot.data!;
          return ListView.builder(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()), // ✅ Smooth scrolling
            itemCount: highlights.length,
            itemBuilder: (context, index) {
              final highlight = highlights[index];
              return GestureDetector(
                onTap: () => _handleHighlightTap(highlight),
                child: Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.all(8.0),
                  child: Image.network(
                    highlight.thumbnailUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// ✅ Video Player using Improved WebView
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint("WebView error: $error");
          },
        ),
      )
      ..clearCache()
      ..loadRequest(Uri.parse(widget.videoUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(), // ✅ Only back button
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
        ],
      ),
    );
  }
}

/// ✅ Loader Animation
class RotatingFootballWithText extends StatefulWidget {
  const RotatingFootballWithText({Key? key}) : super(key: key);

  @override
  _RotatingFootballWithTextState createState() =>
      _RotatingFootballWithTextState();
}

class _RotatingFootballWithTextState extends State<RotatingFootballWithText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        RotationTransition(
          turns: AlwaysStoppedAnimation(1.0),
          child: Icon(Icons.sports_football, size: 50, color: Colors.red),
        ),
        SizedBox(height: 16),
        Text(
          "Please wait...",
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      ],
    );
  }
}
