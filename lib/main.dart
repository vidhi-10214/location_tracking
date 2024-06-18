import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:location_tracking/localDataBase/database.dart';
import 'package:location_tracking/localDataBase/location_database.dart.dart';
import 'package:location_tracking/localDataBase/location_database_dao.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info/device_info.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  //INITIALIZATION OF DATABASE
  final database = await $FloorAppDatabase.databaseBuilder('locations.db').build();
  final dao = database.locationDatabaseDao;
  runApp( MyApp(dao: dao,));
}

class MyApp extends StatelessWidget {
  final LocationDatabaseDao dao;
   const MyApp({super.key,required this.dao});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:  MyHomePage(title: 'ATTENDANCE ON THE BEHALF OF LOCATION',dao: dao,),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final LocationDatabaseDao dao;
  const MyHomePage({super.key, required this.title,required this.dao});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double userPlaceLatitude = 0.0;
  double userPlaceLongitude = 0.0;
  List<List<dynamic>> locationData = [];
  bool isNearHome = false;
  late Timer timer;
  AppDatabase? database;
  bool val = false;
  String isFirst = 'no';
  String? androidVersion;
  @override
  void initState() {
    ///CALLING OF FUNCTIONS FOR INITIAL SETUP
   _handleLocationPermission();
   getLocationPermission();
   check();
   getDeviceDetails();
   super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  ///REQUESTING THE PERMISSION FOR LOCATION
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    final SharedPreferences sharedPrefernceType = await SharedPreferences.getInstance();
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        sharedPrefernceType.setBool("location", false);
        return false;
      }else{
        isFirst = 'yes';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      sharedPrefernceType.setBool("location", false);
      return false;
    }

