import 'package:flutter/material.dart';
import 'package:flutter_app/theme/app_colors.dart';

class CurrencyInfo {
  final String code;
  final String name;
  final String balance;
  final Color color;
  final IconData icon;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.balance,
    required this.color,
    required this.icon,
  });
}

const currencyMeta = <String, ({String name, Color color, IconData icon})>{
  'POL': (name: 'Polygon', color: AppColors.purple600, icon: Icons.hexagon_outlined),
  'USDC': (name: 'Digital Dollar', color: AppColors.blue600, icon: Icons.attach_money),
  'USDT': (name: 'Tether', color: AppColors.green500, icon: Icons.monetization_on_outlined),
  'BRL1': (name: 'Zori Real', color: AppColors.amber500, icon: Icons.currency_exchange),
};
