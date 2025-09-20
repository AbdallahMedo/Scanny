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
        Image.asset(
          'assets/images/onboard.jpg',
          height: 350,
          fit: BoxFit.fitWidth,
          width: double.infinity,
        ),
        const SizedBox(height: 50),

        // QR Icon (centered large icon)
        Image.asset(
          'assets/images/qr-code.png',
          height: 200,
          width: 200,
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
