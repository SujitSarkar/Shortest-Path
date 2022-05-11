import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LocationService{
  final String apiKey = 'AIzaSyCS5dkzV7PAltcWH5C_J7QsOaB5BXTU5D4';

  Future<String> getPlaceId(String input)async{
    final String url = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$apiKey';
    try{
      var response = await http.get(Uri.parse(url));
      var jsonData = jsonDecode(response.body);
      //var placeId = jsonData['candidates'][0]['place_id'] as String;
      print(jsonData);
      return '';
    }catch(e){
      if (kDebugMode) {
        print(e.toString());
      }
      return e.toString();
    }
  }

  Future<Map<String,dynamic>> getPlace(String input)async{
    String placeId = await getPlaceId(input);

    final String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';
    try{
      var response = await http.get(Uri.parse(url));
      var jsonData = jsonDecode(response.body);
      var result = jsonData['result'] as Map<String,dynamic>;
      print(result);
      return result;
    }catch(e){
      if (kDebugMode) {
        print(e.toString());
      }
      return {};
    }
  }
}