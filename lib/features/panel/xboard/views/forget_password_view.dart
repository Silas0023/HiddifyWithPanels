// views/forget_password_view.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/login_viewmodel/forget_password_viewmodel.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final forgetPasswordViewModelProvider = ChangeNotifierProvider((ref) {
  return ForgetPasswordViewModel(
    authService: AuthService(),
  );
});

class ForgetPasswordPage extends ConsumerStatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends ConsumerState<ForgetPasswordPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(forgetPasswordViewModelProvider);
    final t = ref.watch(translationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFEFF6FF),
              const Color(0xFFE0F2FE),
              Colors.white.withOpacity(0.95),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildGlassCard(context, viewModel, t, isDark),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(
    BuildContext context,
    ForgetPasswordViewModel viewModel,
    Translations t,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, t),
            const SizedBox(height: 36),
            _buildEmailField(context, viewModel, t),
            const SizedBox(height: 24),
            _buildPasswordField(context, viewModel, t),
            const SizedBox(height: 24),
            _buildVerificationCodeField(context, viewModel, t),
            const SizedBox(height: 36),
            _buildResetButton(context, viewModel, t),
            const SizedBox(height: 24),
            _buildLoginLink(context, t),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Translations t) {
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
            Icons.lock_reset_outlined,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          t.forgetPassword.pageTitle,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          '请输入您的邮箱以重置密码',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField(
    BuildContext context,
    ForgetPasswordViewModel viewModel,
    Translations t,
  ) {
    return TextFormField(
      controller: viewModel.emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: t.forgetPassword.email,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.email_outlined,
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
        if (value == null || value.isEmpty) {
          return t.forgetPassword.emailEmptyError;
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return '请输入有效的邮箱地址';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(
    BuildContext context,
    ForgetPasswordViewModel viewModel,
    Translations t,
  ) {
    return TextFormField(
      controller: viewModel.passwordController,
      obscureText: viewModel.obscurePassword,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: t.forgetPassword.newPassword,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF0EA5E9),
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            viewModel.obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF64748B),
            size: 20,
          ),
          onPressed: viewModel.togglePasswordVisibility,
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
        if (value == null || value.isEmpty) {
          return t.forgetPassword.passwordEmptyError;
        }
        if (value.length < 6) {
          return '密码长度至少6位';
        }
        return null;
      },
    );
  }

  Widget _buildVerificationCodeField(
    BuildContext context,
    ForgetPasswordViewModel viewModel,
    Translations t,
  ) {
    return TextFormField(
      controller: viewModel.emailCodeController,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: t.forgetPassword.verificationCode,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.verified_user_outlined,
          color: Color(0xFF0EA5E9),
          size: 20,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: viewModel.isCountingDown
              ? Center(
                  widthFactor: 1,
                  child: Text(
                    '${viewModel.countdownTime}秒',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: viewModel.isCountingDown
                      ? null
                      : () {
                          final email = viewModel.emailController.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('请输入邮箱'),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('请输入有效的邮箱地址'),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }
                          viewModel.sendVerificationCode();
                        },
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
                    t.forgetPassword.sendCode,
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
        if (value == null || value.isEmpty) {
          return t.forgetPassword.verificationCodeEmptyError;
        }
        return null;
      },
    );
  }

  Widget _buildResetButton(
    BuildContext context,
    ForgetPasswordViewModel viewModel,
    Translations t,
  ) {
    return Container(
      height: 54,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0EA5E9),
            Color(0xFF0284C7),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.35),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: viewModel.isLoading
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
              onPressed: () => viewModel.resetPassword(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                t.forgetPassword.resetPassword,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
    );
  }

  Widget _buildLoginLink(BuildContext context, Translations t) {
    return Center(
      child: TextButton(
        onPressed: () => context.go('/login'),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0EA5E9),
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 36),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '记起密码了? ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              '返回登录',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
