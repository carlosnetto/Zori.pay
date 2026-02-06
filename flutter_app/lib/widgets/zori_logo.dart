import 'package:flutter/material.dart';
import 'package:flutter_app/theme/app_colors.dart';

class ZoriLogo extends StatelessWidget {
  final double size;
  const ZoriLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.blue600,
            borderRadius: BorderRadius.circular(size * 0.25),
          ),
          alignment: Alignment.center,
          child: Text(
            'Z',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.625,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'zori.pay',
          style: TextStyle(
            fontSize: size * 0.75,
            fontWeight: FontWeight.w800,
            color: AppColors.blue600,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
