import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerScreen> createState() =>
      _VideoPlayerScreenState();
}

class _VideoPlayerScreenState
    extends State<VideoPlayerScreen> {
  late VideoPlayerController controller;

  bool initialized = false;

  @override
  void initState() {
    super.initState();

    controller =
        VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    )
          ..initialize().then((_) {
            if (!mounted) return;

            setState(() {
              initialized = true;
            });
          });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void togglePlay() {
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Video"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: initialized
            ? Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [

                  AspectRatio(
                    aspectRatio:
                        controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),

                  const SizedBox(height: 20),

                  IconButton(
                    iconSize: 70,
                    color: Colors.white,
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle,
                    ),
                    onPressed: togglePlay,
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}