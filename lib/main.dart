import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nextggendise_authenticator/const.dart';
import 'package:nextggendise_authenticator/login.dart';
import 'package:nextggendise_authenticator/scan.dart';
import 'package:nextggendise_authenticator/splash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
     SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NGD Authenticator',
      theme: ThemeData(
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        iconTheme: IconThemeData(color: white,),
        // useMaterial3: true,
      ),
      
      home: const Splash(),
    );
  }
}


