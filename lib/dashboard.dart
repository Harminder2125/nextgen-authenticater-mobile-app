import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nextggendise_authenticator/const.dart';
import 'package:nextggendise_authenticator/db.dart';
import 'package:nextggendise_authenticator/helper.dart';
import 'package:nextggendise_authenticator/scan.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

  List<String>? tokens;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getalltokensList();
  }

  getalltokensList() async {
    tokens = await TokenHelper().getAllTokens();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createapp(),
      body: FutureBuilder(
        future: TokenHelper().getAllTokens(),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<String> tokens = snapshot.data ?? [];
            return ListView.builder(
              itemCount:tokens.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10,vertical: 3),
                  elevation: 5.0,
                  child: ListTile(
                    onTap: (){
                         Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          Scanqr(tokens[index])),
                                                );
                    },
                    title: Text(tokens[index]),//
                    // You can customize the ListTile further if needed
                  ),
                );
              },
            );
          }
        },
      ),
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
    
    );
  }
}
