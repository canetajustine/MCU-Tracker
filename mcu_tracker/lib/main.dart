import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(McuTrackerApp(store: TrackerStore(prefs)));
}

class McuTrackerApp extends StatelessWidget {
  const McuTrackerApp({super.key, required this.store});

  final TrackerStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (BuildContext context, _) {
        return MaterialApp(
          title: 'MCU Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: store.themeMode,
          theme: buildTheme(AppPalette.light, Brightness.light),
          darkTheme: buildTheme(AppPalette.dark, Brightness.dark),
          home: TrackerPage(store: store),
        );
      },
    );
  }
}

/// Either a saga heading or one checklist entry.
sealed class _Row {
  const _Row();
}

class _SagaRow extends _Row {
  const _SagaRow(this.title, this.ids);
  final String title;
  final List<int> ids;
}

class _EntryRow extends _Row {
  const _EntryRow(this.entry);
  final Entry entry;
}

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key, required this.store});

  final TrackerStore store;

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  final Set<int> _expanded = <int>{};
  late final List<_Row> _rows = _buildRows();

  static List<_Row> _buildRows() {
    final List<Entry> one =
        entries.where((Entry e) => e.saga == 1).toList(growable: false);
    final List<Entry> two =
        entries.where((Entry e) => e.saga == 2).toList(growable: false);
    return <_Row>[
      _SagaRow(sagaOneTitle, one.map((Entry e) => e.n).toList()),
      ...one.map(_EntryRow.new),
      _SagaRow(sagaTwoTitle, two.map((Entry e) => e.n).toList()),
      ...two.map(_EntryRow.new),
    ];
  }

  Future<void> _confirmReset() async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear all watched titles?'),
        content: const Text('This cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (yes ?? false) await widget.store.clear();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _Header(
              store: widget.store,
              onReset: _confirmReset,
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  14,
                  14,
                  14,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                itemCount: _rows.length,
                itemBuilder: (BuildContext context, int i) {
                  final _Row row = _rows[i];
                  return switch (row) {
                    _SagaRow(:final String title, :final List<int> ids) =>
                      _SagaHeader(
                        title: title,
                        done: widget.store.countWithin(ids),
                        total: ids.length,
                        topPadding: i == 0 ? 0 : 26,
                      ),
                    _EntryRow(:final Entry entry) => _EntryTile(
                        entry: entry,
                        watched: widget.store.isWatched(entry.n),
                        expanded: _expanded.contains(entry.n),
                        onToggleWatched: () => widget.store.toggle(entry.n),
                        onToggleExpanded: () => setState(() {
                          if (!_expanded.remove(entry.n)) {
                            _expanded.add(entry.n);
                          }
                        }),
                      ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: p.bg,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.store, required this.onReset});

  final TrackerStore store;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final int done = store.watchedCount;
    final int total = entries.length;

    final int sagaOneDone = store.countWithin(
      entries.where((Entry e) => e.saga == 1).map((Entry e) => e.n),
    );
    final int sagaTwoDone = done - sagaOneDone;

    final Entry? next = entries
        .cast<Entry?>()
        .firstWhere((Entry? e) => !store.isWatched(e!.n), orElse: () => null);

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'MARVEL STUDIOS · RELEASE ORDER',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.7,
                        color: p.dim,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'THE COMPLETE WATCH GUIDE',
                      style: TextStyle(
                        fontSize: 19,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Road to Avengers: Doomsday',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        color: p.muted,
                      ),
                    ),
                  ],
                ),
              ),
              _IconAction(
                icon: switch (store.themeMode) {
                  ThemeMode.system => Icons.brightness_auto_outlined,
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.dark => Icons.dark_mode_outlined,
                },
                tooltip: 'Theme: ${store.themeMode.name}',
                onPressed: store.cycleTheme,
              ),
              const SizedBox(width: 4),
              _IconAction(
                icon: Icons.restart_alt,
                tooltip: 'Reset progress',
                onPressed: onReset,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                      text: '$done',
                      style: TextStyle(color: p.essential),
                    ),
                    TextSpan(text: ' / $total', style: TextStyle(color: p.ink)),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'WATCHED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: p.muted,
                ),
              ),
              const Spacer(),
              Text(
                'Infinity $sagaOneDone/23 · Multiverse $sagaTwoDone/24',
                style: TextStyle(
                  fontSize: 10.5,
                  color: p.dim,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures()
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: done / total),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (BuildContext context, double value, _) =>
                  LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: p.line,
                valueColor: AlwaysStoppedAnimation<Color>(p.essential),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // A rounded box cannot carry a differently-coloured left edge, so the
          // accent stripe is a real child behind a clip.
          _AccentCard(
            radius: 8,
            accent: p.essential,
            fill: p.surfaceAlt,
            border: p.line,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
              child: Row(
                children: <Widget>[
                  Text(
                    'WATCH NEXT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: p.dim,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      next == null
                          ? 'All 47 done — you are ready for Doomsday.'
                          : '${next.title}  ${next.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: p.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      color: p.muted,
      style: IconButton.styleFrom(
        backgroundColor: p.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: p.line),
        ),
        minimumSize: const Size(40, 40),
      ),
    );
  }
}

