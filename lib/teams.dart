import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Admob/interstitial_ads.dart';
import 'waiting_logo.dart';

class TeamsScreen extends StatefulWidget {
  final Function(Map<String, String>)? onTeamSelected;

  const TeamsScreen({Key? key, this.onTeamSelected}) : super(key: key);

  @override
  _TeamsScreenState createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  List<dynamic> teams = [];

  @override
  void initState() {
    super.initState();
    InterstitialAdManager.initialize();
    loadTeamsJson();
  }

  Future<void> loadTeamsJson() async {
    try {
      final response =
          await http.get(Uri.parse('http://20.115.89.23/teams.json'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          teams = jsonData ?? [];
        });
      } else {
        print("Failed to load teams: ${response.statusCode}");
      }
    } catch (e) {
      print("Error loading teams: $e");
    }
  }

  void _handleTeamTap(String teamId, String displayName) {
    InterstitialAdManager.showInterstitialAd(onAdDismissed: () {
      widget.onTeamSelected?.call({'id': teamId, 'name': displayName});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.background;
    final textColor = theme.colorScheme.onBackground;
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: teams.isEmpty
          ? const Center(child: RotatingFootballWithText())
          : ListView.builder(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.only(
                top: 12,
                left: 12,
                right: 12,
                bottom: kBottomNavigationBarHeight + 12, // ✅ Fix overlap
              ),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                final teamId = team['id'].toString();
                final displayName = team['displayName'] ?? 'Unknown Team';
                final location = team['location'] ?? 'Unknown Location';
                final logoUrl = team['logoUrl'] ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Material(
                    color: cardColor, // ✅ Dynamic card color based on theme
                    borderRadius: BorderRadius.circular(16),
                    elevation: 4,
                    shadowColor: Colors.black54,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _handleTeamTap(teamId, displayName),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: logoUrl.isNotEmpty
                                  ? NetworkImage(logoUrl)
                                  : null,
                              child: logoUrl.isEmpty
                                  ? Icon(Icons.sports,
                                      color: Colors.red.shade400)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 16, color: Colors.redAccent),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          location,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                textColor.withOpacity(0.7),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                color: Colors.redAccent, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

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
      children: [
        RotationTransition(
          turns: _controller,
          child: const Icon(Icons.sports_football,
              size: 50, color: Colors.red),
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
