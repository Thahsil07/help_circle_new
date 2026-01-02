import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:help_circle_new/screens/home/requests/helpreq.dart';

class NearbyMapScreen extends StatelessWidget {
  final Stream<List<HelpRequest>> nearbyStream;

  const NearbyMapScreen({super.key, required this.nearbyStream});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Requests"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<List<HelpRequest>>(
        stream: nearbyStream,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snap.data!;
          if (requests.isEmpty) {
            return const Center(child: Text("No nearby requests."));
          }

          // Choose the first request as map center if user location not provided
          final first = requests.first;
          final center = LatLng(first.latitude ?? 0, first.longitude ?? 0);

          return FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.help_circle_new',
              ),

              // Markers for requests
              MarkerLayer(
                markers: requests
                    .where((r) => r.latitude != null && r.longitude != null)
                    .map(
                      (r) => Marker(
                        width: 50,
                        height: 50,
                        point: LatLng(r.latitude!, r.longitude!),
                        child: GestureDetector(
                          onTap: () {
                            // Open details
                            Navigator.pushNamed(
                              context,
                              "/request-details",
                              arguments: r,
                            );
                          },
                          child: Column(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 40,
                                color: Colors.red,
                              ),
                              Text(
                                r.title,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
