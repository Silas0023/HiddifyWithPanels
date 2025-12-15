import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/features/panel/xboard/services/auth_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rocketController;

  @override
  void initState() {
    super.initState();
    _rocketController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _rocketController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    // 等待动画播放完成（2.5秒）
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // 检查用户状态并导航
    final hasSeenIntro = ref.read(Preferences.introCompleted);
    final isLoggedIn = ref.read(authProvider);

    if (!hasSeenIntro) {
      // 首次启动，跳转到介绍页
      if (mounted) const IntroRoute().go(context);
    } else if (!isLoggedIn) {
      // 已看过介绍，但未登录，跳转到登录页
      if (mounted) const LoginRoute().go(context);
    } else {
      // 已登录，跳转到主页
      if (mounted) const HomeRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      body: Stack(
        children: [
          // 背景装饰圆
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0EA5E9).withAlpha(isDark ? 30 : 20),
                    const Color(0xFF0EA5E9).withAlpha(0),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 1000.ms)
              .scale(begin: const Offset(0.8, 0.8), duration: 1500.ms),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0284C7).withAlpha(isDark ? 25 : 15),
                    const Color(0xFF0284C7).withAlpha(0),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 1000.ms)
              .scale(begin: const Offset(0.8, 0.8), duration: 1500.ms),

          // 主内容
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 火箭 Logo
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 外圈光晕
                    AnimatedBuilder(
                      animation: _rocketController,
                      builder: (context, child) {
                        return Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0EA5E9).withAlpha(
                                (30 + 20 * math.sin(_rocketController.value * 2 * math.pi)).toInt(),
                              ),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    // 内圈光晕
                    AnimatedBuilder(
                      animation: _rocketController,
                      builder: (context, child) {
                        return Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0EA5E9).withAlpha(
                                (40 + 30 * math.cos(_rocketController.value * 2 * math.pi)).toInt(),
                              ),
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    ),
                    // Logo 容器
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0EA5E9),
                            Color(0xFF0284C7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0EA5E9).withAlpha(80),
                            blurRadius: 40,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.rocket_launch_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 40),

                // 应用名称
                Text(
                  '小火箭',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    letterSpacing: 2,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 12),

                // 副标题
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withAlpha(isDark ? 30 : 20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '安全 · 高速 · 稳定',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7),
                      letterSpacing: 3,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 80),

                // 加载动画
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 外圈
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF0EA5E9).withAlpha(60),
                          ),
                        ),
                      ),
                      // 内圈
                      SizedBox(
                        width: 35,
                        height: 35,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0EA5E9),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 400.ms),
              ],
            ),
          ),

          // 底部文字
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              'Powered by Hiddify',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                letterSpacing: 1,
              ),
            ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
          ),
        ],
      ),
    );
  }
}
