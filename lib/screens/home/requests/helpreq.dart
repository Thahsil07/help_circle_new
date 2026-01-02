import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class HelpRequest {
  // ---------------------------------------------------------------------------
  // CORE IDS
  // ---------------------------------------------------------------------------
  final String id;
  final String userId; // owner
  final String acceptedBy; // helper uid or ""
  final String completedBy; // owner uid or ""

  // ✅ CHAT ID (NULLABLE – THIS IS CRITICAL)
  final String? chatId;

  // ---------------------------------------------------------------------------
  // USER INFO
  // ---------------------------------------------------------------------------
  final String createdByName;
  final String createdByPhotoUrl;

  // ---------------------------------------------------------------------------
  // REQUEST CONTENT
  // ---------------------------------------------------------------------------
  final String title;
  final String description;
  final String locationText;
  final String urgency; // high / medium / low
  final String status; // pending / accepted / completed
  final String? category;
  final String? imageUrl;
  final double? rating;

  // ---------------------------------------------------------------------------
  // LOCATION
  // ---------------------------------------------------------------------------
  final double? latitude;
  final double? longitude;

  // ---------------------------------------------------------------------------
  // DATES
  // ---------------------------------------------------------------------------
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? needDate;

  // ---------------------------------------------------------------------------
  // RUNTIME ONLY (IMMUTABLE)
  // ---------------------------------------------------------------------------
  final double distanceKm;

  // ---------------------------------------------------------------------------
  // CONSTRUCTOR
  // ---------------------------------------------------------------------------
  const HelpRequest({
    required this.id,
    required this.userId,
    required this.acceptedBy,
    required this.completedBy,
    required this.createdByName,
    required this.createdByPhotoUrl,
    required this.title,
    required this.description,
    required this.locationText,
    required this.urgency,
    required this.status,
    this.chatId,
    this.category,
    this.imageUrl,
    this.latitude,
    this.rating,
    this.longitude,
    this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.needDate,
    this.distanceKm = 0,
  });

  // ---------------------------------------------------------------------------
  // FROM FIRESTORE
  // ---------------------------------------------------------------------------
  factory HelpRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return HelpRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      acceptedBy: data['acceptedBy'] ?? '',
      completedBy: data['completedBy'] ?? '',
      chatId: data['chatId'], // ✅ DO NOT CONVERT NULL TO ""
      createdByName: data['createdByName'] ?? 'Unknown',
      createdByPhotoUrl: data['createdByPhotoUrl'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      locationText: data['locationText'] ?? '',
      urgency: (data['urgency'] ?? 'low').toString().toLowerCase(),
      status: data['status'] ?? 'pending',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      needDate: (data['needDate'] as Timestamp?)?.toDate(),
      category: data['category'],
      imageUrl: data['imageUrl'],
      rating: (data['rating'] as num?)?.toDouble(),
    );
  }

  // ---------------------------------------------------------------------------
  // COPY WITH
  // ---------------------------------------------------------------------------
  HelpRequest copyWith({
    String? status,
    String? acceptedBy,
    String? completedBy,
    String? chatId,
    double? distanceKm,
    double? rating,
  }) {
    return HelpRequest(
      id: id,
      userId: userId,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      completedBy: completedBy ?? this.completedBy,
      chatId: chatId ?? this.chatId,
      createdByName: createdByName,
      createdByPhotoUrl: createdByPhotoUrl,
      title: title,
      description: description,
      locationText: locationText,
      urgency: urgency,
      status: status ?? this.status,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      acceptedAt: acceptedAt,
      completedAt: completedAt,
      needDate: needDate,
      category: category,
      imageUrl: imageUrl,
      rating: rating ?? this.rating,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  String get createdAtFormatted {
    if (createdAt == null) return '';

    final d = createdAt!;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }

  // ---------------------------------------------------------------------------
  // DISTANCE
  // ---------------------------------------------------------------------------
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371;
    final dLat = _deg(lat2 - lat1);
    final dLon = _deg(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg(lat1)) * cos(_deg(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _deg(double d) => d * pi / 180;

  @override
  String toString() => 'HelpRequest(id: $id, status: $status, chatId: $chatId)';
}
