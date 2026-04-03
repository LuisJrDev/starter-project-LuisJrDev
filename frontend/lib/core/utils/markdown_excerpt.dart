String stripMarkdown(String input) {
  var s = input;

  // quita bloques de código
  s = s.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  // quita code inline
  s = s.replaceAll(RegExp(r'`([^`]*)`'), r'$1');

  // headings/listas/quotes al inicio de línea
  s = s.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^\s{0,3}>\s?', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^\s{0,3}[-*+]\s+', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^\s{0,3}\d+\.\s+', multiLine: true), '');

  // bold/italic
  s = s.replaceAll('**', '');
  s = s.replaceAll('__', '');
  s = s.replaceAll('*', '');
  s = s.replaceAll('_', '');

  // links [text](url) -> text
  s = s.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
    (m) => m.group(1) ?? '',
  );

  // espacios
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}
