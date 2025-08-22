import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'playerdetails.dart';

class FixturesScreen extends StatefulWidget {
  final String teamId;

  const FixturesScreen({Key? key, required this.teamId}) : super(key: key);

  @override
  _FixturesScreenState createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  List<dynamic> fixtures = [];
  bool isLoading = true;
  Timer? _timer;
  Map<int, DateTime?> liveMatches = {};

  @override
  void initState() {
    super.initState();
    fetchFixtures(widget.teamId);
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchFixtures(String teamId) async {
    final response = await http.get(Uri.parse('http://20.115.89.23/fixtures$teamId.json'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        fixtures = data['events'] as List;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => checkLiveMatches());
    });
  }

  void checkLiveMatches() {
    final now = DateTime.now();
    for (int i = 0; i < fixtures.length; i++) {
      final matchTime = DateTime.tryParse(fixtures[i]['date'] ?? '')?.toLocal() ?? now;
      if (liveMatches[i] == null &&
          now.isAfter(matchTime) &&
          now.isBefore(matchTime.add(const Duration(hours: 2)))) {
        liveMatches[i] = matchTime.add(const Duration(hours: 2));
      } else if (liveMatches[i] != null && now.isAfter(liveMatches[i]!)) {
        liveMatches.remove(i);
      }
    }
  }

  Map<String, String> formatDateTimeToLocal(String dateTime) {
    try {
      final local = DateTime.parse(dateTime).toLocal();
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      String date;

      if (local.year == now.year && local.month == now.month && local.day == now.day) {
        date = 'Today';
      } else if (local.year == tomorrow.year && local.month == tomorrow.month && local.day == tomorrow.day) {
        date = 'Tomorrow';
      } else {
        date = DateFormat('MMM d, yyyy').format(local);
      }

      return {
        'date': date,
        'dayTime': DateFormat('EEEE, h:mm a').format(local),
      };
    } catch (_) {
      return {'date': 'Invalid date', 'dayTime': ''};
    }
  }

  Map<String, int> calculateRemainingTime(String dateTime) {
    try {
      final match = DateTime.parse(dateTime).toLocal();
      final diff = match.difference(DateTime.now());
      if (diff.isNegative) return {'days': 0, 'hours': 0, 'minutes': 0, 'seconds': 0};
      return {
        'days': diff.inDays,
        'hours': diff.inHours % 24,
        'minutes': diff.inMinutes % 60,
        'seconds': diff.inSeconds % 60,
      };
    } catch (_) {
      return {'days': 0, 'hours': 0, 'minutes': 0, 'seconds': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.background;
    final text = theme.colorScheme.onBackground;
    final card = theme.cardColor;

    return Scaffold(
      backgroundColor: bg,
      body: isLoading
          ? const Center(child: RotatingFootballWithText())
          : Column(
              children: [
                SizedBox(
                  height: 120,
                  child: PlayerDetails(teamId: widget.teamId, fixturesLoaded: true),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: fixtures.length,
                    itemBuilder: (context, index) {
                      final fixture = fixtures[index];
                      final comps = fixture['competitions'] ?? [];
                      final competitors = comps.isNotEmpty ? comps[0]['competitors'] ?? [] : [];
                      final home = competitors.firstWhere(
                        (c) => c['homeAway'] == 'home',
                        orElse: () => {'team': {'nickname': 'Unknown', 'logos': [{'href': ''}]}},
                      );
                      final away = competitors.firstWhere(
                        (c) => c['homeAway'] == 'away',
                        orElse: () => {'team': {'nickname': 'Unknown', 'logos': [{'href': ''}]}},
                      );
                      final dt = formatDateTimeToLocal(fixture['date'] ?? '');
                      final rem = calculateRemainingTime(fixture['date'] ?? '');
                      final live = liveMatches.containsKey(index);

                      return Card(
                        color: card,
                        margin: const EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  teamColumn(home, text),
                                  Column(
                                    children: [
                                      const Text(
                                        "VS",
                                        style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                      Text(dt['date']!, style: TextStyle(color: text)),
                                      Text(dt['dayTime']!, style: TextStyle(color: text.withOpacity(0.7))),
                                    ],
                                  ),
                                  teamColumn(away, text),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (!live) ...[
                                Text("Match Starts In...", style: TextStyle(color: Colors.red, fontSize: 14)),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    timeBox(rem['days']!, 'Days', text, card),
                                    timeBox(rem['hours']!, 'Hours', text, card),
                                    timeBox(rem['minutes']!, 'Minutes', text, card),
                                    timeBox(rem['seconds']!, 'Seconds', text, card),
                                  ],
                                ),
                              ],
                              if (live)
                                Text("MATCH IS LIVE", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget teamColumn(Map<String, dynamic> team, Color text) {
    final logo = team['team']['logos'][0]['href'] ?? '';
    final name = team['team']['nickname'] ?? 'Unknown';
    return Column(
      children: [
        Image.network(
          logo,
          width: 50,
          height: 50,
          errorBuilder: (ctx, e, st) => Icon(Icons.broken_image, size: 50, color: text),
        ),
        const SizedBox(height: 5),
        Text(name, style: TextStyle(color: text)),
      ],
    );
  }

  Widget timeBox(int value, String label, Color text, Color box) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: box,
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value.toString().padLeft(2, '0'), style: TextStyle(color: text, fontSize: 18)),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: text.withOpacity(0.7))),
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
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
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
        const Text("Please wait...", style: TextStyle(color: Colors.red, fontSize: 16)),
      ],
    );
  }
}
