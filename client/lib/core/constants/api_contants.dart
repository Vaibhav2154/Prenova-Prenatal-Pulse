
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiContants {

    // static const baseUrl = 'http://10.0.2.2:5003'; // for emulator
    // static const baseUrl = 'http://10.0.2.2:8000'; // for emulatorfastapi
    // static const baseUrl = 'http://172.26.46.198:5000'; // for phone2222/
    // static const baseUrl = 'http://172.26.46.198:8000'; // for phone2222 fastapi

  static String get baseUrl => dotenv.env['BACKEND_URL'] ?? '';
  
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }
}
