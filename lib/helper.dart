import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nextggendise_authenticator/const.dart';

showtoast(String message,Color c) {
  return Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.SNACKBAR,
      timeInSecForIosWeb: 2,
      backgroundColor: c,
      textColor: white,
      fontSize: 12.0);
}

Container makelogo(r,iconsize) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white, // Choose the color you want for the border
          width: 5, // Adjust the width of the border as needed
        ),
      ),
      child: CircleAvatar(
        radius: r,
        backgroundColor: Colors
            .transparent, // Set background color to transparent to see the image
        child: ClipOval(
          child: SvgPicture.string(
            shield,
            width: iconsize,
            height: iconsize,
          ),
        ),
      ),
    );
  }



