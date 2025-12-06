import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../bloc/student_bloc.dart';
import '../../bloc/student_event.dart';
import '../../bloc/student_state.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _processQRCode(String qrData) {
    context.read<StudentBloc>().add(CheckInWithQR(qrData: qrData));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: BlocListener<StudentBloc, StudentState>(
        listener: (context, state) {
          if (state is CheckInSuccess) {
            controller.stop();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 32),
                    SizedBox(width: 12),
                    Text('Success!'),
                  ],
                ),
                content: Text(state.message),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Done'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        isProcessing = false;
                      });
                      controller.start();
                    },
                    child: const Text('Scan Another'),
                  ),
                ],
              ),
            );
          } else if (state is StudentError) {
            setState(() {
              isProcessing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      isProcessing = false;
                    });
                  },
                ),
              ),
            );
          }
        },
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: MobileScanner(
                controller: controller,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (!isProcessing && barcodes.isNotEmpty) {
                    final String? code = barcodes.first.rawValue;
                    if (code != null) {
                      setState(() {
                        isProcessing = true;
                      });
                      _processQRCode(code);
                    }
                  }
                },
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isProcessing)
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Processing check-in...'),
                        ],
                      )
                    else
                      const Column(
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 48,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Position the QR code within the frame',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The QR code will be scanned automatically',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
