import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:nextggendise_authenticator/const.dart';
import 'package:nextggendise_authenticator/db.dart';
import 'package:nextggendise_authenticator/helper.dart';
import 'package:nextggendise_authenticator/login.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:http/http.dart' as http;

class Scanqr extends StatefulWidget {

  final String token;
  const Scanqr(this.token, {super.key});

  @override
  State<Scanqr> createState() => _ScanqrState();
}

class _ScanqrState extends State<Scanqr> with TickerProviderStateMixin {



  signoutUser() async {
    
    await TokenHelper().deleteToken(widget.token).then((value) {
      if (value['code'] == 200) {
        showtoast(value['message'], success);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    });
  }

  signoutwebUser() async {
    await postdeletedata().then((v) async {
      if (v['code'] == 200) {
        showtoast(v['message'], success);
      } else {
        showtoast(v['message'], danger);
      }
    });
  }

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  PermissionStatus? status;
  bool? didAuthenticate = null;
  late final AnimationController _controller;
  int loggedin = -1;
  bool stopscan = false;

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
        if (result!.code != null) {
          callAuth();
        }
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
    _controller.dispose();
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
    _controller = AnimationController(vsync: this);
  }

  getpermission() async {
    status = await _getCameraPermission();
    setState(() {
      result = null;
      didAuthenticate = false;
      _controller.reset();
    });
  }

  final LocalAuthentication auth = LocalAuthentication();

