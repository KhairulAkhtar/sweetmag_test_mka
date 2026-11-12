import 'package:flutter/material.dart';

enum StatePlaceholderType { loading, error, offline, empty }

class StatePlaceholder extends StatelessWidget {
  const StatePlaceholder({
    super.key,
    required this.type,
    this.message,
    this.onRetry,
  });

  final StatePlaceholderType type;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (type == StatePlaceholderType.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final String title =
        message ??
        switch (type) {
          StatePlaceholderType.empty => 'No products found',
          StatePlaceholderType.offline => 'No internet connection',
          _ => 'Something went wrong',
        };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              switch (type) {
                StatePlaceholderType.empty => Icons.search_off_rounded,
                StatePlaceholderType.offline =>
                  Icons.signal_wifi_connected_no_internet_4_rounded,
                _ => Icons.error_outline_rounded,
              },
              size: 54,
              color: Theme.of(context).colorScheme.primary.withAlpha(179),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
