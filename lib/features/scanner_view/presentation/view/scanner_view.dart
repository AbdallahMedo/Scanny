import 'package:flutter/material.dart';
import 'package:test_scanner/features/scanner_view/presentation/view/scanner_page.dart';

class ScannerView extends StatelessWidget {
  const ScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white, body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Top illustration (replace with your own image)
        Image.asset(
          'assets/images/scan.jpg',
          // Use the illustrated image similar to what you uploaded
          height: 400,
          fit: BoxFit.fitWidth, // Ensures image stretches to fill width
          width: double.infinity,
        ),
        const SizedBox(height: 50),

        // QR Icon (centered large icon)
        Image.asset(
          'assets/images/qr-code-scan.png', // Replace with your own QR icon
          height: 250,
          width: 250,
        ),
        Spacer(),
        // Scan Button
        SizedBox(
          width: 200,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScannerPage()),
              );
              // Your scan logic here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Scan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Spacer(),
      ],
    );
  }
}
