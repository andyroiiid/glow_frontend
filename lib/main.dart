import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

const String SERVER_URL = "http://192.168.50.232";
const String SERVER_PORT = ":5000";

class CameraExampleHome extends StatefulWidget {
  @override
  _CameraExampleHomeState createState() {
    return new _CameraExampleHomeState();
  }
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class _CameraExampleHomeState extends State<CameraExampleHome> {
  CameraController controller;

  List<dynamic> images;

  @override
  void initState() {
    super.initState();
    availableCameras().then((cameras) {
      controller = new CameraController(cameras[0], ResolutionPreset.high);
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    });
  }

  Widget _buildCard(String img) => Card(
          child: Column(children: [
        Text(img),
        Expanded(child: Image.network(SERVER_URL + "/" + img))
      ]));

  List<Widget> _buildCards() => images.map((img) => _buildCard(img)).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          controller == null
              ? CircularProgressIndicator()
              : AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
          Expanded(
              child: images == null
                  ? Center(child: CircularProgressIndicator())
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: _buildCards()))
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: onTakePictureButtonPressed, child: Icon(Icons.camera_alt)),
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void onTakePictureButtonPressed() async {
    setState(() {
      images = null;
    });

    var filePath = await takePicture();
    print(filePath);
    var bytes = await File(filePath).readAsBytes();
    print(bytes);
    try {
      var response = await http.post(SERVER_URL + SERVER_PORT + "/post_img",
          body: {"img": base64.encode(bytes)});
      print(response.body);

      setState(() {
        images = json.decode(response.body);
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<String> takePicture() async {
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/';
    await new Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }

    return filePath;
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
  }
}

class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "微笑面对每一天",
      home: new CameraExampleHome(),
    );
  }
}

Future<Null> main() async {
  runApp(new CameraApp());
}
