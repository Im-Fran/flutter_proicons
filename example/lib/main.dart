import 'package:flutter/material.dart';
import 'package:flutter_proicons/flutter_proicons.dart';

void main() => runApp(const GalleryApp());

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProIcons',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const Gallery(),
    );
  }
}

class Gallery extends StatefulWidget {
  const Gallery({super.key});

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  String _query = '';

  bool _matches(ProIconEntry e) {
    final q = _query.trim().toLowerCase();
    return e.name.toLowerCase().contains(q) ||
        e.description.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: ProIconCategory.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ProIcons'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final c in ProIconCategory.values) Tab(text: c.label)],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SearchBar(
                hintText: 'Search by name or description',
                leading: const Icon(Icons.search),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final category in ProIconCategory.values)
                    _CategoryGrid(
                      // Using the full list on purpose: a gallery needs every icon.
                      entries: proicons
                          .where((e) => e.category == category)
                          .where(_matches)
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.entries});

  final List<ProIconEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('No icons match your search.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 128,
        mainAxisExtent: 112,
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return Tooltip(
          message: e.description.isEmpty ? e.name : e.description,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ProIcon(e.icon, size: 32, semanticLabel: e.name),
              const SizedBox(height: 8),
              ExcludeSemantics(
                child: Text(
                  e.name,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
