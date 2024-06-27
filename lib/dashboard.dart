import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nextggendise_authenticator/const.dart';
import 'package:nextggendise_authenticator/db.dart';
import 'package:nextggendise_authenticator/helper.dart';
import 'package:nextggendise_authenticator/login.dart';
import 'package:nextggendise_authenticator/scan.dart';
import 'package:http/http.dart' as http;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<String> tokens = [];
  List<String> tokenstate = [];
  List<String> tokenwebsite = [];
  List<String> tokenurl = [];

  final _formKey = GlobalKey<FormState>();
  TextEditingController _urlController = TextEditingController();
  TextEditingController _userIdController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  Map<String, dynamic> _deviceData = <String, dynamic>{};
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  @override
  void initState() {
    // TODO: implement initState
    initPlatformState();
    getalltokensList();
    super.initState();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  Future<void> initPlatformState() async {
    var deviceData = <String, dynamic>{};
    try {
      if (Platform.isAndroid) {
        deviceData = readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      }
      if (Platform.isIOS) {
        deviceData = readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
      }
    } on PlatformException {
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };
    }

    if (!mounted) return;

    setState(() {
      _deviceData = deviceData;
    });
  }

  Future<List<String>> getalltokensList() async {
    List<String> tokens = await TokenHelper().getAllTokens();
    // print(tokens);
    for (var t in tokens) {
      String? x = await TokenHelper().readToken(t);
      if (x != null) {
        var xx = jsonDecode(x);
        tokenstate.add(xx['state']);
        tokenwebsite.add(xx['website']);
        tokenurl.add(xx['siteurl']);
      }
    }

    // No need to call setState() here since we're returning tokens to the FutureBuilder
    return tokens;
  }

  void _showConfirmationDialog(BuildContext context, String token) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirmation',
            style: GoogleFonts.raleway(),
          ),
          content: Text(
            'Are you sure you want to delete $token token ?',
            style: GoogleFonts.raleway(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                TokenHelper().deleteToken(token).then((v) async {
                  if (v['code'] == 200) {
                    int x = await TokenHelper().getTokenCount();
                    if (x == 0) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                      );
                    }
                    setState(() {});
                  } else {
                    showtoast(v['message'], danger);
                  }
                });

                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text(
                'Yes',
                style: GoogleFonts.raleway(
                    color: success, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text(
                'No',
                style: GoogleFonts.raleway(
                    color: danger, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createapp(),
      body: FutureBuilder<List<String>>(
        future: getalltokensList(),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<String> tokens = snapshot.data ?? [];
            return ListView.builder(
              itemCount: tokens.length,
              itemBuilder: (BuildContext context, int index) {
                return makecard(context, tokens, index); // Using tokendata here
              },
            );
            
          }
        },
      ),
    );
  }

  Card makecard(BuildContext context, List<String> tokens, int index) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      elevation: 5.0,
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Scanqr(tokens[index])),
          );
        },
        trailing: IconButton(
            icon: Icon(
              Icons.delete,
              color: danger,
            ),
            onPressed: () => _showConfirmationDialog(context, tokens[index])),
        title: Text(tokens[index],style: GoogleFonts.raleway(fontWeight: FontWeight.bold),),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tokenwebsite[index]} - ${tokenstate[index]}'),
            Text('${tokenurl[index]}')
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: blue700,
          child: Text(
            tokenstate[index].substring(0, 1),
            style:
                GoogleFonts.raleway(color: white, fontWeight: FontWeight.bold),
          ),
        ),
      ), //r
      // You can customize the ListTile further if needed
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
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return showNewForm(); // This is the dialog content
              },
            );
          },
          icon: const Icon(Icons.add),
          color: white,
        )
      ],
      // actions: [
      //   PopupMenuButton(
      //     icon: Icon(Icons.more_vert, color: Colors.white),
      //     itemBuilder: (BuildContext context) => [
      //       PopupMenuItem(
      //         child: Text("Menu Item 1"),
      //         value: 1,
      //       ),
      //       PopupMenuItem(
      //         child: Text("Menu Item 2"),
      //         value: 2,
      //       ),
      //       // Add more PopupMenuItem widgets as needed
      //     ],
      //   ),
      // ],
    );
  }

  logindata() async {
    var url = Uri.parse(_urlController.text + apilogin);
    var _bodystr = {
      'userid': _userIdController.text,
      'password': _passwordController.text,
      'devicename': _deviceData['manufacturer'] + _deviceData['brand'],
      'deviceOS': Platform.isAndroid
          ? "ANDROID"
          : Platform.isIOS
              ? "IOS"
              : "UNKNOW",
      'deviceModel': _deviceData['model'] ?? '',
      'deviceID': _userIdController.text +
          _deviceData['manufacturer'] +
          _deviceData['brand'] +
          _deviceData['model'] +
          _deviceData['hardware'],
      'deviceJson': jsonEncode(_deviceData)
    };

    try {
      var response = await http.post(url, body: _bodystr);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'message': 'Server under Maintenance : ${_deviceData.toString()}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'message': 'Something went wrong => $e', 'code': 999};
    }
  }

  showNewForm() {
    return AlertDialog(
      title: Text(
        'Enter Credentials',
        style: GoogleFonts.raleway(),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              
              controller: _urlController,
              decoration: InputDecoration(labelText: 'URL',hintText: "http://xyz.com"),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter URL';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _userIdController,
              decoration: InputDecoration(labelText: 'User ID'),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter User ID';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter Password';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Submit'),
          onPressed: () {
            FocusScope.of(context).unfocus();
            if (_formKey.currentState!.validate()) {
              logindata().then((value) {
                // setState(() {
                //   _progress = false;
                // });
                if (value['code'] != 200) {
                  showtoast(value['message'], danger);
                } else {
                  showtoast(value['message'], success);
                  String data = jsonEncode({
                    'deviceID': _userIdController.text +
                        _deviceData['manufacturer'] +
                        _deviceData['brand'] +
                        _deviceData['model'] +
                        _deviceData['hardware'],
                    'token': value['token'],
                    'deviceOS': Platform.isAndroid
                        ? "Android"
                        : Platform.isIOS
                            ? "IOS"
                            : "Unknow",
                    'physicalDevice': _deviceData['isPhysicalDevice'],
                    'state': value['state'],
                    'userid': _userIdController.text,
                    'website': value['website'],
                    'siteurl': _urlController.text
                  });

                  TokenHelper().saveToken(_userIdController.text, data);
                  setState(() {
                    _urlController.clear();
                    _userIdController.clear();
                    _passwordController.clear();
                  });
                }
              });

              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
