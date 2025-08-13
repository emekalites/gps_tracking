import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gps_tracker/controllers/location_controller.dart';

class MainPage extends GetView<LocationController> {
  const MainPage({super.key});

  List<DataCell> _buildDataCells(String key, dynamic value) {
    return [DataCell(Text(key)), DataCell(Text(value?.toString() ?? ""))];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Service'), centerTitle: true),
      body: Obx(() {
        Location? location = controller.location.value;
        return SingleChildScrollView(
          child: Column(
            children: [
              DataTable(
                columns: const [
                  DataColumn(label: Text('Key')),
                  DataColumn(label: Text('Value')),
                ],
                rows: [
                  DataRow(cells: _buildDataCells('latitude', location?.latitude)),
                  DataRow(cells: _buildDataCells('longitude', location?.longitude)),
                  DataRow(cells: _buildDataCells('accuracy', location?.accuracy)),
                  DataRow(cells: _buildDataCells('altitude', location?.altitude)),
                  DataRow(cells: _buildDataCells('heading', location?.heading)),
                  DataRow(cells: _buildDataCells('speed', location?.speed)),
                  DataRow(cells: _buildDataCells('timestamp', location?.timestamp)),
                  DataRow(cells: _buildDataCells('isMock', location?.isMock)),
                ],
              ),
              const Divider(),
              const Text("Stored Locations", style: TextStyle(fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.storedLocations.length,
                itemBuilder: (context, index) {
                  final loc = controller.storedLocations[index];
                  return ListTile(
                    title: Text("Lat: ${loc['latitude']}, Lon: ${loc['longitude']}"),
                    subtitle: Text("Time: ${loc['timestamp']}"),
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
