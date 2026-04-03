import 'package:flutter/material.dart';

enum ReaderThemePreset { dark, gray, sepia }

class ReaderSettings {
  final double fontScale;
  final ReaderThemePreset preset;

  const ReaderSettings({required this.fontScale, required this.preset});

  ReaderSettings copyWith({double? fontScale, ReaderThemePreset? preset}) {
    return ReaderSettings(
      fontScale: fontScale ?? this.fontScale,
      preset: preset ?? this.preset,
    );
  }
}

Future<ReaderSettings?> showReaderSettingsSheet(
  BuildContext context, {
  required ReaderSettings current,
}) {
  return showModalBottomSheet<ReaderSettings>(
    context: context,
    showDragHandle: true,
    isScrollControlled: false,
    builder: (_) => _ReaderSettingsSheet(current: current),
  );
}

class _ReaderSettingsSheet extends StatefulWidget {
  final ReaderSettings current;

  const _ReaderSettingsSheet({required this.current});

  @override
  State<_ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<_ReaderSettingsSheet> {
  late double _scale = widget.current.fontScale;
  late ReaderThemePreset _preset = widget.current.preset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Text size',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: _scale <= 0.9
                    ? null
                    : () => setState(() => _scale -= 0.1),
                icon: const Icon(Icons.text_decrease),
              ),
              Text('${(_scale * 100).round()}%'),
              IconButton(
                onPressed: _scale >= 1.6
                    ? null
                    : () => setState(() => _scale += 0.1),
                icon: const Icon(Icons.text_increase),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Text(
                'Theme',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              SegmentedButton<ReaderThemePreset>(
                segments: const [
                  ButtonSegment(
                    value: ReaderThemePreset.dark,
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: ReaderThemePreset.gray,
                    label: Text('Gray'),
                  ),
                  ButtonSegment(
                    value: ReaderThemePreset.sepia,
                    label: Text('Sepia'),
                  ),
                ],
                selected: {_preset},
                onSelectionChanged: (s) => setState(() => _preset = s.first),
              ),
            ],
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  ReaderSettings(fontScale: _scale, preset: _preset),
                );
              },
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
