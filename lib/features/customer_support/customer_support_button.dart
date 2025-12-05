import 'package:flutter/material.dart';
import 'package:hiddify/features/customer_support/intercom_service.dart';

class CustomerSupportButton extends StatelessWidget {
  const CustomerSupportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 80,
      child: FloatingActionButton(
        onPressed: () {
          // 打开 Intercom 客服
          IntercomService.displayMessenger();
        },
        backgroundColor: const Color(0xFF0EA5E9),
        heroTag: 'customer_support_fab',
        child: const Icon(
          Icons.support_agent,
          color: Colors.white,
        ),
      ),
    );
  }
}
