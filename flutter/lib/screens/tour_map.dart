import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/labels.dart';
import '../widgets.dart';

/// Geolocalizza il punto di ritrovo (testo libero inserito dalla guida, es.
/// "Uscita metro Colosseo, Linea B") con Nominatim/OpenStreetMap — gratuito,
/// senza API key — e mostra un pin su una mappa incorporata. Offre sempre
/// anche un link per aprire la posizione in Google Maps.
class TourMeetingPointMap extends StatefulWidget {
  const TourMeetingPointMap(
      {super.key, required this.meetingPoint, required this.city});
  final String meetingPoint;
  final String city;

  @override
  State<TourMeetingPointMap> createState() => _TourMeetingPointMapState();
}

/// Parole generiche nei punti di ritrovo che spesso confondono il geocoder
/// (es. "Uscita metro Colosseo, Linea B" non trova nulla, "Colosseo" sì).
const _fillerWords = [
  'uscita',
  'ingresso',
  'metro',
  'linea',
  'stazione',
  'fermata',
  'principale',
];

class _TourMeetingPointMapState extends State<TourMeetingPointMap> {
  late final Future<LatLng?> _future =
      _geocode(widget.meetingPoint, widget.city);

  /// Prova prima con l'indirizzo completo, poi con varianti via via più
  /// semplificate, finché Nominatim non trova un risultato.
  static Future<LatLng?> _geocode(String meetingPoint, String city) async {
    final segments =
        meetingPoint.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    final withoutFillers = meetingPoint
        .split(RegExp(r'[\s,]+'))
        .where((w) => !_fillerWords.contains(w.toLowerCase()))
        .join(' ')
        .trim();
    final candidates = <String>{
      meetingPoint,
      ...segments,
      if (withoutFillers.isNotEmpty) withoutFillers,
    };
    for (final candidate in candidates) {
      final point = await _geocodeOnce('$candidate, $city, Italia');
      if (point != null) return point;
    }
    return null;
  }

  static Future<LatLng?> _geocodeOnce(String query) async {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
      queryParameters: {'format': 'json', 'limit': '1', 'q': query},
    );
    try {
      final res = await http.get(uri,
          headers: {'User-Agent': 'GuidaTourApp/1.0 (info@guidatour.it)'});
      if (res.statusCode != 200) return null;
      final results = jsonDecode(res.body) as List;
      if (results.isEmpty) return null;
      final item = results.first as Map<String, dynamic>;
      final lat = double.tryParse(item['lat'] as String? ?? '');
      final lon = double.tryParse(item['lon'] as String? ?? '');
      if (lat == null || lon == null) return null;
      return LatLng(lat, lon);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse('https://www.google.com/maps/search/').replace(
      queryParameters: {
        'api': '1',
        'query': '${widget.meetingPoint}, ${widget.city}, Italia',
      },
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(title: t.mapTitle),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 200,
            child: FutureBuilder<LatLng?>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const ColoredBox(
                    color: kSand,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final point = snapshot.data;
                if (point == null) {
                  return ColoredBox(
                    color: kSand,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(t.mapNotFound,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: kMuted)),
                      ),
                    ),
                  );
                }
                return FlutterMap(
                  options: MapOptions(initialCenter: point, initialZoom: 15),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'it.guidatour.app',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin,
                            color: kPrimary, size: 40),
                      ),
                    ]),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _openExternal,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: Text(t.mapOpenExternal),
        ),
      ],
    );
  }
}
