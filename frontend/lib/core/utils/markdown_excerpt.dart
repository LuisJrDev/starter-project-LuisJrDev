String stripMarkdown(String input) {
  var s = input;

  s = s.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  s = s.replaceAll(RegExp(r'`([^`]*)`'), r'$1');

  s = s.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^\s{0,3}>\s?', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^\s{0,3}[-*+]\s+', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^\s{0,3}\d+\.\s+', multiLine: true), '');

  s = s.replaceAll('**', '');
  s = s.replaceAll('__', '');
  s = s.replaceAll('*', '');
  s = s.replaceAll('_', '');

  s = s.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
    (m) => m.group(1) ?? '',
  );

  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}
