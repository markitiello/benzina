import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';
import '../../state/providers.dart';

enum _Filter {
  all('Tutte'),
  prices('Prezzi'),
  app('App');

  const _Filter(this.label);
  final String label;
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final all = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);
    final visible = all.where(
      (n) => switch (_filter) {
        _Filter.all => true,
        _Filter.prices => n.isPriceAlert,
        _Filter.app => !n.isPriceAlert,
      },
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final groups = <String, List<AppNotification>>{};
    for (final n in visible) {
      final age = today
          .difference(DateTime(n.time.year, n.time.month, n.time.day))
          .inDays;
      final group = age == 0
          ? 'Oggi'
          : age < 7
          ? 'Questa settimana'
          : 'Precedenti';
      groups.putIfAbsent(group, () => []).add(n);
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: unread == 0
                ? null
                : () => ref.read(notificationsProvider.notifier).markAllRead(),
            child: Text(
              'Segna tutte come lette',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: unread == 0 ? c.muted : c.cheap,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            'Notifiche',
            style: displayStyle(
              fontSize: 30,
              letterSpacing: -0.5,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedTabs<_Filter>(
            values: _Filter.values,
            selected: _filter,
            labelOf: (f) => f.label,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 8),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                'Nessuna notifica.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted),
              ),
            ),
          for (final entry in groups.entries) ...[
            SectionLabel(entry.key),
            for (final n in entry.value) ...[
              _NotificationTile(notification: n),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => context.push('/impostazioni'),
              child: Text(
                'Gestisci le notifiche',
                style: TextStyle(fontWeight: FontWeight.w700, color: c.cheap),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final n = notification;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, bg, fg) = switch (n.kind) {
      NotificationKind.trendDown => (
        Icons.trending_down_rounded,
        c.cheapChipBg,
        c.cheapChipFg,
      ),
      NotificationKind.trendUp => (
        Icons.trending_up_rounded,
        isDark ? const Color(0xFF3A2412) : const Color(0xFFFBE7D4),
        isDark ? const Color(0xFFF5B98A) : const Color(0xFF7A3905),
      ),
      NotificationKind.appUpdate => (
        Icons.download_rounded,
        isDark ? c.surfaceMuted : c.ground,
        c.ink,
      ),
    };

    void open() {
      ref.read(notificationsProvider.notifier).markRead(n.id);
      switch (n.kind) {
        case NotificationKind.trendUp || NotificationKind.trendDown:
          context.go('/andamento');
        case NotificationKind.appUpdate:
          context.push('/impostazioni');
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: open,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: bg,
            foregroundColor: fg,
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: n.read
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatNotificationTime(n.time),
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  n.body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: n.read ? c.muted : c.ink,
                  ),
                ),
              ],
            ),
          ),
          if (!n.read)
            Semantics(
              label: 'non letta',
              child: Container(
                margin: const EdgeInsets.only(left: 8, top: 6),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? c.amber : c.priceyFill,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
