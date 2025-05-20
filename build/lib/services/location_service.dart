import 'dart:math';

class LocationService {
  // Calculate distance between two points in kilometers using Haversine formula
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Radius of the Earth in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  // Convert degrees to radians
  static double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  // Check if a point is within the specified distance
  static bool isWithinDistance(
      double lat1, double lon1, double lat2, double lon2, double maxDistanceKm) {
    final distance = calculateDistance(lat1, lon1, lat2, lon2);
    return distance <= maxDistanceKm;
  }

  // Get nearby points within a certain radius
  // This is a simplified calculation for demonstrative purposes
  // For production, you should use a spatial database like PostGIS
  static List<Map<String, dynamic>> getNearbyPoints(
      double latitude, double longitude, double radiusKm, List<Map<String, dynamic>> allPoints) {
    final nearbyPoints = allPoints.where((point) {
      final pointLat = point['latitude'] as double;
      final pointLon = point['longitude'] as double;
      
      return isWithinDistance(
          latitude, longitude, pointLat, pointLon, radiusKm);
    }).toList();
    
    // Sort by distance
    nearbyPoints.sort((a, b) {
      final distA = calculateDistance(
          latitude, longitude, a['latitude'] as double, a['longitude'] as double);
      final distB = calculateDistance(
          latitude, longitude, b['latitude'] as double, b['longitude'] as double);
      
      return distA.compareTo(distB);
    });
    
    return nearbyPoints;
  }
}
