import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:munch_app/api/structured_exception.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong/latlong.dart';

class MunchLocation {
  static MunchLocation instance = MunchLocation();
  static const Distance _distance = Distance();

  static final int _expirySecond = 200;

  Position _lastPosition;
  DateTime _expiryDate = DateTime.now().add(Duration(seconds: _expirySecond));

  Position get lastPosition => _lastPosition;

  String get lastLatLng {
    Position lastPosition = _lastPosition;
    if (lastPosition == null) return null;
    return "${lastPosition.latitude},${lastPosition.longitude}";
  }

  Future<bool> isEnabled() async {
    // TODO(fuxing): This may be causing a delay, need to investigate
    PermissionStatus permission = await PermissionHandler().checkPermissionStatus(PermissionGroup.location);

    switch (permission) {
      case PermissionStatus.granted:
      case PermissionStatus.restricted:
        return true;

      default:
        return false;
    }
  }

  Future<bool> _requestPermission() async {
    final response = await PermissionHandler().requestPermissions([PermissionGroup.location]);
    switch (response[PermissionGroup.location]) {
      case PermissionStatus.granted:
      case PermissionStatus.restricted:
        return true;

      case PermissionStatus.denied:
      // TODO(fuxing): show this after location is denied
      // await PermissionHandler().shouldShowRequestPermissionRationale(PermissionGroup.location);
      default:
        return false;
    }
  }

  Future<String> request({
    bool force = false,
    bool permission = false,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (await isEnabled()) {
      return _request(force: force).timeout(timeout);
    }

    if (permission) {
      if (await _requestPermission()) {
        return _request(force: force).timeout(timeout);
      }

      throw StructuredException(
        type: "Location Services Error",
        message: "Location services permission is required but disabled.",
      );
    }
    return null;
  }

  Future<String> _request({bool force = false}) async {
    Position lastPosition = _lastPosition;

    if (!force && lastPosition != null && DateTime.now().isBefore(_expiryDate)) {
      return "${lastPosition.latitude},${lastPosition.longitude}";
    }

    lastPosition = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high).catchError((error) {
      if (error is PlatformException) {
        throw StructuredException(
          type: "Location Error",
          message: error.message,
        );
      }
      throw error;
    });

    _lastPosition = lastPosition;
    _expiryDate = DateTime.now().add(Duration(seconds: _expirySecond));

    return "${lastPosition.latitude},${lastPosition.longitude}";
  }

  ///
  /// distance in meters
  double distance(String latLng, double lat, double lng) {
    var split = latLng.split(",");
    LatLng ll = LatLng(double.parse(split[0]), double.parse(split[1]));
    return _distance.distance(ll, LatLng(lat, lng));
  }

  /// For < 10m, returns 10m
  /// For < 1km format metres in multiple of 50s
  /// For < 100km format with 1 precision floating double
  /// For > 100km format in km
  String distanceAsMetric(String latLng) {
    Position position = _lastPosition;
    if (position == null) return null;

    var meter = distance(latLng, position.latitude, position.longitude);
    if (meter <= 10.0) {
      return "10m";
    } else if (meter <= 50.0) {
      return "50m";
    } else if (meter < 1000) {
      int m = (meter ~/ 50 * 50);
      if (m == 1000) {
        return "1.0km";
      } else {
        return "${m}m";
      }
    } else if (meter < 100000) {
      return "${(meter / 1000).toStringAsFixed(1)}km";
    } else {
      return "${meter ~/ 1000}km";
    }
  }

  String distanceAsDuration(String latLng, String toLatLng) {
    var split = toLatLng.split(",");
    var meter = distance(latLng, double.parse(split[0]), double.parse(split[1]));
    int min = meter ~/ 70;

    if (min <= 1) {
      return "1 min";
    }

    return "$min min";
  }
}

String getCentroid(List<String> points) {
  double cLat = 0, cLng = 0;

  points.forEach((latLng) {
    var ll = latLng.split(",");
    cLat += double.parse(ll[0]);
    cLng += double.parse(ll[1]);
  });

  return '${cLat / points.length},${cLng / points.length}';
}

double _toRad(double radiusInKm) {
  return (1 / 110.54) * radiusInKm;
}

BoundingBox getBoundingBox(List<String> points, double offsetKm) {
  if (points.isEmpty) return null;

  final double offset = _toRad(offsetKm);

  // Max: TopLat, BotLng, North East
  // Min: TopLng, BotLat, South West
  double topLat = -1000;
  double topLng = 1000;
  double botLat = 1000;
  double botLng = -1000;

  points.forEach((latLng) {
    var ll = latLng.split(",");
    double lat = double.parse(ll[0]);
    double lng = double.parse(ll[1]);

    if (topLat < lat) topLat = lat;
    if (botLng < lng) botLng = lng;
    if (topLng > lng) topLng = lng;
    if (botLat > lat) botLat = lat;
  });

  return BoundingBox(
    topLat: topLat + offset,
    topLng: topLng - offset,
    botLat: botLat - offset,
    botLng: botLng + offset,
  );
}

class BoundingBox {
  const BoundingBox({this.topLat, this.topLng, this.botLat, this.botLng});

  final double topLat;
  final double topLng;
  final double botLat;
  final double botLng;
}
