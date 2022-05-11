import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:shortest_route/location_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(23.810332, 90.4125181),
    zoom: 15,
  );

  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polyLines = <Polyline>{};
  int _polylineIdCounter = 1;

  GooglePlace? googlePlace;
  List<AutocompletePrediction> originPredictions = [];
  List<AutocompletePrediction> destinationPredictions = [];

  @override
  void initState() {
    super.initState();
    googlePlace = GooglePlace('AIzaSyA0y82hvYQpAYdusasMnFiQOgy-D5rPYWA');
    _setMarker(const LatLng(23.810332, 90.4125181));
  }

  _setMarker(LatLng point){
    setState(() {
      _markers.add(
        Marker(markerId: MarkerId(_origin.text),position: point,icon: BitmapDescriptor.defaultMarker)
      );
    });
  }

  _updateMarker(LatLng start, LatLng end){
    _markers.clear();
    setState(() {
      _markers.add(
          Marker(markerId: MarkerId(_origin.text),position: start,icon: BitmapDescriptor.defaultMarker)
      );
      _markers.add(
          Marker(markerId: MarkerId(_destination.text),position: end,icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue))
      );
    });
  }

  void _setPolyline(List<PointLatLng> points){
    _polyLines.clear();
    final String polylineIdVal = 'polyline$_polylineIdCounter';
    _polylineIdCounter++;
    _polyLines.add(
        Polyline(
          polylineId: PolylineId(polylineIdVal),
          width: 2,
          color: Colors.blue,
          points: points.map((point) => LatLng(point.latitude, point.longitude)).toList()
        )
    );
  }

  void _originAutoCompleteSearch(String value) async {
    var result = await googlePlace!.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      setState(() {
        originPredictions = result.predictions!;
      });
    }
  }
  void _destinationAutoCompleteSearch(String value) async {
    var result = await googlePlace!.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      setState(() {
        destinationPredictions = result.predictions!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            ///Origin Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: _origin,
                textCapitalization: TextCapitalization.words,
                // onChanged: (value){
                //   if (value.isNotEmpty) {
                //     _originAutoCompleteSearch(value);
                //   } else {
                //     if (originPredictions.isNotEmpty && mounted) {
                //       setState(() {
                //         originPredictions = [];
                //       });
                //     }
                //   }
                // },
                decoration: const InputDecoration(
                  hintText: 'Origin'
                ),
              ),
            ),
            ///Suggestion
            if(originPredictions.isNotEmpty) Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                shrinkWrap: true,
                itemCount: originPredictions.length,
                itemBuilder: (context,index)=> InkWell(
                  onTap: (){
                    _origin.text = originPredictions[index].description!;
                    originPredictions.clear();
                    setState(() {});
                  },
                  child: Text(originPredictions[index].description!)),
                separatorBuilder: (context, index)=>const SizedBox(height: 15),
              ),
            ),

            ///Destination Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _destination,
                      textCapitalization: TextCapitalization.words,
                      // onChanged: (value){
                      //   if (value.isNotEmpty) {
                      //     _destinationAutoCompleteSearch(value);
                      //   } else {
                      //     if (destinationPredictions.isNotEmpty && mounted) {
                      //       setState(() {
                      //         destinationPredictions = [];
                      //       });
                      //     }
                      //   }
                      // },
                      decoration: const InputDecoration(
                        hintText: 'Destination'
                      ),
                    ),
                  ),

                  ///Search Button
                  ElevatedButton(
                    onPressed: ()async{
                      if(_origin.text.isNotEmpty && _destination.text.isNotEmpty){
                        originPredictions.clear();destinationPredictions.clear();
                        setState(() {});
                        var directions = await LocationService().getDirections(_origin.text, _destination.text);
                        _goToPlace(
                            directions['start_location']['lat'],
                            directions['start_location']['lng'],
                            directions['bounds_ne'],
                            directions['bounds_sw']
                        );
                        _setPolyline(directions['polyline_decoded']);
                      }
                    },
                    child: const Icon(Icons.search),
                  )
                ],
              ),
            ),
            ///Suggestion
            if(destinationPredictions.isNotEmpty) Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                shrinkWrap: true,
                itemCount: destinationPredictions.length,
                itemBuilder: (context,index)=> InkWell(
                    onTap: (){
                      _destination.text = destinationPredictions[index].description!;
                      destinationPredictions.clear();
                      setState(() {});
                    },
                    child: Text(destinationPredictions[index].description!)),
                separatorBuilder: (context, index)=>const SizedBox(height: 15),
              ),
            ),

            Expanded(
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _initialPosition,
                markers: _markers,
                polylines: _polyLines,
                onMapCreated: (GoogleMapController controller){
                  _controller.complete(controller);
                },
              ),
            ),

          ],
        ),
      ),
    );
  }

  Future<void> _goToPlace(double lat, double lng, Map<String,dynamic> boundsNe, Map<String,dynamic> boundsSw) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(lat,lng),zoom: 15)
    ));

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
            northeast: LatLng(boundsNe['lat'], boundsNe['lng']),
        ),15)
    );
    _updateMarker(LatLng(boundsSw['lat'], boundsSw['lng']), LatLng(boundsNe['lat'], boundsNe['lng']));
  }
}
