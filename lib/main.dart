import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart' as globals;
import 'package:dio/dio.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

const MaterialColor primaryBlack = MaterialColor(
  _blackPrimaryValue,
  <int, Color>{
    50: Color(0xFF000000),
    100: Color(0xFF000000),
    200: Color(0xFF000000),
    300: Color(0xFF000000),
    400: Color(0xFF000000),
    500: Color(_blackPrimaryValue),
    600: Color(0xFF000000),
    700: Color(0xFF000000),
    800: Color(0xFF000000),
    900: Color(0xFF000000),
  },
);

const int _blackPrimaryValue = 0xFF000000;
String image_download_url = "";

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: primaryBlack,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Memearia'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<List<Meme>> myStreamData;

  @override
  Future<void> initState() {
    super.initState();
    myStreamData = getmemes(globals.limits, globals.subreddits);
  }

  Future<void> downloadFile() async {
    final directory = await ExtStorage.getExternalStorageDirectory();
    //final myImagePath = '${directory}/DownloadedMemes';
    //final myImgDir = await new Directory(myImagePath).create();
    Dio dio = Dio();
    int random_name = new DateTime.now().millisecondsSinceEpoch;

    try {
      //var dir =          await getExternalStorageDirectory(); //getApplicationDocumentsDirectory();

      await dio.download(
          image_download_url, "${directory}/Memearia/_meme$random_name.jpg",
          onReceiveProgress: (rcv, total) {
        print(
            'received: ${rcv.toStringAsFixed(0)} out of total: ${total.toStringAsFixed(0)}');
      });
    } catch (e) {
      print(e);
    }
  }

  Future<List<Meme>> getmemes(int limits, List<String> subreddits) async {
    String url = "https://scraper-backend-meme-app.herokuapp.com/getfromreddit";
    String body = jsonEncode({'limits': limits, 'subreddit': subreddits});

    var resp = await http.post(url,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Charset': 'utf-8'
        },
        body: body);

    var jsonResponse = json.decode(json.decode(resp.body));
    //var x = jsonResponse["memes"];
    List<Meme> memes = [];

    for (var m in jsonResponse["memes"]) {
      Meme meme = Meme(m["title"], m["url"]);
      memes.add(meme);
    }
    print(memes.length);
    return memes;
  }

  @override
  Widget build(BuildContext context) {
    //List<String> subredditlist = ['memes'];
    final scrollcont = ScrollController();
    return Scaffold(
        appBar: AppBar(
            title: Center(child: Text(widget.title)),
            leading: GestureDetector(
              onTap: () async {
                String x = "";

                for (var sub = 0; sub < globals.subreddits.length; sub++) {
                  if (sub == globals.subreddits.length - 1) {
                    x = x + globals.subreddits[sub];
                  } else {
                    x = x + globals.subreddits[sub] + ",";
                  }
                }
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    // return object of type Dialog
                    final myController = TextEditingController()..text = x;
                    return AlertDialog(
                      title: new Text("Change Meme Lobbies"),
                      content: new TextField(
                        controller: myController,
                      ),
                      actions: <Widget>[
                        // usually buttons at the bottom of the dialog
                        new FlatButton(
                          child: new Text("Refresh"),
                          onPressed: () {
                            var arr = myController.text.split(',');
                            scrollcont.animateTo(
                              0.0,
                              curve: Curves.easeOut,
                              duration: const Duration(milliseconds: 300),
                            );
                            setState(() {
                              globals.subreddits = arr;
                              myStreamData =
                                  getmemes(globals.limits, globals.subreddits);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Icon(
                Icons.settings, // add custom icons also
              ),
            )),
        body: FutureBuilder(
            future: myStreamData,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.data != null) {
                return Container(
                    color: Colors.black,
                    child: ListView.builder(
                        controller: scrollcont,
                        itemCount: snapshot.data.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Card(
                                  color: primaryBlack,
                                  shadowColor: Colors.white,
                                  elevation: 18.0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10.0))),
                                  child: Column(children: <Widget>[
                                    FadeInImage.assetNetwork(
                                        placeholder: 'assets/placeholder.png',
                                        image: snapshot.data[index].url,
                                        fit: BoxFit.cover,
                                        width: 400.0),
                                    Center(
                                        /*child: Card(*/
                                        child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        ListTile(
                                          title: Text(
                                            snapshot.data[index].title,
                                            style: TextStyle(
                                                fontSize: 20.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.download_outlined,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            image_download_url =
                                                snapshot.data[index].url;
                                            downloadFile();
                                          },
                                        ),
                                      ],
                                    )),
                                  ]),
                                  clipBehavior: Clip.antiAlias,
                                  margin: EdgeInsets.all(8.0),
                                ),
                              ]);
                        }));
              } else {
                return Center(child: Text("Loading....."));
              }
            }));
  }
}

class Meme {
  final String title;
  final String url;

  Meme(this.title, this.url);
}
