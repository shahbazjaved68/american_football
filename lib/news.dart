import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:marquee/marquee.dart';
import 'Admob/interstitial_ads.dart'; // ✅ Import ads manager

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool isConnected = true;
  List<Article> articles = [];

  @override
  void initState() {
    super.initState();
    checkInternetAndFetchNews();

    /// ✅ Preload interstitial ad once screen is opened
    InterstitialAdManager.initialize();
  }

  Future<void> checkInternetAndFetchNews() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isConnected = false;
        isLoading = false;
      });
    } else {
      setState(() {
        isConnected = true;
      });
      fetchNews();
    }
  }

  Future<void> fetchNews() async {
    const String apiUrl = "http://20.115.89.23/news.php";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          articles = (data['articles'] as List)
              .map((json) => Article.fromJson(json))
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load news");
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        isConnected = false;
      });
    }
  }

  void _handleNewsTap(Article article) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailsScreen(article: article),
      ),
    );

    /// ✅ After returning from details, show interstitial ad
    InterstitialAdManager.showInterstitialAd();
  }

  @override
  void dispose() {
    InterstitialAdManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final text = theme.textTheme;

    return Scaffold(
      backgroundColor: color.background,
      body: isLoading
          ? const Center(child: RotatingFootballWithText())
          : !isConnected
              ? Center(
                  child: Text(
                    "Please connect to the internet",
                    style: text.bodyLarge?.copyWith(color: Colors.red),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      height: 30,
                      color: color.background,
                      child: Marquee(
                        text: 'Latest News of NFL',
                        style: TextStyle(
                          color: color.onBackground,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        scrollAxis: Axis.horizontal,
                        blankSpace: 20.0,
                        velocity: 35.0,
                        pauseAfterRound: const Duration(seconds: 2),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          itemCount: articles.length,
                          itemBuilder: (context, index) {
                            final article = articles[index];
                            return GestureDetector(
                              onTap: () => _handleNewsTap(article),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Card(
                                  color: theme.cardColor,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (article.images.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(12)),
                                          child: Image.network(
                                            article.images.first.url,
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              article.headline,
                                              style: text.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: color.onBackground,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "By ${article.byline}",
                                              style: text.bodySmall?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: color.onBackground.withOpacity(0.7),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              article.description,
                                              style: text.bodyMedium?.copyWith(
                                                color: color.onBackground.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class RotatingFootballWithText extends StatefulWidget {
  const RotatingFootballWithText({Key? key}) : super(key: key);

  @override
  _RotatingFootballWithTextState createState() => _RotatingFootballWithTextState();
}

class _RotatingFootballWithTextState extends State<RotatingFootballWithText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
      children: [
        RotationTransition(
          turns: _controller,
          child: const Icon(Icons.sports_football, size: 50, color: Colors.red),
        ),
        const SizedBox(height: 16),
        const Text(
          "Please wait...",
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      ],
    );
  }
}

class Article {
  final String headline;
  final String description;
  final List<ArticleImage> images;
  final DateTime published;
  final String byline;
  final String url;

  Article({
    required this.headline,
    required this.description,
    required this.images,
    required this.published,
    required this.byline,
    required this.url,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      headline: json['headline'] ?? '',
      description: json['description'] ?? '',
      images: (json['images'] as List)
          .map((imageJson) => ArticleImage.fromJson(imageJson))
          .toList(),
      published: DateTime.parse(json['published']),
      byline: json['byline'] ?? 'Unknown',
      url: json['link']?['href'] ?? '',
    );
  }
}

class ArticleImage {
  final String url;

  ArticleImage({required this.url});

  factory ArticleImage.fromJson(Map<String, dynamic> json) {
    return ArticleImage(url: json['url'] ?? '');
  }
}

class NewsDetailsScreen extends StatelessWidget {
  final Article article;

  const NewsDetailsScreen({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color.background,
        iconTheme: IconThemeData(color: color.primary),
      ),
      backgroundColor: color.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.images.isNotEmpty)
              Image.network(
                article.images.first.url,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.headline,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("By ${article.byline}",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: color.onBackground.withOpacity(0.7),
                      )),
                  const SizedBox(height: 8),
                  Text("Published: ${article.published.toLocal()}".split(' ')[0],
                      style: TextStyle(color: color.onBackground.withOpacity(0.7))),
                  const SizedBox(height: 16),
                  Text(article.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: color.onBackground.withOpacity(0.8),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
