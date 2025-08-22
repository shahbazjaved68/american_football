import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ScoreboardScreen extends StatefulWidget {
  @override
  _ScoreboardScreenState createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  List<Body> games = [];
  bool isLoading = true;
  bool isConnected = true;
  late int currentWeek;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    currentWeek = 1;
    checkInitialConnection();
    fetchGames();
    _scrollController = ScrollController();
    monitorConnectivity();
  }

  Future<void> checkInitialConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  void monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        isConnected = result != ConnectivityResult.none;
      });
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please connect to the internet.",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchGames() async {
    if (!isConnected) return;

    final String url = 'http://20.115.89.23/currentweekfixtures.json';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weekKey = 'week_$currentWeek';

        if (data.containsKey(weekKey) && data[weekKey]['statusCode'] == 200) {
          final List<dynamic> bodyList = data[weekKey]['body'];

          setState(() {
            games = bodyList
                .map((game) => Body.fromJson(game))
                .where((game) => game.home.isNotEmpty && game.away.isNotEmpty)
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            games = [];
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load games');
      }
    } catch (e) {
      setState(() {
        games = [];
        isLoading = false;
      });
    }
  }

  String convertToLocalTime(double gameTimeEpoch, String gameDate) {
    if (gameTimeEpoch == 0.0) {
      try {
        final parsedDate = DateTime.parse(gameDate);
        final formattedDate = DateFormat('MMM dd, yyyy').format(parsedDate);
        return '$formattedDate - Time TBD';
      } catch (e) {
        return 'Date TBD';
      }
    }

    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(
        (gameTimeEpoch * 1000).toInt(),
        isUtc: true,
      );
      final localDateTime = dateTime.toLocal();
      final formattedDate = DateFormat('MMM dd, yyyy').format(localDateTime);
      final formattedTime = DateFormat('hh:mm a').format(localDateTime);
      return '$formattedDate - $formattedTime';
    } catch (e) {
      return 'Invalid Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.background;
    final textColor = theme.colorScheme.onBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Select Week',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                Slider(
                  value: currentWeek.toDouble(),
                  min: 1,
                  max: 18,
                  divisions: 17,
                  label: 'Week $currentWeek',
                  onChanged: (value) {
                    setState(() {
                      currentWeek = value.toInt();
                      isLoading = true;
                    });
                    fetchGames();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (!isConnected)
                  Center(
                    child: Text(
                      "Please connect to the internet.",
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                if (isLoading && isConnected)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RotatingFootballIcon(),
                        const SizedBox(height: 16),
                        const Text(
                          "Please wait...",
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (!isLoading && isConnected)
                  games.isEmpty
                      ? Center(
                          child: Text(
                            'No games available',
                            style: TextStyle(fontSize: 18, color: textColor.withOpacity(0.6)),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight + 12),
                          itemCount: games.length,
                          itemBuilder: (context, index) {
                            final game = games[index];
                            final adjustedDateTime =
                                convertToLocalTime(game.gameTimeEpoch, game.gameDate);

                            return GameCard(
                              game: game,
                              currentWeek: currentWeek,
                              adjustedDateTime: adjustedDateTime,
                            );
                          },
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final Body game;
  final int currentWeek;
  final String adjustedDateTime;

  const GameCard({
    required this.game,
    required this.currentWeek,
    required this.adjustedDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final cardColor = Theme.of(context).cardColor;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 6,
      color: cardColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                'Week $currentWeek',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  '${game.home} vs ${game.away}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  adjustedDateTime,
                  style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        if (game.espnLink.isNotEmpty) {
                          launchUrl(Uri.parse(game.espnLink));
                        }
                      },
                      icon: const Icon(Icons.tv, color: Colors.red),
                      label: Text('ESPN', style: TextStyle(color: textColor)),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        if (game.cbsLink.isNotEmpty) {
                          launchUrl(Uri.parse(game.cbsLink));
                        }
                      },
                      icon: const Icon(Icons.tv, color: Colors.blue),
                      label: Text('CBS', style: TextStyle(color: textColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RotatingFootballIcon extends StatefulWidget {
  @override
  _RotatingFootballIconState createState() => _RotatingFootballIconState();
}

class _RotatingFootballIconState extends State<RotatingFootballIcon>
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
    return RotationTransition(
      turns: _controller,
      child: const Icon(Icons.sports_football, color: Colors.red, size: 50),
    );
  }
}

class Body {
  final String gameId;
  final String away;
  final String gameDate;
  final String home;
  final double gameTimeEpoch;
  final String espnLink;
  final String cbsLink;

  Body({
    required this.gameId,
    required this.away,
    required this.gameDate,
    required this.home,
    required this.gameTimeEpoch,
    required this.espnLink,
    required this.cbsLink,
  });

  factory Body.fromJson(Map<String, dynamic> json) {
    return Body(
      gameId: json['gameID'] ?? '',
      away: json['away'] ?? '',
      gameDate: json['gameDate'] ?? '',
      home: json['home'] ?? '',
      gameTimeEpoch: double.tryParse(json['gameTime_epoch']?.toString() ?? '0') ?? 0.0,
      espnLink: json['espnLink'] ?? '',
      cbsLink: json['cbsLink'] ?? '',
    );
  }
}
