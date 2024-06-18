import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:nextggendise_authenticator/const.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:nextggendise_authenticator/db.dart';
import 'package:nextggendise_authenticator/helper.dart';
import 'package:nextggendise_authenticator/scan.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';


class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();


  postdata() async {
    var url = Uri.parse(dwebsite + apilogin);
    try {
      var response = await http.post(url, body: {
        'userid': _usernameController.text,
        'password': _passwordController.text
      });
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'message': 'Server under Maintainance',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'message': 'Something went wrong => $e', 'code': 999};
    }
  }

  bool _passwordVisible = false;
  bool _progress = false;
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};

  Map<String, dynamic> readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'systemFeatures': build.systemFeatures,
      'serialNumber': build.serialNumber,
      'isLowRamDevice': build.isLowRamDevice,
    };
  }

  Map<String, dynamic> readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }

@override
  void initState() {
    initPlatformState();
    super.initState();
  }

  Future<void> initPlatformState() async {
      var deviceData = <String, dynamic>{};
      try {
        if (Platform.isAndroid) {
          debugPrint("Android");
          deviceData =
              readAndroidBuildData(await deviceInfoPlugin.androidInfo);
        }
        if (Platform.isIOS) {
          debugPrint("IOS");
          deviceData = readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
        }
      }
      on PlatformException {
        deviceData = <String, dynamic>{
          'Error:': 'Failed to get platform version.'
        };
      }

      if (!mounted) return;

      setState(() {
        _deviceData = deviceData;
       
      });
    }


  @override
  Widget build(BuildContext context) {
    final bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.blue[900],actions: [
        IconButton(onPressed: (){
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: white,
                
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text("Device Information",textAlign:TextAlign.center,style: GoogleFonts.raleway(fontSize: 20),),
                      Container(
                        height: MediaQuery.of(context).size.height*4/5,
                        child: ListView(
                                children: _deviceData.keys.map(
                                      (String property) {
                                    return Row(
                                      children: <Widget>[
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          child: Text(
                                            property,
                                            
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            child: Text(
                                              '${_deviceData[property]}',
                                              maxLines: 10,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ).toList(),
                              ),
                      ),
                    ],
                  ),
                ),


              ); // Show custom dialog
            },
          );
        }, icon: Icon(Icons.info,color: white,))
      ],),
      body: GestureDetector(
        onTap: () {
          // Close the keyboard when tapped outside of text field
          FocusScope.of(context).unfocus();
        },
        child: Center(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: keyboardOpen
                    ? [white!, white!]
                    : [blue900!, blue700!], // Your gradient colors
                begin: Alignment
                    .topCenter, // Alignment for the start of the gradient
                end: Alignment
                    .bottomCenter, // Alignment for the end of the gradient
              ),
            ),
            child: Column(
              children: [


                keyboardOpen
                    ? const SizedBox(
                        height: 0,
                      )
                    :
                Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            makelogo(40.0,50.0),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              appname,
                              style: GoogleFonts.raleway(
                                  fontSize: 20,
                                  color: white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                SingleChildScrollView(
                  child: Container(
                    color: white,
                    child: Column(
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -50),
                          child: SizedBox(
                            height: 60,
                            width: double.infinity,
                            child: Stack(
                              children: List.generate(
                                50,
                                (index) => makeCircle(70, -50 + index * 45,
                                    index % 1.5 == 0 ? 20 : 30),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          "Login Securely",
                          style: GoogleFonts.raleway(
                              color: blue700,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Please enter your username';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 30.0),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _passwordVisible = !_passwordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText:
                                      !_passwordVisible, // Toggle password visibility
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20.0),
                                _progress
                                    ? Container(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator())
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: blue700,
                                        ),
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();

                                          if (_formKey.currentState!
                                              .validate()) {
                                            _progress = true;
                                            postdata().then((value) {
                                              setState(() {
                                                _progress = false;
                                              });
                                              if (value['code'] != 200) {
                                                showtoast(
                                                    value['message'], danger);
                                              } else {
                                                showtoast(
                                                    value['message'], success);
                                                TokenHelper()
                                                    .saveToken(value['token']);
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          Scanqr()),
                                                );
                                              }
                                            });
                                          }
                                        },
                                        child: Text(
                                          'Submit',
                                          style:
                                              GoogleFonts.raleway(color: white),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                keyboardOpen
                    ? const SizedBox(
                        height: 0,
                      )
                    : Container(
                        width: double.infinity,
                        color: white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          footer,
                          textAlign: TextAlign.center,
                          style:
                              GoogleFonts.raleway(fontSize: 12, color: blue700),
                        ),
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }

  

  Widget makeCircle(double size, double x, double y) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );
  }
}