  postdeletedata() async {

   

    String? data = await TokenHelper().readToken(widget.token);
    var temp = jsonDecode(data!);
    String t = temp["token"];
    String tokenurl=temp["siteurl"];
    var url = Uri.parse(tokenurl + apidelete);

    try {
      DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

      var bodystr = jsonEncode({
        'deviceID': temp["deviceID"].toString(),
        'deviceOS': temp["deviceOS"].toString(),
        'physicalDevice': temp["physicalDevice"].toString()
      });
      var response = await http.post(url,
          headers: {
            'Authorization': 'Bearer $t', // Assuming Bearer token authorization
            'Content-Type': 'application/json', // Adjust content type as needed
          },
          body: bodystr);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        var data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'message': 'Server under Maintenance',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'message': 'Something went wrong => $e', 'code': 999};
    }
  }

   void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation',style: GoogleFonts.raleway(),),
          content: Text('Are you sure you want logout from all Active Web Sessions ?',style: GoogleFonts.raleway(),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
               signoutwebUser();
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text('Yes',style: GoogleFonts.raleway(color: success,fontWeight: FontWeight.bold),),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text('No',style: GoogleFonts.raleway(color: danger,fontWeight: FontWeight.bold),),
            ),
          ],
        );
      },
    );
  }
  
  postAuthdata(double width) async {
    
    String? data = await TokenHelper().readToken(widget.token);
    var temp = jsonDecode(data!);
    String t = temp["token"];
    String tokenurl=temp["siteurl"];
    var url = Uri.parse(tokenurl + apivalidate);

    try {
      var response = await http.post(url,
          headers: {
            'Authorization': 'Bearer $t', // Assuming Bearer token authorization
            'Content-Type': 'application/json', // Adjust content type as needed
          },
          body: jsonEncode({
            'deviceID':temp["deviceID"].toString(),
            'deviceOS':temp["deviceOS"].toString().toUpperCase(),
            'physicalDevice':temp["physicalDevice"].toString(),
            'ssid': result!.code.toString(),
            'deviceWidth': width.ceil().toString()
            }));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        var data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'message': 'Server under Maintenance',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'message': 'Something went wrong => $e', 'code': 999};
    }
  }

  callAuth() async {
    try {
      // final List<BiometricType> availableBiometrics =
      // await auth.getAvailableBiometrics();
      
      // if (availableBiometrics.isNotEmpty) {
      // Some biometrics are enrolled.
      didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to Login',
          options: const AuthenticationOptions(
              biometricOnly: false,
              useErrorDialogs: false,
              stickyAuth: true,
              sensitiveTransaction: true));

      if (didAuthenticate!) {
        var x = await postAuthdata(MediaQuery.of(context).size.width);
        if (x['code'] == 200) {
          showtoast(x['message'], success);
          setState(() {
            loggedin = 1;
          });
        } else {
          loggedin = 0;
          showtoast(x['message'], danger);
        }

        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            loggedin = -1;
          });
        });
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
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: Colors.blue[900]),
                    child: Column(
                      children: [
                        makelogo(30.0, 30.0),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "NIC Shield",
                          style: GoogleFonts.raleway(
                              fontSize: 20,
                              color: white,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text("Sign Out from Mobile"),
                    onTap: signoutUser,
                    leading: Icon(Icons.power_settings_new_outlined),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(16.0),
              color: Colors.grey[200],
              child: Align(
                alignment: Alignment.bottomCenter,
                child: const Text(
                  "Version 1.0.0",
                  style: TextStyle(fontSize: 12.0, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),

      // Drawer(
      //   child: ListView(
      //     padding: EdgeInsets.zero,
      //     children: [
      //       DrawerHeader(
      //         decoration: BoxDecoration(),
      //         child: Container(
      //           height: 200,
      //           width: double.infinity,
      //           color: blue900,
      //           child: Center(child:  makelogo(15.0, 20.0),),
      //         ),
      //       ),
      //       ListTile(
      //         title: const Text("SignOut from Mobile"),
      //         onTap: signoutUser,
      //         leading: Icon(Icons.power_settings_new_outlined),
      //       )
      //     ],
      //   ),
      // ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: blue900,
        onPressed: () {
          loggedin = -1;

          if (status != null) {
            setState(() {});
          } else {
            getpermission();
          }
          stopscan = !stopscan;

          if (stopscan) {
            status = null;
            stopscan = false;
          }
        },
        child: Icon(
          (!stopscan && status == null)
              ? Icons.qr_code_2
              : Icons.slow_motion_video_sharp,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (result != null)
                      if (didAuthenticate == true)
                        if (loggedin == 1)
                          SizedBox(
                            height: 200,
                            child: Lottie.asset(
                              "assets/images/loginsuccess.json",
                              key: UniqueKey(),
                              repeat: false,
                              fit: BoxFit.cover,
                              controller: _controller,
                              onLoaded: (composition) {
                                // Configure the AnimationController with the duration of the
                                // Lottie file and start the animation.
                                _controller
                                  ..duration = composition.duration
                                  ..forward();
                              },
                            ),
                          )
                        else if (loggedin == 0)
                          Lottie.asset(
                            "assets/images/loginfailed.json",
                            key: UniqueKey(),
                            repeat: false,
                            fit: BoxFit.cover,
                            // controller: _controller,
                            // onLoaded: (composition) {
                            //   // Configure the AnimationController with the duration of the
                            //   // Lottie file and start the animation.
                            //   _controller
                            //     ..duration = composition.duration
                            //     ..forward();
                            // },
                          )
                        else
                          const SizedBox(
                            height: 0,
                          )
                      else
                        const CircularProgressIndicator()
                    //  Text(
                    //   'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}',
                    //   style: TextStyle(fontSize: 13.0),
                    // )
                    else
                      const SizedBox(height: 0),
                    if (loggedin == -1) const Text('Scan New code'),
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
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: Icon(
              Icons.menu,
              color: white,
            ), // Hamburger icon
            onPressed: () {
              Scaffold.of(context)
                  .openDrawer(); // Example action, could be different in your app
            },
          );
        },
      ),
      backgroundColor: Colors.blue[900],
      actions: [
        IconButton(
          onPressed: () => _showConfirmationDialog(context),
          icon: const Icon(Icons.desktop_access_disabled_sharp),
          color: white,
        )
      ],
    );
  }
}
