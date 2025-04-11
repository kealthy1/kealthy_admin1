import 'package:flutter/material.dart';
import 'package:kealthy_admin/view/homepage.dart';
import 'package:pinput/pinput.dart';

class LoginPage extends StatelessWidget {
  final String correctOtp = "1520";
  final pinController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 60,
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: const Text('Kealthy - Admin',style: TextStyle(color: Colors.white),),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Enter Pin", style: TextStyle(fontSize: 22)),
          const SizedBox(height: 20),
          Center(
            child: Pinput(
              controller: pinController,
              length: 4,
              defaultPinTheme: defaultPinTheme,
              onCompleted: (pin) {
                if (pin == correctOtp) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const Homepage()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid OTP, try again.")));
                  pinController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}