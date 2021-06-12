import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_restart/flutter_restart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() async {
  runApp(
    MaterialApp(
      home: MapView(),
    ),
  );
}

class MapView extends StatefulWidget {
  MapView({Key key}) : super(key: key);

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  //Setting up Google Maps
  GoogleMapController mapController;
  final LatLng initialPosition = LatLng(33.952965, 9.570181);

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  //User's location
  Location userLocation = new Location();

  //firebase db
  DatabaseReference dbRef = FirebaseDatabase.instance.reference();

  //Showing loading screen
  bool isLoading = true;

  //checking for permission and services
  @override
  void initState() {
    super.initState();
    userLocation.serviceEnabled().then((hasService) {
      if (!hasService) {
        userLocation.requestService();
      }
    });
    userLocation.hasPermission().then((hasPermission) {
      if (hasPermission == PermissionStatus.denied) {
        userLocation.requestPermission();
      }
    });

    //Retrieving all concentrators from db
    //todo: retireve all data from db
    dbRef.once().then((DataSnapshot snapshot) {
      Map<dynamic, dynamic> values = snapshot.value;
      values.forEach((key, values) {
        Marker marker = Marker(
          markerId: MarkerId(values["id"].toString()),
          position: LatLng(values["latitude"], values["longitude"]),
          infoWindow: InfoWindow(
            title: values["name"],
            snippet: "+216 " + values["number"],
            onTap: () async {
              String call = "tel:+216" + values["number"];
              if (await canLaunch(call)) {
                await launch(call);
              } else {
                Clipboard.setData(
                  ClipboardData(text: "+216" + values["number"]),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text("Le numéro a été copié dans votre presse papier"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        );
        setState(() {
          concentrators[MarkerId(values["id"].toString())] = marker;
        });
      });
    });
    setState(() {
      isLoading = false;
    });
  }

  //Controller for the name and the phone number
  TextEditingController nameController = new TextEditingController(),
      numberController = new TextEditingController();
  //Add mode. So in order to allow the user to add a concentrator, i will use a bool to determine whether add mode is enabeled or not
  //Add mode is a mode, where the user gets to input his name (optional) and number and concentrayor's figures
  bool addMode = false;

  //Concentrators Markers
  Map<MarkerId, Marker> concentrators = <MarkerId, Marker>{};

  //Scaffold Key
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Tunisie Concentrateurs",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                  Text(
                    "Rêstez prudent! Mettez vos masques, lavez vos main et limitez vos sorties!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contact_mail,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20.0, right: 20.0),
                  ),
                  Text(
                    "Contact",
                  ),
                ],
              ),
              onTap: () async {
                if (await canLaunch("mailto:contact@aaronhaddad.tech")) {
                  launch("mailto:contact@aaronhaddad.tech");
                } else {
                  Clipboard.setData(
                      ClipboardData(text: "contact@aaronhaddad.tech"));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      "Contact sur: contact@aaronhaddad.tech, dans votre presse papier",
                    ),
                    backgroundColor: Colors.green,
                  ));
                }
              },
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    "version: 1.0.1",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: (addMode) ? Colors.blue : Color(0xff),
        title: (addMode)
            ? Text(
                "Ajouter un concentrateur",
                style: TextStyle(
                  color: Colors.white,
                ),
              )
            : Text(""),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          child: Icon(
            Icons.menu,
            color: (addMode) ? Colors.white : Colors.black,
          ),
          onTap: () {
            scaffoldKey.currentState.openDrawer();
          },
        ),
        actions: [
          GestureDetector(
            onTap: () {
              if (addMode) {
                setState(() {
                  addMode = false;
                });
              } else {
                setState(() {
                  addMode = true;
                });
              }
            },
            child: Padding(
              padding: EdgeInsets.only(
                right: 10.0,
              ),
              child: (addMode)
                  ? Icon(
                      Icons.close,
                      color: (addMode) ? Colors.white : Colors.black,
                    )
                  : Icon(
                      Icons.add,
                      color: (addMode) ? Colors.white : Colors.black,
                    ),
            ),
          ),
          GestureDetector(
            onTap: () {
              //I will temporairly restart the app
              FlutterRestart.restartApp();
            },
            child: Padding(
              padding: EdgeInsets.only(
                right: 10.0,
              ),
              child: Icon(
                Icons.refresh,
                color: (addMode) ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GoogleMap(
            onTap: (LatLng concentratorPosition) async {
              if (addMode &&
                  numberController.text.isNotEmpty &&
                  numberController.text.length == 8) {
                setState(() {
                  isLoading = true;
                });
                String name = (nameController.text.isNotEmpty)
                    ? nameController.text
                    : "Concentrateur";
                var id = concentrators.length;
                final MarkerId markerId = MarkerId(id.toString());
                try {
                  await dbRef.push().set({
                    "id": id,
                    "name": name,
                    "number": numberController.text,
                    "latitude": concentratorPosition.latitude,
                    "longitude": concentratorPosition.longitude,
                  });
                } catch (e) {
                  nameController.clear();
                  numberController.clear();
                  setState(() {
                    concentrators.remove(concentrators.length);
                    addMode = false;
                  });
                }
                var number;
                dbRef.once().then((DataSnapshot snapshot) {
                  if (snapshot.value["id"].toString() == id.toString()) {
                    number = snapshot.value["number"];
                  }
                });
                final Marker marker = new Marker(
                  markerId: markerId,
                  position: concentratorPosition,
                  infoWindow: InfoWindow(
                    title: name,
                    snippet: "+216 " + numberController.text.toString(),
                    onTap: () async {
                      String call = "tel:+216" + number.toString();
                      if (await canLaunch(call)) {
                        await launch(call);
                      } else {
                        Clipboard.setData(
                          ClipboardData(text: "+216" + number.toString()),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Le numéro a été copié dans votre presse papier"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                );
                nameController.clear();
                numberController.clear();
                setState(() {
                  concentrators[markerId] = marker;
                  addMode = false;
                });
              } else if (addMode && numberController.text.length < 8) {
                setState(() {
                  addMode = false;
                });
                nameController.clear();
                numberController.clear();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text("Veuillez entrer un numero de téléphone valide"),
                  backgroundColor: Colors.red,
                ));
              }
              setState(() {
                isLoading = false;
              });
            },
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 6.0,
            ),
            markers: Set<Marker>.of(concentrators.values),
            onMapCreated: onMapCreated,
            padding: EdgeInsets.only(
              top: 200.0,
            ),
          ),
          Visibility(
            visible: addMode,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 300.0,
              color: Colors.blue,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 100.0,
                    child: TextFormField(
                      maxLength: 8,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      controller: numberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "Numéro de téléphone",
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width - 100.0,
                    child: TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Nom complet (optionnel)",
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 15.0),
                    child: Text("Et choisissez la position sur la carte"),
                  )
                ],
              ),
            ),
          ),
          Visibility(
            visible: isLoading,
            child: Container(
              color: Colors.blue.withOpacity(0.7),
              child: Center(
                child: SpinKitCubeGrid(
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await userLocation.getLocation();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Une érreur s\'est produite. Veuillez réessayer"),
                backgroundColor: Colors.red,
              ),
            );
          }
          userLocation.onLocationChanged.first.then((location) {
            mapController.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(
                    location.latitude,
                    location.longitude,
                  ),
                  zoom: 11.0,
                  bearing: 0,
                ),
              ),
            );
          });
        },
        backgroundColor: Colors.blueAccent,
        child: Icon(
          Icons.my_location_sharp,
        ),
      ),
    );
  }
}
