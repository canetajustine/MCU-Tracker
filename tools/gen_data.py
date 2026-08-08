"""Generate mcu_tracker/lib/data.dart from mcu-tracker.html.

The HTML file is the single source of truth for the checklist, so the Flutter
app never gets a hand-typed second copy that can drift out of sync.
"""

import io
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "mcu-tracker.html")
DST = os.path.join(ROOT, "mcu_tracker", "lib", "data.dart")

ROW = re.compile(
    r'\{n:(\d+),s:(\d+),t:"(.*?)",(?:g:"(.*?)",)?y:"(.*?)",'
    r'k:"(\w+)",why:"(.*?)",how:"(.*?)"\}'
)

STATUS = {
    "essential": "Status.essential",
    "important": "Status.important",
    "required": "Status.requiredUniverse",
    "upcoming": "Status.upcoming",
}

HEADER = """// GENERATED FILE - do not edit by hand.
// Source of truth: mcu-tracker.html  ->  regenerate with: python tools/gen_data.py
//
// All 47 entries in the poster's release order.

enum Status { essential, important, requiredUniverse, upcoming }

extension StatusLabel on Status {
  String get label => switch (this) {
        Status.essential => 'Essential',
        Status.important => 'Important',
        Status.requiredUniverse => 'Required Universe',
        Status.upcoming => 'Upcoming',
      };
}

class Entry {
  const Entry({
    required this.n,
    required this.saga,
    required this.title,
    required this.year,
    required this.status,
    required this.why,
    required this.how,
    this.tag,
  });

  /// Position in the poster's release order, 1-47.
  final int n;

  /// 1 = Infinity Saga, 2 = Multiverse Saga.
  final int saga;

  final String title;
  final String year;
  final Status status;

  /// Why it matters / what you'll learn.
  final String why;

  /// How it connects to the bigger story.
  final String how;

  /// Poster's parenthetical, e.g. 'Series' or 'Fox Universe'.
  final String? tag;
}

const String sagaOneTitle = 'The Infinity Saga · Phases 1–3';
const String sagaTwoTitle = 'The Multiverse Saga · Road to Doomsday';

const List<Entry> entries = <Entry>[
"""


def dart_str(s):
    """Escape a Python string for a single-quoted Dart literal."""
    return s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")


def main():
    src = open(SRC, encoding="utf-8").read()
    start = src.index("var DATA = [")
    block = src[start:src.index("];", start)]

    rows = ROW.findall(block)
    if len(rows) != 47:
        raise SystemExit("expected 47 entries, parsed %d" % len(rows))

    out = io.StringIO()
    out.write(HEADER)
    for n, s, title, tag, year, kind, why, how in rows:
        out.write("  Entry(\n")
        out.write("    n: %s,\n" % n)
        out.write("    saga: %s,\n" % s)
        out.write("    title: '%s',\n" % dart_str(title))
        if tag:
            out.write("    tag: '%s',\n" % dart_str(tag))
        out.write("    year: '%s',\n" % dart_str(year))
        out.write("    status: %s,\n" % STATUS[kind])
        out.write("    why: '%s',\n" % dart_str(why))
        out.write("    how: '%s',\n" % dart_str(how))
        out.write("  ),\n")
    out.write("];\n")

    os.makedirs(os.path.dirname(DST), exist_ok=True)
    open(DST, "w", encoding="utf-8").write(out.getvalue())
    print("wrote %s - %d entries" % (os.path.relpath(DST, ROOT), len(rows)))


if __name__ == "__main__":
    main()
