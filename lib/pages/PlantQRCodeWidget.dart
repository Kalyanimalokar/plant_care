import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';

class PlantQRCode extends StatelessWidget {
  final String plantId;

  const PlantQRCode({
    super.key,
    required this.plantId
  });

  Future<void> _saveQrCode(BuildContext context) async {
    try {
    //   Crating QR painting
      final qrPainter = QrPainter(
          data: plantId,
          version: QrVersions.auto,
          eyeStyle: const QrEyeStyle(
            eyeShape:  QrEyeShape.square,
            color: Color(0xFF4A6741),
          ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF4A6741),
        ),
      );

    //   Create Image
      final painter = qrPainter;
      final size = 320.0;
      final imageData =  await painter.toImageData(size);
      if (imageData == null) return;

    //   Get temporary directory
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/qr_$plantId.png';
      final imagefile = File (imagePath);

    //   Save Image
      await imagefile.writeAsBytes(imageData.buffer.asUint8List());

    //   Share image
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: "QR Code for Plant: $plantId",
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving QR code: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(
                  data: plantId,
                  version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF4A6741),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF4A6741),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                plantId,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6741),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                  onPressed: () => _saveQrCode(context),
                icon: const Icon(Icons.download),
                label: const Text('Save QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6741),
                  foregroundColor: Colors.white
                ),
                  )
            ],
          ),
        ),
      ),
    );
  }
}
