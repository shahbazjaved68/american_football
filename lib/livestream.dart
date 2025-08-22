import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({Key? key}) : super(key: key);

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  late Future<List<Datum>> futureStreams;

  @override
  void initState() {
    super.initState();
    futureStreams = fetchLiveStreams();
  }

  Future<List<Datum>> fetchLiveStreams() async {
    try {
      final response =
          await http.get(Uri.parse('http://20.115.89.23/livestream.php'));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        // ✅ Backend wraps inside [ { "data": [...] } ]
        if (body is List && body.isNotEmpty && body.first["data"] != null) {
          return (body.first["data"] as List)
              .map((e) => Datum.fromJson(e))
              .toList();
        } else {
          return []; // no valid data
        }
      } else {
        return [];
      }
    } catch (e) {
      return []; // network or parsing error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Datum>>(
        future: futureStreams,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // ✅ Show this if error OR no data
            return const Center(
              child: Text(
                "Live Streaming available soon",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            );
          }

          final streams = snapshot.data!;

          return ListView.builder(
            itemCount: streams.length,
            itemBuilder: (context, index) {
              final stream = streams[index];
              return Card(
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.live_tv, color: Colors.red),
                  title: Text(
                    "${stream.teamOneName} vs ${stream.teamTwoName ?? ''}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Score: ${stream.score ?? "N/A"}"),
                  trailing: const Icon(Icons.play_arrow, color: Colors.green),
                  onTap: () {
                    if (stream.m3U8Source.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerPage(
                            title:
                                "${stream.teamOneName} vs ${stream.teamTwoName ?? ''}",
                            url: stream.m3U8Source,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Live Streaming available soon"),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  final String title;
  final String url;

  const VideoPlayerPage({Key? key, required this.title, required this.url})
      : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();

    _videoPlayerController = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
      });

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      aspectRatio: 16 / 9,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        handleColor: Colors.redAccent,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.lightGreen,
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: _chewieController != null &&
                _videoPlayerController.value.isInitialized
            ? AspectRatio(
                aspectRatio: 16 / 9,
                child: Chewie(controller: _chewieController!),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class Datum {
  final String? other;
  final String iframeSource;
  final String m3U8Source;
  final int? matchId;
  final String? score;
  final DateTime? startTime;
  final int? teamOneId;
  final String teamOneName;
  final int? teamTwoId;
  final String? teamTwoName;

  Datum({
    this.other,
    required this.iframeSource,
    required this.m3U8Source,
    this.matchId,
    this.score,
    this.startTime,
    this.teamOneId,
    required this.teamOneName,
    this.teamTwoId,
    this.teamTwoName,
  });

  factory Datum.fromJson(Map<String, dynamic> json) {
    return Datum(
      other: json['Other'],
      iframeSource: json['iframe_source'] ?? '',
      m3U8Source: json['m3u8_source'] ?? '',
      matchId: json['match_id'],
      score: json['score'],
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'])
          : null,
      teamOneId: json['team_one_id'],
      teamOneName: json['team_one_name'] ?? "Team One",
      teamTwoId: json['team_two_id'],
      teamTwoName: json['team_two_name'] ?? "Team Two",
    );
  }
}
