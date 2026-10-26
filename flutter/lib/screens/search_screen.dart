import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'tour_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = '', this.initialCategory});
  final String initialQuery;
  final String? initialCategory;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);
  late String? _category = widget.initialCategory;
  String? _language;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final q = _controller.text.trim().toLowerCase();
        final results = appState.tours.where((t) {
          final okCat = _category == null || t.category == _category;
          final okLang = _language == null || t.language == _language;
          final okQuery = q.isEmpty ||
              t.title.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q) ||
              t.meetingPoint.toLowerCase().contains(q);
          return okCat && okLang && okQuery;
        }).toList()
          ..sort((a, b) => a.start.compareTo(b.start));

        return PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tour a Roma',
                  style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800, color: kInk)),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Es. Colosseo, Trastevere, bambini…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(_controller.clear)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFDCE5E0)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _chips(['Tutti', ...tourCategories], _category ?? 'Tutti',
                  (v) => setState(() => _category = v == 'Tutti' ? null : v)),
              const SizedBox(height: 8),
              _chips(
                  ['Ogni lingua', ...tourLanguages],
                  _language ?? 'Ogni lingua',
                  (v) => setState(
                      () => _language = v == 'Ogni lingua' ? null : v)),
              const SizedBox(height: 22),
              Text('${results.length} tour',
                  style: const TextStyle(color: kMuted)),
              const SizedBox(height: 12),
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                      child: Text('Nessun tour trovato con questi filtri.')),
                )
              else
                ResponsiveGrid(children: [
                  for (final t in results)
                    TourCard(tour: t, onTap: () => openTour(context, t)),
                ]),
              const PlatformDisclaimer(),
            ],
          ),
        );
      },
    );
  }

  Widget _chips(
      List<String> items, String selected, ValueChanged<String> onTap) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final c in items)
          ChoiceChip(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            backgroundColor: const Color(0xFFE1F0EC),
            selectedColor: kPrimary,
            side: BorderSide.none,
            labelStyle: TextStyle(color: selected == c ? Colors.white : kInk),
            selected: selected == c,
            label: Text(c),
            onSelected: (_) => onTap(c),
          ),
      ],
    );
  }
}
