import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'AuthService.dart';

class StudioService {
  String _baseUrl = "https://us-central1-spot-629a6.cloudfunctions.net";

//  String _baseUrl = "http://10.0.2.2:5001/spot-629a6/us-central1";

  Future<bool> createStudio(
      String userName, String studioName, String imageUrl) async {
    var currentUser = await FirebaseAuth.instance.currentUser();
    var idToken = await currentUser.getIdToken(refresh: true);

    var requestBody = json.encode({
      "userName": userName,
      "studioName": studioName,
      "profileImageUrl": imageUrl
    });

    var url = "$_baseUrl/api/studio";
    var response = await http.post(url, body: requestBody, headers: {
      "Authorization": idToken.token,
      "Content-Type": "application/json"
    });

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<void> updateStudioBanner(String banner) async {
    var currentUser = await FirebaseAuth.instance.currentUser();
    var idToken = await currentUser.getIdToken(refresh: true);

    var requestBody = json.encode({"banner": banner});

    var url = "$_baseUrl/api/studio/banner";
    var response = await http.put(url, body: requestBody, headers: {
      "Authorization": idToken.token,
      "Content-Type": "application/json"
    });

    return response.statusCode >= 200 && response.statusCode < 300;
  }
}
