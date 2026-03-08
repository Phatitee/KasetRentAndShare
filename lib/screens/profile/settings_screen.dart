import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tr('settings_title')),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // ─── Language ───
          _SectionHeader(title: l.tr('language')),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('🇹🇭  ไทย'),
                  value: 'th',
                  groupValue: localeProvider.locale,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (value) {
                    if (value != null) localeProvider.setLocale(value);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: const Text('🇺🇸  English'),
                  value: 'en',
                  groupValue: localeProvider.locale,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (value) {
                    if (value != null) localeProvider.setLocale(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── Notifications ───
          _SectionHeader(title: l.tr('notification_settings')),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l.tr('notification_rental')),
                  value: true,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (value) {
                    // TODO: persist notification preferences
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(l.tr('notification_chat')),
                  value: true,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (value) {
                    // TODO: persist notification preferences
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── App Info ───
          _SectionHeader(title: l.tr('app_info')),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              title: Text(l.tr('version')),
              trailing: Text(
                '1.0.0',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTeal,
            ),
      ),
    );
  }
}
