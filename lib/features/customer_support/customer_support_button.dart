import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomerSupportButton extends StatelessWidget {
  const CustomerSupportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 80,
      child: FloatingActionButton(
        onPressed: () {
          // 导航到客服页面
          context.push('/customer-support');
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
