import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nextggendise_authenticator/const.dart';
import 'package:nextggendise_authenticator/db.dart';
import 'package:nextggendise_authenticator/login.dart';
import 'package:nextggendise_authenticator/scan.dart';
import 'package:nextggendise_authenticator/dashboard.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> moveToNextScreen() async {
      final storage = new FlutterSecureStorage();

      // Retrieve token
      int token;

       token = await TokenHelper().getTokenCount();//storage.read(key: 'token');
      await Future.delayed(Duration(seconds:5));

      if (token>0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    }

    // Call the function when the SplashScreen is built
    moveToNextScreen();

    
    return Scaffold(
      // appBar: AppBar(title: const Text("Nextgen Dise Authenticator",style: heading ),centerTitle: true, backgroundColor: Colors.blue[900],),
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                blue900!,
                blue700!
              ], // Your gradient colors
              begin: Alignment
                  .topCenter, // Alignment for the start of the gradient
              end: Alignment
                  .bottomCenter, // Alignment for the end of the gradient
            ),
          ),
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Image.asset('assets/images/logo.jpeg'),
              Expanded(
                child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          shield,
                          width: 100,
                          height: 100,
                        ),
                        Text(
                          appname,
                          style: GoogleFonts.raleway(
                              fontSize: 40,
                              color: white,
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(
                          height: 50,
                        ),
                        CircularProgressIndicator(
                          color: white,
                        ),
                      ],
                    )),
              ),

              Container(
                margin: const EdgeInsets.all(30),
                child: Text(
                  footer,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(fontSize: 15, color: white),
                ),
              )
            ],
          )),
        ),
      ),
    );
  }
}