    await sharedPrefernceType.setBool("location", true);
    _fetchAndStoreLocation();
    getLocationPermission();
    check();
    return true;
  }


  ///CHECKING STATUS OF PERMISSION
  Future<bool> getLocationPermission() async{
    final SharedPreferences sharedPrefernceType = await SharedPreferences.getInstance();
    setState(() {
      val = sharedPrefernceType.getBool("location") ?? false;
      userPlaceLatitude = sharedPrefernceType.getDouble("latitude") ?? 0.0;
      userPlaceLongitude = sharedPrefernceType.getDouble("longitude") ?? 0.0;
    });
    return  val;
  }

  ///FETCHING LONGITUDE AND LATITUDE AFTER EVERY FIFTEEN MINUTES
  check()async{
    if( await getLocationPermission()){
      timer = Timer.periodic(Duration(minutes: 10), (timer) {
        _fetchAndStoreLocation();
      });
    }
    if( await getLocationPermission()){
      timer = Timer.periodic(Duration(seconds: 5), (timer) {
        distance();
      });
    }
  }

 //FETCHING LOCATION'S LONGITUDE AND LATITUDE
  _fetchAndStoreLocation() async{
    final SharedPreferences sharedPrefernceType = await SharedPreferences.getInstance();

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    final latitude = position.latitude;
    final longitude = position.longitude;
    if(isFirst == 'yes'){
      setState(() {
        userPlaceLatitude = latitude;
        sharedPrefernceType.setDouble("latitude", latitude);
        userPlaceLongitude = longitude;
        sharedPrefernceType.setDouble("longitude", longitude);
        isFirst = "no";
      });
    }
    print("latitude $latitude longitude $longitude");
    var distanceInMeter = Geolocator.distanceBetween(latitude, longitude, userPlaceLatitude, userPlaceLongitude);
    if(distanceInMeter <= 100){
      setState(() {
        isNearHome = true;
      });
      print('You are within 100 meters of your place.');
    }else{
      setState(() {
        isNearHome = false;
      });
      print('You are not within 100 meters of your place.');
    }
    //Store in database
    int? id= await widget.dao.insertLocation(Location(longitude: longitude.toString(),latitude: latitude.toString(),createdAt: DateTime.now().toString()));
    print("id==${id}");
  }

  distance() async{
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    final latitude = position.latitude;
    final longitude = position.longitude;
    var distanceInMeter = Geolocator.distanceBetween(latitude, longitude, userPlaceLatitude, userPlaceLongitude);
    if(distanceInMeter <= 100){
      setState(() {
        isNearHome = true;
      });
      print('You are within 100 meters of your place.');
    }else{
      setState(() {
        isNearHome = false;
      });
      print('You are not within 100 meters of your place.');
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title,style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
        centerTitle: true,
      ),
      body:  Column(
        children: [
          SizedBox(height:30),
          Container(
            padding: const EdgeInsets.all(40.0),
            margin: const EdgeInsets.only(top:40.0,bottom: 40.0),
            height:130,
            width:300,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Theme.of(context).colorScheme.inversePrimary,width:2.0),
            ),
            child: Column(
              children: [
                Text("Latitude of home - $userPlaceLatitude",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 14),),
                Text("Longitude of home - $userPlaceLongitude",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 14),),
              ],
            ),
          ),

          
          Container(
            margin: const EdgeInsets.only(left: 40.0,right: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width:130,
                  child: ElevatedButton(onPressed: (){
                    isNearHome?ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Great ! you are in your location range. Attendance marked successfully'))):
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Attendance can not be marked, you are out of your home location')));
                  }, child:  Text("Attendence",style: TextStyle(color: isNearHome?Colors.deepPurpleAccent:Colors.black),)),
                ),
                Container(
                  width:130,
                  child: ElevatedButton(onPressed: (){
                    requestWritePermission();
                  }, child: const Text("Export")),
                ),
              ],
            ),
          ),

          Container(
              margin: const EdgeInsets.only(left: 43.0,right: 43.0),
              child:const Column(
                children: [
                  SizedBox(height: 20,),
                  Align(alignment:Alignment.topLeft,child: Text('NOTE: - ',style: TextStyle(fontWeight: FontWeight.bold),)),
                  SizedBox(height: 20,),
                  Text("1. Attendance can only be marked With in your current location (which is mentioned above) 100 meter range."),
                  SizedBox(height: 10,),
                  Text("2. We are tracking your location after every ten minute which is saved locally, you can export your location's latitude and longitude."),
                ],
              ),
          )
        ],
      ),
    );
  }

  ///For requesting permission to write the external storage
  Future<void> requestWritePermission() async {
    final PermissionStatus status;
    if(androidVersion == "13"){
        status = await Permission.manageExternalStorage.request();

    }else{
       status = await Permission.storage.request();

    }
    print(" status $status");
    if (status.isGranted) {
      _exportToPDF();      // Write permissions are granted, proceed with file operations.
    } else {
      // Handle the case where write permissions are denied.
    }
  }

  ///for location exporting data in csv
  Future<void> exportDataToCSV() async {
    List<Location>? data = await widget.dao.getAllLocation();
    List<List<dynamic>?> val = [
      [
        'id',
        'longitude',
        'latitude',
      ],
      [' ',' ',' ',' ',' ',],
      for (var item in data!)
        [
          item.id,
          item.longitude,
          item.latitude,
        ],
    ];
    // val.add(data);
    print(data);
    final csvData = ListToCsvConverter().convert(val);
    print(csvData);
    final directory = await getExternalStorageDirectory();
    final file = File('${directory?.path}/location_data.csv');
    print(file.path);

    await file.writeAsString(csvData);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Data Exported Successfully.')));
    print('Data exported to CSV file.');
  }

  ///for location exporting data in pdf
  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    List<Location>? data = await widget.dao.getAllLocation();
    print("data $data" );
    if (data == null || data.isEmpty) {
      print('No location data to export.');
      return;
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Location Data', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),

              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  ['ID', 'Latitude', 'Longitude','Time'],
                  // [ data[0].id, data[0].latitude, data[0].longitude]
                  for (var location in data)
                   if(location.id! <= 20)
                     [ location.id.toString(), location.latitude.toString(), location.longitude.toString(),location.createdAt.toString().split(' ').first],

                ],


                border: pw.TableBorder.all(width: 1.0),
                // cellHeight: 3000,
                // headerHeight: 200,
                cellStyle: pw.TextStyle(fontSize: 12), // Adjust styling as needed
                // cellAlignments: {
                //   0: pw.Alignment.centerLeft,
                //   1: pw.Alignment.center,
                //   2: pw.Alignment.center,
                // },
              ),
            ],
          );
        },
      ),
    );
    if(locationData.length>=21) {
      pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Location Data', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),

              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  ['ID', 'Latitude', 'Longitude','Time'],
                  // [ data[0].id, data[0].latitude, data[0].longitude]
                  for (var location in data)
                   if(location.id! >= 21 && (location.id! <= 40))
                     [ location.id.toString(), location.latitude.toString(), location.longitude.toString(),location.createdAt.toString().split(' ').first],

                ],


                border: pw.TableBorder.all(width: 1.0),
                // cellHeight: 3000,
                // headerHeight: 200,
                cellStyle: pw.TextStyle(fontSize: 12), // Adjust styling as needed
                // cellAlignments: {
                //   0: pw.Alignment.centerLeft,
                //   1: pw.Alignment.center,
                //   2: pw.Alignment.center,
                // },
              ),
            ],
          );
        },
      ),
    );
    }

    if(locationData.length>=41) {
      pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Location Data', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),

              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  ['ID', 'Latitude', 'Longitude','Time'],
                  // [ data[0].id, data[0].latitude, data[0].longitude]
                  for (var location in data)
                   if(location.id! >= 41 && (location.id! <= 50))
                     [ location.id.toString(), location.latitude.toString(), location.longitude.toString(),location.createdAt.toString().split(' ').first],

                ],


                border: pw.TableBorder.all(width: 1.0),
                // cellHeight: 3000,
                // headerHeight: 200,
                cellStyle: pw.TextStyle(fontSize: 12), // Adjust styling as needed
                // cellAlignments: {
                //   0: pw.Alignment.centerLeft,
                //   1: pw.Alignment.center,
                //   2: pw.Alignment.center,
                // },
              ),
            ],
          );
        },
      ),
    );
    }

    final output = await getExternalStorageDirectory();
    final file = File('${output?.path}/location_data.pdf');
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Data Exported Successfully.')));
    print('Data exported to PDF file: ${file.path}');
  }

  ///For getting device details
  Future<void> getDeviceDetails() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      androidVersion = androidInfo.version.release;
      print('Device Model: ${androidInfo.model}');
      print('Device Manufacturer: ${androidInfo.manufacturer}');
      print('Android Version: ${androidInfo.version.release}');
      print('Android SDK: ${androidInfo.version.sdkInt}');
      print('Device ID: ${androidInfo.androidId}');
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      print('Device Model: ${iosInfo.model}');
      print('Device Name: ${iosInfo.name}');
      print('iOS Version: ${iosInfo.systemVersion}');
      print('Device ID: ${iosInfo.identifierForVendor}');
    }
  }
}
