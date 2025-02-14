import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelsView extends StatefulWidget {
  final String videoUrl;

  const ReelsView(this.videoUrl, {super.key});

  @override
  ReelsViewState createState() => ReelsViewState();
}

class ReelsViewState extends State<ReelsView> {
  late VideoPlayerController _controller;
  bool _showButton = true;
  Timer? _hideButtonTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(true);
    _controller.initialize();
    _controller.play();
    _hideButtonAfterDelay();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video"),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showButton = true;
              });
              _hideButtonAfterDelay();
            },
            child: _controller.value.isInitialized
                ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller),)
                : const Center(child: CircularProgressIndicator()),
          ),
          if (_showButton)
            SizedBox(
              height: 240,
              width: 160,
              child: IconButton(
                icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_circle, color: Colors.white, size: 140),
                onPressed: _togglePlayPause,
              ),
            ),
        ],
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _showButton = true;
      _hideButtonAfterDelay();
    });
  }

  void _hideButtonAfterDelay() {
    _hideButtonTimer?.cancel();
    _hideButtonTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _showButton = false;
      });
    });
  }
}
