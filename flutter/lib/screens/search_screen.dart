import 'package:flutter/material.dart';

import '../l10n/labels.dart';
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
    final t = l10n(context);
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final q = _controller.text.trim().toLowerCase();
        final results = appState.tours.where((tour) {
          final okCat = _category == null || tour.category == _category;
          final okLang = _language == null || tour.language == _language;
          final okQuery = q.isEmpty ||
              tour.title.toLowerCase().contains(q) ||
              tour.description.toLowerCase().contains(q) ||
              tour.meetingPoint.toLowerCase().contains(q);
          return okCat && okLang && okQuery;
        }).toList()
          ..sort((a, b) => a.start.compareTo(b.start));

        return PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  appState.city == null
                      ? t.searchTitleItaly
                      : t.searchTitle(cityLabel(context, appState.city!)),
                  style: const TextStyle(
                      fontFamily: kSerif,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: kInk)),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: t.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(_controller.clear)),
                  filled: true,
                  fillColor: kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kLine),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _chips(
                  context,
                  [
                    t.filterAll,
                    ...tourCategories.map((c) => categoryLabel(context, c))
                  ],
                  [null, ...tourCategories],
                  _category,
                  (v) => setState(() => _category = v)),
              const SizedBox(height: 8),
              _chips(
                  context,
                  [
                    t.filterAnyLanguage,
                    ...tourLanguages.map((l) => languageLabel(context, l))
                  ],
                  [null, ...tourLanguages],
                  _language,
                  (v) => setState(() => _language = v)),
              const SizedBox(height: 22),
              Text(t.searchResultsCount(results.length),
                  style: const TextStyle(color: kMuted)),
              const SizedBox(height: 12),
              if (results.isEmpty)
                EmptyState(icon: Icons.search_off, message: t.searchNoResults)
              else
                ResponsiveGrid(children: [
                  for (final tour in results)
                    TourCard(tour: tour, onTap: () => openTour(context, tour)),
                ]),
              const PlatformDisclaimer(),
            ],
          ),
        );
      },
    );
  }

  /// [labels] e [values] sono parallele: labels[i] è il testo mostrato per
  /// values[i] (il valore canonico, null per "tutti/ogni lingua").
  Widget _chips(BuildContext context, List<String> labels, List<String?> values,
      String? selected, ValueChanged<String?> onTap) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < values.length; i++)
          ChoiceChip(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            backgroundColor: kSand,
            selectedColor: kPrimary,
            side: BorderSide.none,
            labelStyle:
                TextStyle(color: selected == values[i] ? Colors.white : kInk),
            selected: selected == values[i],
            label: Text(labels[i]),
            onSelected: (_) => onTap(values[i]),
          ),
      ],
    );
  }
}
