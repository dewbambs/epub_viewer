import 'dart:io';

import 'package:dio/dio.dart';
import 'package:epub_viewer/epub_viewer.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loading = true;
  Dio dio = new Dio();

  @override
  void initState() {
    super.initState();
    download();
  }

  download() async {
    if (Platform.isIOS) {
      print('download');
      await downloadFile();
    } else {
      loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: loading
              ? CircularProgressIndicator()
              : GestureDetector(
                  onTap: () async {
                    Directory appDocDir =
                        await getApplicationDocumentsDirectory();
                    print('$appDocDir');

                    String iosBookPath = '${appDocDir.path}/chair.epub';
                    String androidBookPath = 'file:///android_asset/3.epub';
                    EpubViewer.setConfig("iosBook", "#32a852", "vertical", true);
                    EpubViewer.open(
                      Platform.isAndroid ? androidBookPath : iosBookPath,
                      lastLocation: {
                        "bookId": "2239",
                        "href": "/OEBPS/ch06.xhtml",
                        "created": 1539934158390,
                        "locations": {
                          "cfi": "epubcfi(/0!/4/4[simple_book]/2/2/6)"
                        }
                      },
                    );
                    // get current locator
                    EpubViewer.locatorStream.listen((event) {
                      print('EVENT: $event');
                    });
                  },
                  child: Container(
                    child: Text('open epub'),
                  ),
                ),
        ),
      ),
    );
  }

  Future downloadFile() async {
    print('download1');
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);

    if (permission != PermissionStatus.granted) {
      await PermissionHandler().requestPermissions([PermissionGroup.storage]);
      await startDownload();
    } else {
      await startDownload();
    }
  }

  startDownload() async {
    Directory appDocDir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();

    String path = appDocDir.path + '/chair.epub';
    print(path);
    File file = File(path);

    if (!File(path).existsSync()) {
      await file.create();
      await dio.download(
        'https://github.com/FolioReader/FolioReaderKit/raw/master/Example/'
        'Shared/Sample%20eBooks/The%20Silver%20Chair.epub',
        path,
        deleteOnError: true,
        onReceiveProgress: (receivedBytes, totalBytes) {
          print((receivedBytes / totalBytes * 100).toStringAsFixed(0));
          //Check if download is complete and close the alert dialog
          if (receivedBytes == totalBytes) {
            loading = false;
            setState(() {});
          }
        },
      );
    } else {
      loading = false;
      setState(() {});
    }
  }
}