class _SagaHeader extends StatelessWidget {
  const _SagaHeader({
    required this.title,
    required this.done,
    required this.total,
    required this.topPadding,
  });

  final String title;
  final int done;
  final int total;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 10),
      child: Container(
        padding: const EdgeInsets.only(bottom: 7),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: p.ink, width: 2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: p.ink,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$done/$total',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: p.muted,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.watched,
    required this.expanded,
    required this.onToggleWatched,
    required this.onToggleExpanded,
  });

  final Entry entry;
  final bool watched;
  final bool expanded;
  final VoidCallback onToggleWatched;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final Color accent = p.statusColor(entry.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: _AccentCard(
        radius: 10,
        accent: watched ? p.line : accent,
        fill: watched ? p.bg : p.surface,
        border: p.line,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                // Deliberately outside the expand target: tapping the box
                // must never open the row.
                Semantics(
                  checked: watched,
                  label: 'Mark ${entry.title} as watched',
                  child: InkWell(
                    onTap: onToggleWatched,
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 46,
                      height: 52,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          width: 21,
                          height: 21,
                          decoration: BoxDecoration(
                            color: watched ? p.essential : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: watched ? p.essential : p.dim,
                              width: 2,
                            ),
                          ),
                          child: watched
                              ? Icon(Icons.check, size: 14, color: p.surface)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: onToggleExpanded,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 11, 8),
                      child: Row(
                        children: <Widget>[
                          Text(
                            entry.n.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: p.dim,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  entry.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.25,
                                    fontWeight:
                                        watched ? FontWeight.w500 : FontWeight.w600,
                                    color: watched ? p.dim : p.ink,
                                    decoration: watched
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: p.dim,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      entry.year,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: p.muted,
                                        fontFeatures: const <FontFeature>[
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _Chip(
                                      label: entry.status.label,
                                      color: watched ? p.dim : accent,
                                      fill: watched
                                          ? Colors.transparent
                                          : p.statusTint(entry.status),
                                      border: watched ? p.line : accent,
                                    ),
                                    if (entry.tag != null) ...<Widget>[
                                      const SizedBox(width: 6),
                                      _Chip(
                                        label: entry.tag!,
                                        color: p.dim,
                                        fill: Colors.transparent,
                                        border: p.line,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: p.dim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(46, 0, 13, 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _Fact(
                            label: 'WHY IT MATTERS',
                            body: entry.why,
                            accent: accent,
                          ),
                          const SizedBox(height: 10),
                          _Fact(
                            label: 'HOW IT CONNECTS',
                            body: entry.how,
                            accent: accent,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rounded card with a full-height accent stripe down its left edge.
///
/// Flutter refuses to round a border whose sides differ in colour, so the
/// stripe is a sibling widget sized by [IntrinsicHeight] and clipped to the
/// card's radius rather than a `BorderSide`.
class _AccentCard extends StatelessWidget {
  const _AccentCard({
    required this.radius,
    required this.accent,
    required this.fill,
    required this.border,
    required this.child,
  });

  final double radius;
  final Color accent;
  final Color fill;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: border),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 3, color: accent),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.fill,
    required this.border,
  });

  final String label;
  final Color color;
  final Color fill;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: color,
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.body,
    required this.accent,
  });

  final String label;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 1,
          color: p.line,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: accent,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          body,
          style: TextStyle(fontSize: 13.5, height: 1.5, color: p.muted),
        ),
      ],
    );
  }
}
