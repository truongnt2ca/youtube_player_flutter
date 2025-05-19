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
  bool _captionEnabled = true;
  List<Map<String, dynamic>> _tracks = [];
  bool _loadingTracks = false;
  Map<String, dynamic> _currentLanguage = {};
  final others = <Map<String,dynamic>>[];
  final ordered = <Map<String,dynamic>>[];
  final pref = ['vi', 'en', 'ja'];
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
    return
        //   IconButton(
        //   icon: Icon(
        //     !_caption
        //         ? Icons.closed_caption
        //         : Icons.closed_caption_disabled_outlined,
        //     color: widget.color,
        //   ),
        //   onPressed: () {
        //     _controller.toggleCaptions(_caption);
        //     setState(() {
        //       _caption = !_caption;
        //     });
        //   },
        // );
      PopupMenuButton<int>(
        icon: Icon(
          _captionEnabled
              ? Icons.closed_caption
              : Icons.closed_caption_off,
          color: Colors.white,
          size: 20,
        ),
        padding: EdgeInsets.zero,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 0,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(
                  _captionEnabled
                      ? Icons.closed_caption
                      : Icons.closed_caption_disabled_outlined,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _tracks.isNotEmpty ? _captionEnabled ? 'Tắt phụ đề' : 'Bật phụ đề' : 'Video này không có phụ đề',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 4),
          PopupMenuItem(
            value: 1,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.language, size: 18, color: _tracks.isEmpty ? Colors.grey: Colors.black,),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _captionEnabled
                    // nếu displayName null thì dùng chuỗi mặc định
                        ? (_currentLanguage['displayName'] as String? ?? 'Chọn ngôn ngữ')
                        : 'Chọn ngôn ngữ',
                    style: TextStyle(fontSize: 12, color: _tracks.isEmpty ? Colors.grey: Colors.black,),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
        onSelected: (idx) async {
          if (idx == 0) {
            if(_tracks.isNotEmpty){
              _controller.toggleCaptions(enable: !_captionEnabled, currentLanguage: _currentLanguage);
              setState(() => _captionEnabled = !_captionEnabled);
            }
          } else {
            if(_tracks.isNotEmpty){
              if (_tracks.isEmpty && !_loadingTracks) {
                setState(() => _loadingTracks = true);
                _tracks = await _controller.getCaptionTrackList();
                // pick ra các ngôn ngữ theo pref
                for (var code in pref) {
                  final match = _tracks.where((t) => t['languageCode'] == code);
                  ordered.addAll(match);
                }
// phần còn lại
                for (var t in _tracks) {
                  if (!pref.contains(t['languageCode'])) others.add(t);
                }
// có thể sort others theo displayName nếu muốn alphabet
                others.sort((a, b) {
                  final na = (a['displayName'] ?? a['languageName']) as String;
                  final nb = (b['displayName'] ?? b['languageName']) as String;
                  return na.compareTo(nb);
                });

                _tracks = [...ordered, ...others];
                setState(() => _loadingTracks = false);
              }
              final selected = await showMenu<Map<String,dynamic>>(
                context: context,
                position: RelativeRect.fromLTRB(
                  MediaQuery.of(context).size.width - 100,
                  kToolbarHeight + 250,
                  16,
                  0,
                ),
                constraints: BoxConstraints(maxHeight: 200),
                items: _tracks.map((track) {
                  final name = track['displayName'] ?? track['languageName'];
                  final isCurrent = _currentLanguage['languageCode'] == track['languageCode'];
                  return PopupMenuItem(
                    value: track,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        if (isCurrent)
                          Icon(Icons.check, size: 16, color: Colors.blue),
                        if (isCurrent)
                          const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
              if (selected != null) {
                _controller.setCaptionTrack(selected);
                setState(() {
                  _captionEnabled = true;
                  _currentLanguage = selected;
                });
              }
            }
          }
        },
      );

  }
}
