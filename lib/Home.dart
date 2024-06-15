import 'dart:io';
import 'dart:developer' as devtools;
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? filepath;
  String label = "";
  double confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _tfliteinit();
  }

  Future<void> _tfliteinit() async {
    String? res = await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
      numThreads: 1,
      isAsset: true,
      useGpuDelegate: false,
    );
    devtools.log("Model loaded: $res");
  }

  Future<void> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image == null) return;
    var imageMap = File(image.path);
    setState(() {
      filepath = imageMap;
    });

    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      imageMean: 0.0,
      imageStd: 255.0,
      numResults: 2,
      threshold: 0.2,
      asynch: true,
    );

    if (recognitions == null || recognitions.isEmpty) {
      devtools.log("Recognition failed");
      return;
    }

    devtools.log(recognitions.toString());
    setState(() {
      confidence = (recognitions[0]['confidence'] * 100);
      label = (recognitions[0]['label'].toString());
    });
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan.shade100,
      appBar: AppBar(
        backgroundColor: Colors.red.shade300,
        title: Text(
          "LIVE DETECTION",
          style: GoogleFonts.alegreyaSans(
              fontWeight: FontWeight.w800, fontSize: 35),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Center(
                  child: Container(
                    width: 300,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade300,
                          spreadRadius: 5,
                          blurRadius: 2,
                          offset: const Offset(2, 10),
                        )
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: filepath == null
                            ? Icon(
                                Icons.image_search,
                                color: Colors.orange.shade200,
                              )
                            : Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Image.file(
                                  filepath!,
                                  fit: BoxFit.fill,
                                  height: 90,
                                  width: 90,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  label,
                  style: GoogleFonts.alegreyaSans(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 45),
              Text(
                "The Accuracy Percentage is ${confidence.toStringAsFixed(0)}%",
                style: GoogleFonts.alegreyaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  pickImage(ImageSource.camera);
                },
                child: Text(
                  "Take a photo",
                  style: GoogleFonts.alegreyaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 35,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  pickImage(ImageSource.gallery);
                },
                child: Text(
                  "Pick from gallery",
                  style: GoogleFonts.alegreyaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 35,
                  ),
                ),
              ),
              SizedBox(
                height: 40,
              )
            ],
          ),
        ),
      ),
    );
  }
}
