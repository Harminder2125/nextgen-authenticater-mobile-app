import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nextggendise_authenticator/const.dart';
import 'package:nextggendise_authenticator/db.dart';
import 'package:nextggendise_authenticator/helper.dart';
import 'package:nextggendise_authenticator/login.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class Scanqr extends StatefulWidget {
  const Scanqr({super.key});

  @override
  State<Scanqr> createState() => _ScanqrState();
}

class _ScanqrState extends State<Scanqr> {
  signoutUser() async {
    await TokenHelper().deleteToken().then((value) {
      if (value['code'] == 200) {
        showtoast(value['message'], success);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    });
  }

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  PermissionStatus? status;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 200.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: white,
          borderRadius: 10,
          borderLength: 25,
          borderWidth: 5,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        callAuth();
        status = null;
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<PermissionStatus> _getCameraPermission() async {
    var status = await Permission.camera.status;

    if (!status.isGranted) {
      final result = await Permission.camera.request();
      return result;
    } else {
      return status;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getpermission();
  }

  getpermission() async {
    status = await _getCameraPermission();
  }

  final LocalAuthentication auth = LocalAuthentication();
  callAuth() async {
    try {
      // final List<BiometricType> availableBiometrics =
      // await auth.getAvailableBiometrics();
      // print(availableBiometrics);
      // if (availableBiometrics.isNotEmpty) {
      // Some biometrics are enrolled.
      final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to Login',
          options: const AuthenticationOptions(
              biometricOnly: false,
              useErrorDialogs: false,
              stickyAuth: true,
              sensitiveTransaction: true));

      if (didAuthenticate) {
        showtoast("Success Auth", success);
      } else {
        showtoast("Failed Auth", danger);
      }
      // }
      // else {
      //   showtoast("No Authentication Type Available", danger);
      // }
    } on PlatformException catch (e) {
      if (e.code == auth_error.notEnrolled) {
        showtoast("No Authentication Type Available", danger);
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        showtoast("Locked", danger);
      } else {
        showtoast("Something went wrong: ${e.message}", danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createapp(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: blue900,
        onPressed: () {
          if (status != null) {
            setState(() {});
          }
        },
        child: Icon(
          Icons.qr_code_2,
          color: white,
        ),
      ),
      bottomNavigationBar: status != null ? createBottomMenus() : null,
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          // decoration: BoxDecoration(
          // gradient: LinearGradient(
          //   colors: [
          //     Colors.blue.shade900,
          //     Colors.blue.shade700
          //   ], // Your gradient colors
          //   begin: Alignment
          //       .topCenter, // Alignment for the start of the gradient
          //   end: Alignment
          //       .bottomCenter, // Alignment for the end of the gradient
          // ),
          // ),
          child: Column(
            children: <Widget>[
              status != null
                  ? Expanded(flex: 4, child: _buildQrView(context))
                  : Text(""),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    if (result != null)
                      Text(
                        'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}',
                        style: TextStyle(fontSize: 13.0),
                      )
                    else
                      const Text('Scan a code'),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBar createBottomMenus() {
    return BottomNavigationBar(
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white,
      backgroundColor: blue900,
      selectedLabelStyle: GoogleFonts.raleway(fontSize: 13),
      unselectedLabelStyle: GoogleFonts.raleway(fontSize: 13),
      items: [
        BottomNavigationBarItem(
            icon: IconButton(
              onPressed: () async {
                try {
                  await controller?.toggleFlash();
                  setState(() {});
                } catch (e) {
                  print(e);
                }
              },
              icon: FutureBuilder(
                future: controller?.getFlashStatus(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data == true) {
                      return Icon(Icons.flash_off, color: white);
                    } else {
                      return Icon(Icons.flash_on, color: white);
                    }
                  }
                  return Icon(Icons.flash_on, color: white);
                },
              ),
            ),
            label: "Flash"),
        BottomNavigationBarItem(
            icon: IconButton(
              onPressed: () async {
                await controller?.flipCamera();
                setState(() {});
              },
              icon: FutureBuilder(
                future: controller?.getCameraInfo(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data == CameraFacing.back) {
                      return Icon(
                        Icons.camera_front,
                        color: white,
                      );
                    } else {
                      return Icon(
                        Icons.photo_camera_back,
                        color: white,
                      );
                    }
                  }
                  return Icon(
                    Icons.photo_camera_back,
                    color: white,
                  );
                },
              ),
            ),
            label: "Camera"),
      ],
    );
  }

  AppBar createapp() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          makelogo(15.0, 20.0),
          SizedBox(
            width: 10,
          ),
          Text(
            appname,
            style:
                GoogleFonts.raleway(color: white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: Colors.blue[900],
      actions: [
        IconButton(
          onPressed: () => signoutUser(),
          icon: const Icon(Icons.logout),
          color: white,
        )
      ],
    );
  }
}
