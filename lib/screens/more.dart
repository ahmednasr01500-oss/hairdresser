import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/catalog.dart';
import '../services/session.dart';
import '../widgets/brand.dart';
import 'address_form.dart';
import 'login.dart';
import 'splash.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListenableBuilder(
        listenable: Listenable.merge([Session.i, Catalog.i]),
        builder: (context, _) {
          final s = Session.i;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              _ProfileCard(
                name: s.name,
                phone: s.phone,
                loggedIn: s.isLoggedIn,
              ),
              const SizedBox(height: 16),

              _Group(
                title: 'عناويني',
                children: [
                  ...s.addresses.map(
                    (a) => _AddressRow(
                      address: a,
                      selected: s.selectedAddress?.id == a.id,
                    ),
                  ),
                  _Row(
                    icon: Icons.add_location_alt_outlined,
                    label: 'إضافة عنوان جديد',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddressFormScreen(),
                      ),
                    ),
                  ),
                ],
              ),

              _Group(
                title: 'تواصل معانا',
                children: [
                  _Row(
                    icon: Icons.phone_outlined,
                    label: 'اتصل بينا',
                    trailing: Shop.phoneOrders,
                    onTap: () => _open(context, 'tel:${Shop.phoneOrders}'),
                  ),
                  _Row(
                    icon: Icons.chat_bubble_outline,
                    label: 'واتساب',
                    trailing: Shop.phoneOrders,
                    onTap: () =>
                        _open(context, 'https://wa.me/${Shop.whatsapp}'),
                  ),
                  _Row(
                    icon: Icons.campaign_outlined,
                    label: 'قناة أخضر على واتساب',
                    onTap: () => _open(context, Shop.whatsappChannel),
                  ),
                  _Row(
                    icon: Icons.location_on_outlined,
                    label: 'عنوان المحل',
                    subtitle: Shop.address,
                    onTap: () => _open(
                      context,
                      'https://www.google.com/maps/search/'
                      '?api=1&query=${Uri.encodeComponent(Shop.address)}',
                    ),
                  ),
                  _Row(
                    icon: Icons.access_time,
                    label: 'مواعيد العمل',
                    subtitle: Catalog.i.settings.workingHours,
                  ),
                ],
              ),

              _Group(
                title: 'عن التطبيق',
                children: [
                  _Row(
                    icon: Icons.info_outline,
                    label: 'عن ${Shop.name}',
                    subtitle: Shop.slogan,
                  ),
                  if (s.isLoggedIn)
                    _Row(
                      icon: Icons.logout,
                      label: 'تسجيل الخروج',
                      color: AppColors.danger,
                      onTap: () => _confirmSignOut(context),
                    ),
                ],
              ),

              const SizedBox(height: 24),
              const Center(child: BrandLogo(size: 90, showTagline: false)),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'الإصدار ١.٠.٠',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مقدرناش نفتح الرابط ده')),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج؟'),
        content: const Text('هتحتاج تدخل اسمك ورقمك تاني عشان تطلب.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('رجوع'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;
    await Session.i.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.phone,
    required this.loggedIn,
  });

  final String name;
  final String phone;
  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: AppShape.radius,
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.leaf],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              name.isEmpty ? '👤' : name.characters.first,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loggedIn ? (name.isEmpty ? 'عميلنا العزيز' : name) : 'زائر',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loggedIn ? phone : 'سجّل الدخول عشان تطلب',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (loggedIn)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () => _editProfile(context),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              style: TextButton.styleFrom(backgroundColor: Colors.white),
              child: const Text(
                'دخول',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final nameCtrl = TextEditingController(text: name);
    final phoneCtrl = TextEditingController(text: phone);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل بياناتي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(hintText: 'الاسم'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(hintText: 'رقم الموبايل'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await Session.i.updateProfile(
        name: nameCtrl.text,
        phone: phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
      );
    }
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
        Container(
          decoration: AppShape.cardDeco,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: color ?? AppColors.text,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.6,
              ),
            ),
      trailing: trailing == null
          ? (onTap == null
              ? null
              : const Icon(Icons.chevron_left,
                  color: AppColors.muted, size: 20))
          : Text(
              trailing!,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.address, required this.selected});

  final Address address;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Session.i.selectAddress(address.id),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? AppColors.primary : AppColors.muted,
        size: 22,
      ),
      title: Text(
        address.label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        address.oneLine,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          height: 1.6,
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.muted, size: 20),
        onSelected: (v) async {
          if (v == 'edit') {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddressFormScreen(existing: address),
              ),
            );
          } else if (v == 'delete') {
            await Session.i.deleteAddress(address.id);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('تعديل')),
          PopupMenuItem(
            value: 'delete',
            child: Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
