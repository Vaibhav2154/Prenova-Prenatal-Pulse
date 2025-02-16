import 'package:flutter/material.dart';
import 'package:prenova/core/theme/app_pallete.dart';


import 'Body/baby_status_body.dart';

class BabyStatusPage extends StatelessWidget {
  const BabyStatusPage({super.key, required Null Function(dynamic context) builder});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor:  AppPallete.backgroundColor,
      body: BabyStatusBody(),
    );
  }
}