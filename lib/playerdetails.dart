import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'playerbrief.dart';

class Nfl {
  final List<Athlete> athletes;

  Nfl({required this.athletes});

  factory Nfl.fromJson(Map<String, dynamic> json) {
    return Nfl(
      athletes: (json['athletes'] as List).map((e) => Athlete.fromJson(e)).toList(),
    );
  }
}

class Athlete {
  final String position;
  final List<Item> items;

  Athlete({required this.position, required this.items});

  factory Athlete.fromJson(Map<String, dynamic> json) {
    return Athlete(
      position: json['position'],
      items: (json['items'] as List).map((e) => Item.fromJson(e)).toList(),
    );
  }
}

class Item {
  final String id;
  final String uid;
  final String guid;
  final AlternateIds alternateIds;
  final String firstName;
  final String lastName;
  final String fullName;
  final String displayName;
  final String shortName;
  final int weight;
  final String displayWeight;
  final int height;
  final String displayHeight;
  final int? age;
  final String? dateOfBirth;
  final List<dynamic> links;
  final BirthPlace birthPlace;
  final College college;
  final String slug;
  final Headshot headshot;
  final String? jersey;
  final Position position;
  final List<Injury> injuries;
  final List<dynamic> contracts;
  final Experience experience;
  final Status status;
  final int? debutYear;
  final Hand? hand;

  Item({
    required this.id,
    required this.uid,
    required this.guid,
    required this.alternateIds,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.displayName,
    required this.shortName,
    required this.weight,
    required this.displayWeight,
    required this.height,
    required this.displayHeight,
    this.age,
    this.dateOfBirth,
    required this.links,
    required this.birthPlace,
    required this.college,
    required this.slug,
    required this.headshot,
    this.jersey,
    required this.position,
    required this.injuries,
    required this.contracts,
    required this.experience,
    required this.status,
    this.debutYear,
    this.hand,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      guid: json['guid'] ?? '',
      alternateIds: AlternateIds(sdr: json['alternateIds']?['sdr'] ?? ''),
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      fullName: json['fullName'] ?? '',
      displayName: json['displayName'] ?? '',
      shortName: json['shortName'] ?? '',
      weight: json['weight'] ?? 0,
      displayWeight: json['displayWeight'] ?? '',
      height: json['height'] ?? 0,
      displayHeight: json['displayHeight'] ?? '',
      age: json['age'],
      dateOfBirth: json['dateOfBirth'],
      links: json['links'] ?? [],
      birthPlace: BirthPlace(
        city: json['birthPlace']?['city'] ?? '',
        state: json['birthPlace']?['state'],
        country: Country.USA,
      ),
      college: College(
        id: json['college']?['id'] ?? '',
        guid: json['college']?['guid'] ?? '',
        mascot: json['college']?['mascot'] ?? '',
        name: json['college']?['name'] ?? '',
        shortName: json['college']?['shortName'] ?? '',
        abbrev: json['college']?['abbrev'] ?? '',
        logos: json['college']?['logos'] ?? [],
      ),
      slug: json['slug'] ?? '',
      headshot: Headshot(
        href: json['headshot']?['href'] ?? '',
        alt: json['headshot']?['alt'] ?? '',
      ),
      jersey: json['jersey'],
      position: Position(
        id: json['position']?['id'] ?? '',
        name: json['position']?['name'] ?? '',
        displayName: json['position']?['displayName'] ?? '',
        abbreviation: json['position']?['abbreviation'] ?? '',
        leaf: json['position']?['leaf'] ?? false,
        parent: null,
      ),
      injuries: (json['injuries'] as List?)?.map((e) => Injury(
        status: e['status'] ?? '',
        date: e['date'] ?? '',
      )).toList() ?? [],
      contracts: json['contracts'] ?? [],
      experience: Experience(years: json['experience']?['years'] ?? 0),
      status: Status(
        id: json['status']?['id'] ?? '',
        name: Abbreviation.ACTIVE,
        type: Type.ACTIVE,
        abbreviation: Abbreviation.ACTIVE,
      ),
      debutYear: json['debutYear'],
      hand: json['hand'] != null
          ? Hand(
              type: json['hand']['type'] ?? '',
              abbreviation: json['hand']['abbreviation'] ?? '',
              displayValue: json['hand']['displayValue'] ?? '',
            )
          : null,
    );
  }
}

