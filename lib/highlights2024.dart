import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marquee/marquee.dart';
import 'package:webview_flutter/webview_flutter.dart'; // ✅ Use WebView
import 'Admob/interstitial_ads.dart';

class Highlight2024 {
  final String matchId;
  final String videoUrl;
  final String thumbnailUrl;

  Highlight2024({
    required this.matchId,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  factory Highlight2024.fromJson(Map<String, dynamic> json) {
    return Highlight2024(
      matchId: json['match_id'],
      videoUrl: json['video_url'],
      thumbnailUrl: json['thumbnail_url'],
    );
  }
}

class Highlights2024Page extends StatefulWidget {
  @override
  _Highlights2024PageState createState() => _Highlights2024PageState();
}

class _Highlights2024PageState extends State<Highlights2024Page> {
  late Future<List<Highlight2024>> highlights2024;

  @override
  void initState() {
    super.initState();
    highlights2024 = loadHighlights2024();
    InterstitialAdManager.initialize();
  }

  Future<List<Highlight2024>> loadHighlights2024() async {
    final response =
        await http.get(Uri.parse('http://20.115.89.23/highlights2024.json'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Highlight2024.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load highlights 2024');
    }
  }

  void _handleHighlightTap(Highlight2024 highlight) {
    InterstitialAdManager.showInterstitialAd(onAdDismissed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(videoUrl: highlight.videoUrl),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.background;
    final textColor = theme.colorScheme.onBackground;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: SizedBox(
          height: 30,
          child: Marquee(
            text: "Highlights 2024",
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            scrollAxis: Axis.horizontal,
            blankSpace: 50.0,
            velocity: 30.0,
            startPadding: 5.0,
            accelerationDuration: const Duration(seconds: 1),
            decelerationDuration: const Duration(milliseconds: 500),
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: FutureBuilder<List<Highlight2024>>(
        future: highlights2024,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.red));
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
                'No highlights 2024 available.',
                style: TextStyle(color: textColor),
              ),
            );
          }

          final highlights = snapshot.data!;
          return ListView.builder(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
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

/// ✅ Fixed Video Player using WebView
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.videoUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Player")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
