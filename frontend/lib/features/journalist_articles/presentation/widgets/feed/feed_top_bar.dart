import 'package:flutter/material.dart';

class FeedTopBar extends StatelessWidget {
  final VoidCallback onSearch;

  const FeedTopBar({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'Para ti',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