class AlternateIds {
  final String sdr;
  AlternateIds({required this.sdr});
}

class BirthPlace {
  final String city;
  final String? state;
  final Country country;
  BirthPlace({required this.city, this.state, required this.country});
}

enum Country { AUSTRIA, CANADA, DENMARK, USA }

class College {
  final String id, guid, mascot, name, shortName, abbrev;
  final List logos;

  College({
    required this.id,
    required this.guid,
    required this.mascot,
    required this.name,
    required this.shortName,
    required this.abbrev,
    required this.logos,
  });
}

class Headshot {
  final String href;
  final String alt;
  Headshot({required this.href, required this.alt});
}

class Injury {
  final String status;
  final String date;
  Injury({required this.status, required this.date});
}

class Experience {
  final int years;
  Experience({required this.years});
}

class Position {
  final String id, name, displayName, abbreviation;
  final bool leaf;
  final Position? parent;

  Position({
    required this.id,
    required this.name,
    required this.displayName,
    required this.abbreviation,
    required this.leaf,
    this.parent,
  });
}

class Status {
  final String id;
  final Abbreviation name;
  final Type type;
  final Abbreviation abbreviation;

  Status({
    required this.id,
    required this.name,
    required this.type,
    required this.abbreviation,
  });
}

class Hand {
  final String type;
  final String abbreviation;
  final String displayValue;

  Hand({
    required this.type,
    required this.abbreviation,
    required this.displayValue,
  });
}

enum Abbreviation { ACTIVE }
enum Type { ACTIVE }

class PlayerDetails extends StatefulWidget {
  final String teamId;
  final bool fixturesLoaded;

  const PlayerDetails({
    Key? key,
    required this.teamId,
    required this.fixturesLoaded,
  }) : super(key: key);

  @override
  State<PlayerDetails> createState() => _PlayerDetailsState();
}

class _PlayerDetailsState extends State<PlayerDetails> with SingleTickerProviderStateMixin {
  late Future<List<Item>> _playersFuture;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    if (widget.fixturesLoaded) {
      _playersFuture = fetchPlayers();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });

      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 10),
      )..repeat();

      _animationController.addListener(() {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          final offset = _scrollController.offset - 1.5;
          if (offset <= 0) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          } else {
            _scrollController.jumpTo(offset);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.fixturesLoaded) {
      _animationController.dispose();
      _scrollController.dispose();
    }
    super.dispose();
  }

  Future<List<Item>> fetchPlayers() async {
    final url = 'http://20.115.89.23/playerdetails${widget.teamId}.json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final nfl = Nfl.fromJson(data);
      return nfl.athletes.expand((athlete) => athlete.items).toList();
    } else {
      throw Exception('Failed to load players');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    if (!widget.fixturesLoaded) return const SizedBox.shrink();

    return FutureBuilder<List<Item>>(
      future: _playersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 130,
            child: Center(
              child: Text(
                'Player list available soon you can click and see details',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            height: 130,
            child: Center(
              child: Text('Error loading players', style: TextStyle(color: textColor)),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 130,
            child: Center(
              child: Text('No players found', style: TextStyle(color: textColor)),
            ),
          );
        }

        final players = snapshot.data!;
        return SizedBox(
          height: 130,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerBrief(player: player),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(player.headshot.href),
                        backgroundColor: theme.cardColor,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 80,
                        child: Text(
                          player.fullName,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: textColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
