// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../utils/youtube_player_controller.dart';

/// A widget to enable/disable subtitle
class CaptionButton extends StatefulWidget {
  /// Creates [CaptionButton] widget.
  const CaptionButton({
    super.key,
    this.controller,
    this.color = Colors.white,
  });

  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController? controller;

  /// Defines color of the button.
  final Color color;

  @override
  State<CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<CaptionButton> {
  late YoutubePlayerController _controller;
  bool _caption = false;

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
    _controller.removeListener(listener);
    _controller.addListener(listener);
  }

  @override
  void dispose() {
    _controller.removeListener(listener);
    super.dispose();
  }

  void listener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        !_caption
            ? Icons.closed_caption
            : Icons.closed_caption_disabled_outlined,
        color: widget.color,
      ),
      onPressed: () {
        _controller.toggleCaptions(_caption);
        setState(() {
          _caption = !_caption;
        });
      },
    );

    // PopupMenuButton<int>(
    //   icon: Icon(_captionEnabled ? Icons.closed_caption : Icons.closed_caption_disabled, color: widget.color),
    //   onSelected: (value) async {
    //     if (value == 0) {
    //       // toggle cc
    //       _controller.toggleCaptions(!_captionEnabled);
    //       setState(() => _captionEnabled = !_captionEnabled);
    //     } else if (value == 1) {
    //       // chọn ngôn ngữ
    //       final lang = await showMenu<String>(
    //         context: context,
    //         position: RelativeRect.fill,
    //         items: ['en','vi','ja','es'].map((l) {
    //           return PopupMenuItem(value: l, child: Text(l));
    //         }).toList(),
    //       );
    //       if (lang != null) {
    //         // reload video với ngôn ngữ mới
    //         await _controller.value.webViewController?.evaluateJavascript(source: """
    //       player.loadVideoById({
    //         videoId: '${_controller.initialVideoId}',
    //         startSeconds: ${_controller.value.position.inSeconds},
    //         cc_load_policy: 1,
    //         cc_lang_pref: '$lang'
    //       });
    //     """);
    //         setState(() => _currentLang = lang);
    //       }
    //     }
    //   },
    //   itemBuilder: (_) => [
    //     PopupMenuItem(value: 0, child: Text(_captionEnabled ? 'Tắt phụ đề' : 'Bật phụ đề')),
    //     PopupMenuItem(value: 1, child: Text('Ngôn ngữ phụ đề')),
    //   ],
    // )
  }
}
