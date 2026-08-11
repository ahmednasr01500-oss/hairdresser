import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../services/session.dart';
import '../widgets/brand.dart';
import 'address_form.dart';
import 'shell.dart';

/// شاشة الدخول: الاسم والرقم بس.
///
/// اتفقنا نبعد عن كود التحقق (OTP) عشان (١) رسايل Firebase محتاجة تفعيل
/// الفوترة وبتتكلّف على كل رسالة، و(٢) زباين محل الخضار أغلبهم مش هيستحملوا
/// خطوة زيادة. الرقم هنا وسيلة تواصل مش إثبات هوية.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'اكتب رقم موبايلك';
    if (!RegExp(r'^01[0125]\d{8}$').hasMatch(digits)) {
      return 'الرقم لازم يكون ١١ رقم ويبدأ بـ ٠١';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final ok = await Session.i.signIn(
      name: _name.text,
      phone: _phone.text.replaceAll(RegExp(r'\D'), ''),
    );

    if (!mounted) return;
    setState(() => _busy = false);

    // من غير هوية من Firebase مفيش طلب هيتبعت. بنوقّف هنا بدل ما نكمّل
    // ونسيب العميل يكتشف المشكلة وهو بيأكّد طلبه.
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('مقدرناش نكمّل دلوقتي. اتأكد من النت وجرّب تاني.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // أول مرة بنسأل عن العنوان على طول عشان الطلب بعد كده يبقى خطوة واحدة.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const AddressFormScreen(isOnboarding: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(child: BrandLogo(size: 150)),
                const SizedBox(height: 24),
                const Text(
                  'مرحبًا بك 🌿',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'سجّل الدخول لطلب أجود الخضروات والفاكهة الطازجة من مكانك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    height: 1.7,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                const _Label('الاسم'),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'مثال: أحمد محمد',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v ?? '').trim().length < 2
                      ? 'اكتب اسمك عشان نعرف نناديك'
                      : null,
                ),
                const SizedBox(height: 16),

                const _Label('رقم الموبايل'),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: const InputDecoration(
                    hintText: '01xxxxxxxxx',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: _validatePhone,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'هنستخدم الرقم ده عشان نتواصل معاك وقت التوصيل بس.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),

                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('يلا نبدأ'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const AppShell(),
                            ),
                          ),
                  child: const Text(
                    'اتفرّج على المنتجات الأول',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'بمتابعتك أنت توافق على شروط الاستخدام وسياسة الخصوصية',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
}
