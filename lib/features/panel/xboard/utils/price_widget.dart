import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';


class PriceWidget extends StatelessWidget {
  final Plan plan;
  final String priceLabel;
  final String currency;

  const PriceWidget({
    super.key,
    required this.plan,
    required this.priceLabel,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$priceLabel ${plan.currentPrice} $currency',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
    );
  }
}
