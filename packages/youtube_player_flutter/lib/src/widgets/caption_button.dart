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
  bool _isLoadingTracks = false;
  Map<String, dynamic> _currentLanguage = {};
  final List<String> _preferredLanguageCodes = ['vi', 'en', 'ja'];

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
    if (_controller.value.isReady && _tracks.isEmpty && !_isLoadingTracks) {
      _loadAndSortCaptionTracks();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(listener);
    super.dispose();
  }

  // Phương thức listener của controller
  void listener() {
    if (mounted) {
      if (_controller.value.isReady && _tracks.isEmpty && !_isLoadingTracks) {
        _loadAndSortCaptionTracks();
      }
      setState(() {});
    }
  }

  Future<void> _loadAndSortCaptionTracks() async {
    if (_isLoadingTracks) return;
    setState(() {
      _isLoadingTracks = true;
    });

    try {
      final fetchedTracks = await _controller.getCaptionTrackList();
      if (mounted) { // Đảm bảo widget vẫn còn trong cây widget
        List<Map<String, dynamic>> orderedTracks = [];
        List<Map<String, dynamic>> otherTracks = [];

        // Sắp xếp các ngôn ngữ ưu tiên lên đầu
        for (var code in _preferredLanguageCodes) {
          final matches = fetchedTracks.where((t) => t['languageCode'] == code).toList();
          orderedTracks.addAll(matches);
        }

        // Phần còn lại
        for (var t in fetchedTracks) {
          if (!_preferredLanguageCodes.contains(t['languageCode'])) {
            otherTracks.add(t);
          }
        }

        // Sắp xếp phần còn lại theo displayName (hoặc languageName)
        otherTracks.sort((a, b) {
          final na = (a['displayName'] ?? a['languageName']) as String;
          final nb = (b['displayName'] ?? b['languageName']) as String;
          return na.compareTo(nb);
        });

        setState(() {
          _tracks = [...orderedTracks, ...otherTracks];
          _isLoadingTracks = false;
          if (_tracks.isNotEmpty) {
            Map<String, dynamic>? initialCaption = _tracks.firstWhere(
                  (track) => track['languageCode'] == '${_controller.flags.captionLanguage}',
              orElse: () => _tracks.first, // Nếu không tìm thấy, chọn track đầu tiên
            );

            if (initialCaption.isNotEmpty) {
              _currentLanguage = initialCaption;
              _controller.setCaptionTrack(_currentLanguage);
              _captionEnabled = true;
            } else {
              _captionEnabled = false; // Nếu không có track nào, tắt phụ đề
            }
          } else {
            _captionEnabled = false; // Không có track nào
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading and sorting caption tracks: $e');
      if (mounted) {
        setState(() {
          _isLoadingTracks = false;
          _captionEnabled = false;
          _tracks = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      // Xóa onOpened ở đây vì logic tải đã chuyển vào _loadAndSortCaptionTracks()
      icon: Icon(
        _captionEnabled ? Icons.closed_caption : Icons.closed_caption_off,
        color: Colors.white,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        // Mục "Bật/Tắt phụ đề"
        PopupMenuItem(
          value: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                _captionEnabled
                    ? Icons.closed_caption
                    : Icons.closed_caption_disabled_outlined,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  // Hiển thị trạng thái dựa trên _tracks và _isLoadingTracks
                  _isLoadingTracks
                      ? 'Đang tải phụ đề...'
                      : _tracks.isNotEmpty
                      ? (_captionEnabled ? 'Tắt phụ đề' : 'Bật phụ đề')
                      : 'Video này không có phụ đề',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 4),
        // Mục "Chọn ngôn ngữ"
        PopupMenuItem(
          value: 1,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                Icons.language,
                size: 18,
                // Làm mờ icon nếu không có track hoặc đang tải
                color: (_tracks.isEmpty && !_isLoadingTracks) ? Colors.grey : Colors.black,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _captionEnabled
                      ? (_currentLanguage['displayName'] as String? ?? 'Chọn ngôn ngữ')
                      : 'Chọn ngôn ngữ',
                  style: TextStyle(
                    fontSize: 12,
                    // Làm mờ text nếu không có track hoặc đang tải
                    color: (_tracks.isEmpty && !_isLoadingTracks) ? Colors.grey : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (idx) async {
        if (idx == 0) {
          // Bật/tắt phụ đề nếu có track
          if (_tracks.isNotEmpty) {
            _controller.toggleCaptions(enable: !_captionEnabled, currentLanguage: _currentLanguage);
            setState(() => _captionEnabled = !_captionEnabled);
          }
        } else {
          // Chọn ngôn ngữ
          if (_tracks.isNotEmpty) { // Chỉ cho phép chọn nếu đã có track
            final selected = await showMenu<Map<String, dynamic>>(
              context: context,
              position: RelativeRect.fromLTRB(
                MediaQuery.of(context).size.width - 100,
                kToolbarHeight + 250, // Điều chỉnh vị trí menu phù hợp
                16,
                0,
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              items: _tracks.map((track) {
                final name = track['displayName'] ?? track['languageName'];
                final isCurrent = _currentLanguage['languageCode'] == track['languageCode'];
                return PopupMenuItem(
                  value: track,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      if (isCurrent)
                        const Icon(Icons.check, size: 16, color: Colors.blue),
                      if (isCurrent)
                        const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 12),
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
