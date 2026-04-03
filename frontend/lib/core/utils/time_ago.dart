String timeAgo(DateTime dateTime, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final diff = n.difference(dateTime);

  if (diff.inSeconds < 10) return 'Ahora mismo';
  if (diff.inSeconds < 60) return 'Hace ${diff.inSeconds}s';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays} días';

  final weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return 'Hace ${weeks} sem';

  final months = (diff.inDays / 30).floor();
  if (months < 12) return 'Hace ${months} mes${months == 1 ? '' : 'es'}';

  final years = (diff.inDays / 365).floor();
  return 'Hace ${years} año${years == 1 ? '' : 's'}';
}
