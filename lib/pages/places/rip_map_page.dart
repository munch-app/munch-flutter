import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:munch_app/api/places_api.dart';
import 'package:munch_app/pages/places/rip_header.dart';
import 'package:munch_app/styles/buttons.dart';
import 'package:munch_app/styles/colors.dart';
import 'package:munch_app/styles/elevations.dart';
import 'package:url_launcher/url_launcher.dart';

class RIPMapPage extends StatefulWidget {
  const RIPMapPage({Key key, this.placeData}) : super(key: key);

  final PlaceData placeData;

  @override
  RIPMapPageState createState() => new RIPMapPageState();

  LatLng get latLng {
    var location = placeData.place.location;
    var split = location.latLng.split(',');
    return LatLng(double.parse(split[0]), double.parse(split[1]));
  }

  static Future<T> push<T extends Object>(BuildContext context, PlaceData placeData) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (c) => RIPMapPage(placeData: placeData),
        settings: const RouteSettings(name: '/places/map'),
      ),
    );
  }
}

class RIPMapPageState extends State<RIPMapPage> {
  GoogleMapController mapController;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: widget.latLng,
            zoom: 16.0,
          ),
          compassEnabled: false,
          myLocationEnabled: false,
          markers: Set<Marker>.of(markers.values),
        ),
        RIPHeader(
          placeData: widget.placeData,
          clear: true,
          color: MunchColors.black,
        ),
      ]),
      bottomNavigationBar: RIPMapBottom(placeData: widget.placeData),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    final markerId = MarkerId("place");
    final Marker marker = Marker(
      markerId: markerId,
      position: widget.latLng,
      infoWindow: InfoWindow(
        title: widget.placeData.place.name,
        snippet: widget.placeData.place.location.neighbourhood,
      ),
    );

    setState(() {
      mapController = controller;
      markers[markerId] = marker;
    });
  }
}

class RIPMapBottom extends StatelessWidget {
  const RIPMapBottom({Key key, this.placeData}) : super(key: key);

  final PlaceData placeData;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: elevation2,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(placeData.place.location.address),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: MunchButton.text(
              "Open Map",
              onPressed: () async {
                var latLng = placeData.place.location.latLng;
                var address = Uri.encodeFull(placeData.place.location.address).toString();
                String url = 'geo:$latLng?q=$address';
                if (await canLaunch(url)) {
                  await launch(url);
                }
              },
              style: MunchButtonStyle.secondaryOutline,
            ),
          ),
        ],
      ),
    );
  }
}
