import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioMessageWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const AudioMessageWidget({
    super.key,
    required this.audioUrl,
    required this.isMe,
  });

  @override
  State<AudioMessageWidget> createState() =>
      _AudioMessageWidgetState();
}

class _AudioMessageWidgetState
    extends State<AudioMessageWidget> {
  final AudioPlayer player = AudioPlayer();

  bool playing = false;

  Duration position = Duration.zero;

  Duration duration = Duration.zero;

  double speed = 1.0;

  @override
  void initState() {
    super.initState();

    player.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          duration = d;
        });
      }
    });

    player.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          position = p;
        });
      }
    });

    player.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          playing = false;
          position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  String format(Duration d) {
    String two(int n) => n.toString().padLeft(2, "0");

    return "${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}";
  }

  Future<void> togglePlay() async {
    if (playing) {
      await player.pause();

      setState(() {
        playing = false;
      });
    } else {
      await player.play(
        UrlSource(widget.audioUrl),
      );

      await player.setPlaybackRate(speed);

      setState(() {
        playing = true;
      });
    }
  }

  Future<void> changeSpeed() async {
    if (speed == 1.0) {
      speed = 1.5;
    } else if (speed == 1.5) {
      speed = 2.0;
    } else {
      speed = 1.0;
    }

    await player.setPlaybackRate(speed);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.isMe
            ? Colors.green.shade700
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  playing
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: widget.isMe
                      ? Colors.white
                      : Colors.black,
                ),
                onPressed: togglePlay,
              ),

              Expanded(
                child: Slider(
                  value: position.inMilliseconds
                      .toDouble()
                      .clamp(
                        0,
                        duration.inMilliseconds
                            .toDouble(),
                      ),
                  max: duration.inMilliseconds == 0
                      ? 1
                      : duration.inMilliseconds
                          .toDouble(),
                  onChanged: (value) async {
                    await player.seek(
                      Duration(
                        milliseconds: value.toInt(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                format(position),
                style: TextStyle(
                  color: widget.isMe
                      ? Colors.white70
                      : Colors.black54,
                  fontSize: 12,
                ),
              ),

              GestureDetector(
                onTap: changeSpeed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${speed}x",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Text(
                format(duration),
                style: TextStyle(
                  color: widget.isMe
                      ? Colors.white70
                      : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}