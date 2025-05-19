// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../enums/player_state.dart';
import '../utils/youtube_player_controller.dart';

/// A widget to display play/pause button.
class PlayPauseButton extends StatefulWidget {
  /// Creates [PlayPauseButton] widget.
  const PlayPauseButton({
    super.key,
    this.controller,
    this.bufferIndicator,
  });

  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController? controller;

  /// Defines placeholder widget to show when player is in buffering state.
  final Widget? bufferIndicator;

  @override
  State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton>
    with TickerProviderStateMixin {
  late YoutubePlayerController _controller;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      value: 0,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = YoutubePlayerController.of(context);
    if (controller == null) {
      assert(
      widget.controller != null,
      '\n\nNo controller could be found in the provided context.\n\n'
          'Try passing the controller explicitly.',
      );
      _controller = widget.controller!;
    } else {
      _controller = controller;
    }
    _controller.removeListener(_controllerListener);
    _controller.addListener(_controllerListener);
  }

  @override
  void dispose() {
    _controller.removeListener(_controllerListener);
    _animController.dispose();
    super.dispose();
  }

  void _controllerListener() {
    final value = _controller.value;

    if (!mounted) return;
    setState(() {});

    if (value.isPlaying) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;
    final state = value.playerState;

    if (_showPlayPause(state)) {
      final visible = state == PlayerState.cued ||
          !value.isPlaying ||
          value.isControlsVisible;

      return Visibility(
        visible: visible,
        child: Material(
          color: Colors.transparent,
          child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                Spacer(),
                InkWell(
                    borderRadius: BorderRadius.circular(50.0),
                    onTap: () => _rewind10Seconds(),
                    child:const Icon(
                        Icons.replay_10,
                        size: 50.0,
                        color: Colors.white)
                ),
                const SizedBox(width: 32),
                InkWell(
                  borderRadius: BorderRadius.circular(50.0),
                  onTap: () => _togglePlayPause(state),
                  child: AnimatedIcon(
                    icon: AnimatedIcons.play_pause,
                    progress: _animController.view,
                    color: Colors.white,
                    size: 60.0,
                  ),
                ),
                const SizedBox(width: 32),
                InkWell(
                  borderRadius: BorderRadius.circular(50.0),
                  onTap: ()=> _forward10Seconds(),
                  child: const Icon(
                      Icons.forward_10,
                      size: 50.0,
                      color: Colors.white),
                ),
                const Spacer(),
              ]
          ),
        ),
      );
    }
    if (_controller.value.hasError) return const SizedBox();
    return widget.bufferIndicator ??
        const SizedBox.square(
          dimension: 70,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        );
  }

  void _togglePlayPause(PlayerState state) {
    state == PlayerState.playing ? _controller.pause() : _controller.play();
  }

  void _forward10Seconds() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    _controller.seekTo(newPosition);
  }

  // Hàm quay lại 10s
  void _rewind10Seconds() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    if (newPosition.inSeconds < 0) {
      _controller.seekTo(Duration.zero); // Nếu thời gian âm, đưa về đầu video
    } else {
      _controller.seekTo(newPosition);
    }
  }

  bool _showPlayPause(PlayerState state) {
    return (!_controller.flags.autoPlay && _controller.value.isReady) ||
        state == PlayerState.playing ||
        state == PlayerState.paused;
  }
}
