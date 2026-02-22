import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// Using constants from AgentOnboarding for consistency
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kTextColorDark = Color(0xFF1F2937);
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kScaffoldBackground = Color(0xFFF3F4F6);

class VideoTutorial {
  final String title;
  final String videoId;

  VideoTutorial({required this.title, required this.videoId});
}

final List<VideoTutorial> videoTutorials = [
  VideoTutorial(title: 'Product Overview', videoId: 'NtjkCM-iuYI'),
  VideoTutorial(title: 'National Life Insurance PLC TVC - Securing Your Future Since 1985 | Customer Care# 16749', videoId: '7YRC3paxYXE'),
  VideoTutorial(title: 'National Life Insurance PLC Head Office - A Hub of Trust and Security Since 1985', videoId: 'N3kIL1DcjjY'),
  VideoTutorial(title: 'অর্থ উপদেষ্টা ড সালেহ উদ্দিন আহমেদ থেকে 24th ICAB National Award গ্রহন করেন কোম্পানীর সিইও মোঃ কাজি', videoId: 'g2jeCqAILJY')
];

class VideoTutorialsScreen extends StatelessWidget {
  const VideoTutorialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('Video Tutorials'),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kTextColorLight,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: videoTutorials.length,
        itemBuilder: (context, index) {
          final video = videoTutorials[index];
          return _buildVideoCard(context, video);
        },
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, VideoTutorial video) {
    final thumbnailUrl = 'https://img.youtube.com/vi/${video.videoId}/hqdefault.jpg';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  VideoPlayerScreen(videoId: video.videoId, title: video.title),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : const SizedBox(
                            height: 180,
                            child: Center(child: CircularProgressIndicator()));
                  },
                  errorBuilder: (context, error, stack) {
                    return const SizedBox(
                        height: 180,
                        child: Icon(Icons.error_outline,
                            color: Colors.red, size: 40));
                  },
                ),
                const Icon(Icons.play_circle_fill, color: Colors.white70, size: 60),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(video.title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextColorDark)),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  const VideoPlayerScreen({super.key, required this.videoId, required this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kTextColorLight,
      ),
      body: Center(child: YoutubePlayer(controller: _controller)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}