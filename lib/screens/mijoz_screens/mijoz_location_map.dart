import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/core/mysettings.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../services/utils.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  LatLng? _initialPosition;
  bool _mapReady = false;
  Marker? _selectedMarker;
  bool _isSaving = false;

  static const LatLng _defaultPosition = LatLng(41.311081, 69.240562);
  static const double _defaultZoom = 12;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<MySettings>(context, listen: false);
    _loadSavedLocation(settings);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;
    final settings = Provider.of<MySettings>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(t("set_location")),
      ),
      body: _initialPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition!,
                    zoom: _defaultZoom,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    setState(() {
                      _mapReady = true;
                    });
                  },
                  markers: _selectedMarker != null ? {_selectedMarker!} : {},
                  onTap: (val) => _onMapTapped(val, settings),
                  myLocationButtonEnabled: false,
                ),
                if (!_mapReady) const Center(child: CircularProgressIndicator()),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 22, right: 22, bottom: 34),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _isSaving ? null : () => _saveLocation(settings),
                      child: _isSaving ? const CircularProgressIndicator(strokeWidth: 2) : Text(t("profile_save")),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () => _goToCurrentLocation(settings),
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _loadSavedLocation(MySettings settings) async {
    final double lat = settings.mijozGpsLat;
    final double lng = settings.mijozGpsLng;

    setState(() {
      if (lat != 0 && lng != 0) {
        _initialPosition = LatLng(lat, lng);
        _selectedMarker = Marker(
          markerId: const MarkerId('selected-location'),
          position: _initialPosition!,
        );
      } else {
        _initialPosition = _defaultPosition;
      }
    });
  }

  Future<void> _onMapTapped(LatLng pos, MySettings settings) async {
    setState(() {
      _selectedMarker = Marker(
        markerId: const MarkerId('selected-location'),
        position: pos,
      );
    });

    settings.mijozGpsLat = pos.latitude;
    settings.mijozGpsLng = pos.longitude;
    await settings.saveAndNotify();
  }

  Future<void> _saveLocation(MySettings settings) async {
    final t = AppLocalizations.of(context).translate;

    if (_selectedMarker == null) {
      showRedSnackBar(t("location_not_selected"));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final pos = _selectedMarker!.position;
    settings.mijozGpsLat = pos.latitude;
    settings.mijozGpsLng = pos.longitude;
    await settings.saveAndNotify();

    try {
      final uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-update");
      final fcmToken = await Utils.getToken();

      final res = await post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          "lang": settings.locale.languageCode,
          "fcm_token": fcmToken,
          "phone": settings.clientPhone,
          "Authorization": "Bearer ${settings.token}",
        },
        body: jsonEncode({
          "id": settings.mijozId,
          "address": settings.mijozAddress,
          "gps_lat": settings.mijozGpsLat,
          "gps_lng": settings.mijozGpsLng,
        }),
      );

      if (res.statusCode == 200) {
        showSuccessSnackBar(t("gl_success"));
        Navigator.pop(context);
      } else {
        showRedSnackBar("${t("unknown_error")}: ${res.statusCode}");
      }
    } catch (e) {
      showRedSnackBar("${t("unknown_error")}: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _goToCurrentLocation(MySettings settings) async {
    final t = AppLocalizations.of(context).translate;
    final location = Location();

    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          showRedSnackBar(t("location_disabled"));
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          showRedSnackBar(t("permission_denied"));
          return;
        }
      }

      final locData = await location.getLocation();
      if (locData.latitude != null && locData.longitude != null) {
        final pos = LatLng(locData.latitude!, locData.longitude!);
        _mapController.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
        await _onMapTapped(pos, settings);
      } else {
        showRedSnackBar(t("location_error"));
      }
    } catch (e) {
      showRedSnackBar(t("location_error"));
    }
  }

  void showRedSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }
}
