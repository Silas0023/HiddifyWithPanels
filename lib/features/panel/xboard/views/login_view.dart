// views/login_view.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/domain_check_viewmodel.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/login_viewmodel/login_viewmodel.dart';
import 'package:hiddify/features/panel/xboard/views/domain_check_indicator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final loginViewModelProvider = ChangeNotifierProvider((ref) {
  return LoginViewModel(
    authService: AuthService(),
  );
});

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  // 只保留手机号登录模式
  int _countdown = 0; // 验证码倒计时
  bool _isSendingCode = false; // 发送验证码的 loading 状态
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;


  // Typing animation
  final List<String> _features = [
    '一键起飞，畅游全球',
    '火箭加速，秒连世界',
    '安全护航，隐私无忧',
    '多端同步，随时起航',
    '全球节点，极速体验',
  ];
  int _currentFeatureIndex = 0;
  String _displayedText = '';
  late AnimationController _typingController;
  late AnimationController _cursorController;
  late Animation<double> _cursorAnimation;

  @override
  void initState() {
    super.initState();

    // 清空输入框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginViewModel = ref.read(loginViewModelProvider);
      loginViewModel.usernameController.clear();
      loginViewModel.passwordController.clear();
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();

    // Typing animation controller
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    // Cursor blinking animation
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
    _cursorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_cursorController);

    _startTypingAnimation();
  }

  Future<void> _startTypingAnimation() async {
    while (mounted) {
      final currentText = _features[_currentFeatureIndex];

      // Type forward
      for (int i = 0; i <= currentText.length; i++) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _displayedText = currentText.substring(0, i);
          });
        }
      }

      // Pause
      await Future.delayed(const Duration(milliseconds: 2000));

      // Type backward
      for (int i = currentText.length; i >= 0; i--) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          setState(() {
            _displayedText = currentText.substring(0, i);
          });
        }
      }

      // Move to next feature
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _currentFeatureIndex = (_currentFeatureIndex + 1) % _features.length;
        });
      }
    }
  }

  // 发送验证码
  Future<void> _sendVerificationCode(LoginViewModel loginViewModel) async {
    final phone = loginViewModel.usernameController.text.trim();
    if (phone.isEmpty) {
      _showErrorSnackbar(context, '请输入手机号', const Color(0xFFEF4444));
      return;
    }

    // 设置 loading 状态
    setState(() {
      _isSendingCode = true;
    });

    try {
      // 调用发送验证码API
      final result = await loginViewModel.sendSmsCode(phone);

      // 取消 loading 状态 - 在获取到响应后立即取消
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }

      // 检查返回状态 - 检查 code 或 status 字段
      if (result['code'] == 200 || result['status'] == 200) {
        // 开始倒计时
        setState(() {
          _countdown = 60;
        });

        _showErrorSnackbar(context, '验证码已发送', const Color(0xFF10B981));

        // 倒计时
        for (int i = 60; i > 0; i--) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            setState(() {
              _countdown = i - 1;
            });
          }
        }
      } else {
        // API返回失败
        _showErrorSnackbar(
          context,
          result['message']?.toString() ?? '发送验证码失败',
          const Color(0xFFEF4444),
        );
      }
    } catch (e) {
      // 捕获异常
      _showErrorSnackbar(context, '发送验证码失败: $e', const Color(0xFFEF4444));
      // 发生异常时取消 loading 状态
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _typingController.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginViewModel = ref.watch(loginViewModelProvider);
    final t = ref.watch(translationsProvider);
    final domainCheckViewModel = ref.watch(domainCheckViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: DomainCheckIndicator(),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: Container(
          color: Colors.white,
          child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 900;

            if (isWideScreen) {
              // Wide screen: left-right layout
              return Row(
                children: [
                  // Left side - Product introduction with typing animation
                  Expanded(
                    flex: 5,
                    child: _buildLeftPanel(context, constraints),
                  ),
                  // Right side - Login form
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: _buildGlassCard(
                                context,
                                loginViewModel,
                                t,
                                domainCheckViewModel,
                                constraints,
                                isDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Narrow screen: 简洁布局，无外层容器
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildMobileLoginForm(
                        context,
                        loginViewModel,
                        t,
                        domainCheckViewModel,
                        constraints,
                        isDark,
                      ),
                    ),
                  ),
                ),
              );
            }
          },
        ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context, BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.all(64.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App logo and name
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0EA5E9),
                      Color(0xFF0284C7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                '小火箭',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 64),
          // Main title
          const Text(
            '一键起飞，畅游无界网络',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          // Subtitle
          Text(
            '小火箭为您保驾护航',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          // Typing animation
          Row(
            children: [
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF0EA5E9),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _displayedText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0EA5E9),
                    height: 1.4,
                  ),
                ),
              ),
              // Blinking cursor
              FadeTransition(
                opacity: _cursorAnimation,
                child: Container(
                  width: 2,
                  height: 28,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 64),
          // Feature list
          _buildFeatureItem(Icons.rocket_launch_rounded, '火箭般的连接速度'),
          const SizedBox(height: 20),
          _buildFeatureItem(Icons.shield_rounded, '军事级加密保护'),
          const SizedBox(height: 20),
          _buildFeatureItem(Icons.devices_rounded, '全平台无缝体验'),
          const SizedBox(height: 20),
          _buildFeatureItem(Icons.public_rounded, '遍布全球的节点'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0EA5E9),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // 手机端简洁登录表单
  Widget _buildMobileLoginForm(
    BuildContext context,
    LoginViewModel loginViewModel,
    Translations t,
    DomainCheckViewModel domainCheckViewModel,
    BoxConstraints constraints,
    bool isDark,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          // Logo 和标题
          Center(
            child: Column(
              children: [
                // 火箭图标
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0EA5E9),
                        Color(0xFF0284C7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withAlpha(77),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '小火箭',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '安全 · 高速 · 稳定',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          // 手机号输入
          _buildModernPhoneField(loginViewModel),
          const SizedBox(height: 16),
          // 验证码输入
          _buildModernCodeField(loginViewModel),
          const SizedBox(height: 12),
          // 提示文字
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '未注册的手机号将自动创建账号',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // 登录按钮
          _buildModernLoginButton(loginViewModel, domainCheckViewModel, t),
          const SizedBox(height: 40),
          // 底部装饰
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '安全登录',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 1,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 现代风格手机号输入框
  Widget _buildModernPhoneField(LoginViewModel loginViewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: loginViewModel.usernameController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A2E),
          letterSpacing: 1,
        ),
        decoration: InputDecoration(
          hintText: '请输入手机号',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: Icon(
            Icons.phone_iphone_rounded,
            color: Colors.grey.shade400,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '请输入手机号';
          }
          if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
            return '请输入有效的手机号';
          }
          return null;
        },
      ),
    );
  }

  // 现代风格验证码输入框
  Widget _buildModernCodeField(LoginViewModel loginViewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: loginViewModel.passwordController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                hintText: '验证码',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 0,
                ),
                prefixIcon: Icon(
                  Icons.verified_rounded,
                  color: Colors.grey.shade400,
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入验证码';
                }
                if (value.length != 6) {
                  return '请输入6位验证码';
                }
                return null;
              },
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.shade300,
          ),
          _isSendingCode
              ? const SizedBox(
                  width: 100,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _countdown > 0 ? null : () => _sendVerificationCode(loginViewModel),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0EA5E9),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(
                    _countdown > 0 ? '${_countdown}s' : '获取验证码',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _countdown > 0 ? Colors.grey.shade400 : const Color(0xFF0EA5E9),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // 现代风格登录按钮
  Widget _buildModernLoginButton(
    LoginViewModel loginViewModel,
    DomainCheckViewModel domainCheckViewModel,
    Translations t,
  ) {
    final isEnabled = domainCheckViewModel.isSuccess && !loginViewModel.isLoading;

    return GestureDetector(
      onTap: isEnabled
          ? () async {
              if (!_formKey.currentState!.validate()) return;

              try {
                final phone = loginViewModel.usernameController.text.trim();
                final code = loginViewModel.passwordController.text.trim();
                await loginViewModel.loginWithPhone(phone, code, context, ref);

                if (context.mounted) {
                  context.go('/');
                }
              } catch (e) {
                _showErrorSnackbar(context, '登录失败: $e', const Color(0xFFEF4444));
              }
            }
          : null,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF0EA5E9),
                    Color(0xFF0284C7),
                  ],
                )
              : null,
          color: isEnabled ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withAlpha(102),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: loginViewModel.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  isEnabled ? '登 录' : '连接中...',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
        ),
      ),
    );
  }

  // 宽屏版登录卡片（带容器）
  Widget _buildGlassCard(
    BuildContext context,
    LoginViewModel loginViewModel,
    Translations t,
    DomainCheckViewModel domainCheckViewModel,
    BoxConstraints constraints,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withOpacity(0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.08),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, t, constraints, isDark),
            const SizedBox(height: 32),
            _buildPhoneField(context, loginViewModel, isDark),
            const SizedBox(height: 24),
            _buildVerificationCodeField(context, loginViewModel, isDark),
            const SizedBox(height: 36),
            _buildLoginButton(
              context,
              loginViewModel,
              domainCheckViewModel,
              t,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  // 手机号输入框
  Widget _buildPhoneField(
    BuildContext context,
    LoginViewModel loginViewModel,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: loginViewModel.usernameController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            labelText: '手机号',
            labelStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Icon(
              Icons.phone_android_outlined,
              color: Color(0xFF0EA5E9),
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF0EA5E9),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            errorStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w400,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入手机号';
            }
            if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
              return '请输入有效的手机号';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: const Color(0xFF0EA5E9).withOpacity(0.8),
              ),
              const SizedBox(width: 6),
              Text(
                '如果手机号未注册将会自动注册',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF64748B).withOpacity(0.9),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 验证码输入框
  Widget _buildVerificationCodeField(
    BuildContext context,
    LoginViewModel loginViewModel,
    bool isDark,
  ) {
    return TextFormField(
      controller: loginViewModel.passwordController,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: '验证码',
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.sms_outlined,
          color: Color(0xFF0EA5E9),
          size: 20,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _isSendingCode
              ? const SizedBox(
                  width: 80,
                  height: 36,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _countdown > 0
                      ? null
                      : () => _sendVerificationCode(loginViewModel),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0EA5E9),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(80, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _countdown > 0 ? '$_countdown秒' : '获取验证码',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF0EA5E9),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        errorStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFFEF4444),
          fontWeight: FontWeight.w400,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入验证码';
        }
        if (value.length != 6) {
          return '请输入6位验证码';
        }
        return null;
      },
    );
  }

  Widget _buildHeader(BuildContext context, Translations t, BoxConstraints constraints, bool isDark) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0EA5E9),
                Color(0xFF0284C7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0EA5E9).withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.rocket_launch_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '欢迎使用小火箭',
          style: TextStyle(
            fontSize: constraints.maxWidth > 600 ? 28 : 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.3,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginButton(
    BuildContext context,
    LoginViewModel loginViewModel,
    DomainCheckViewModel domainCheckViewModel,
    Translations t,
    bool isDark,
  ) {
    return Container(
      height: 54,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: domainCheckViewModel.isSuccess
            ? const LinearGradient(
                colors: [
                  Color(0xFF0EA5E9),
                  Color(0xFF0284C7),
                ],
              )
            : null,
        color: domainCheckViewModel.isSuccess ? null : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
        boxShadow: domainCheckViewModel.isSuccess
            ? [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withOpacity(0.35),
                  blurRadius: 24,
                  spreadRadius: -2,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: loginViewModel.isLoading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : ElevatedButton(
              onPressed: domainCheckViewModel.isSuccess
                  ? () async {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      try {
                        // 手机号验证码登录
                        final phone = loginViewModel.usernameController.text.trim();
                        final code = loginViewModel.passwordController.text.trim();
                        await loginViewModel.loginWithPhone(phone, code, context, ref);

                        if (context.mounted) {
                          context.go('/');
                        }
                      } catch (e) {
                        _showErrorSnackbar(context, "${t.login.loginErr}: $e", const Color(0xFFFF4757));
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                t.login.loginButton,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
