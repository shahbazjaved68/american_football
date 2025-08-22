import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'heighlights.dart';
import 'Admob/interstitial_ads.dart'; // ✅ Import interstitial ads manager

class Score extends StatefulWidget {
  // ✅ Static flag so main.dart can check
  static bool hasLiveScores = false;

  @override
  _ScoreState createState() => _ScoreState();
}

class _ScoreState extends State<Score> with SingleTickerProviderStateMixin {
  List<Live> liveGames = [];
  Timer? apiRefreshTimer;
  Timer? adTimer; // ✅ Timer for showing ads
  bool isLoading = true;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    fetchLiveScores(isUserAction: true);
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();

    _setupPeriodicRefresh();

    // ✅ Initialize interstitial ads
    InterstitialAdManager.initialize();

    // ✅ Setup ad timer (every 3 minutes)
    adTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        InterstitialAdManager.showInterstitialAd();
      }
    });
  }

  Future<void> fetchLiveScores({bool isUserAction = false}) async {
    if (isUserAction) setState(() => isLoading = true);

    const String apiUrl = 'http://20.115.89.23/livescores.php';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200 && mounted) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('live') && data['live'] is List && data['live'].isNotEmpty) {
          final List<dynamic> liveGamesData = data['live'];
          setState(() {
            liveGames = liveGamesData.map((game) => Live.fromJson(game)).toList();
            Score.hasLiveScores = true; // ✅ Mark as live scores available
          });
        } else {
          setState(() {
            liveGames = [];
            Score.hasLiveScores = false; // ✅ No live scores
          });
        }
      } else {
        setState(() {
          liveGames = [];
          Score.hasLiveScores = false;
        });
        print('Failed to fetch live scores: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        liveGames = [];
        Score.hasLiveScores = false;
      });
      print('Error fetching live scores: $e');
    } finally {
      if (isUserAction) setState(() => isLoading = false);
    }
  }

  void _setupPeriodicRefresh() {
    apiRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) fetchLiveScores();
    });
  }

  @override
  void dispose() {
    apiRefreshTimer?.cancel();
    adTimer?.cancel(); // ✅ Cancel ad timer
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.background;
    final textColor = theme.colorScheme.onBackground;
    final cardColor = theme.cardColor;

    if (isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: _rotationController,
                child: const Icon(Icons.sports_football, size: 50, color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please wait...',
                style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (liveGames.isEmpty) return HighlightsPage();

    return Scaffold(
      backgroundColor: bgColor,
      body: ListView.builder(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.only(
          top: 12,
          bottom: kBottomNavigationBarHeight + 80,
          left: 12,
          right: 12,
        ),
        itemCount: liveGames.length + 1,
        itemBuilder: (context, index) {
          if (index == liveGames.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HighlightsPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Go to Highlights',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }

          final game = liveGames[index];
          final homeTeam = game.homeCompetitor;
          final awayTeam = game.awayCompetitor;

          return Card(
            color: cardColor,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          homeTeam.shortName,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          awayTeam.shortName,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${homeTeam.score} - ${awayTeam.score}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    game.status,
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class Competitor {
  final String shortName;
  final int score;

  Competitor({
    required this.shortName,
    required this.score,
  });

  factory Competitor.fromJson(Map<String, dynamic> json) {
    return Competitor(
      shortName: json['shortName'] ?? 'Unknown',
      score: json['score'] ?? 0,
    );
  }
}

class Live {
  final Competitor homeCompetitor;
  final Competitor awayCompetitor;
  final String status;

  Live({
    required this.homeCompetitor,
    required this.awayCompetitor,
    required this.status,
  });

  factory Live.fromJson(Map<String, dynamic> json) {
    return Live(
      homeCompetitor: Competitor.fromJson(json['homeCompetitor'] ?? {}),
      awayCompetitor: Competitor.fromJson(json['awayCompetitor'] ?? {}),
      status: json['statusText'] ?? 'Unknown',
    );
  }
}
