import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:velour_app/l10n/app_localizations.dart';

import '../services/audio_handler.dart';
import '../services/app_settings.dart';
import '../services/velour_analytics.dart';
import '../services/firestore_service.dart';
import '../services/haptics_handler.dart';
import '../providers/game_state.dart';
import '../utils/responsive.dart';
import '../widgets/ui/dark_matte_overlay.dart';
import '../widgets/ui/universal_back_button.dart';
import '../widgets/ui/velour_snackbar.dart';
import '../utils/velour_release_links.dart';

Future<void> _openPrivacyPolicyUrl(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final String raw = VelourReleaseLinks.privacyPolicyUrl.trim();
  final Uri? uri = Uri.tryParse(raw);
  if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
    if (!context.mounted) return;
    showVelourSnackBar(
      context,
      l10n.settingsPrivacyPolicyLaunchFail,
      accent: const Color(0xFFFFD700),
      icon: Icons.link_off_rounded,
    );
    return;
  }
  final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted) return;
  if (!ok) {
    showVelourSnackBar(
      context,
      l10n.settingsPrivacyPolicyLaunchFail,
      accent: const Color(0xFFFFD700),
      icon: Icons.link_off_rounded,
    );
  }
}

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  static const Color _gold = Color(0xFFFFD700);
  static const Color _panel = Color(0xFF0A0C12);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      VelourAnalytics.logSettingsView(
        runInstanceId: context.read<GameState>().analyticsRunInstanceId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final double sH = Responsive.heightScale(context);
    final double sT = Responsive.textScale(context);
    final Color accent = SettingsView._gold;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0.10),
                  radius: 1.2,
                  colors: [Color(0xFF0B1020), Color(0xFF000000)],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: DarkMatteOverlay()),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        18,
                        (14 * sH).clamp(12.0, 20.0),
                        18,
                        (18 * sH).clamp(14.0, 22.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.settingsTitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w600,
                                  color: accent.withValues(alpha: 0.96),
                                  fontSize: (16 * sT).clamp(14.0, 19.0),
                                ),
                          ),
                          SizedBox(height: (18 * sH).clamp(14.0, 22.0)),
                          _SectionCard(
                            title: l10n.settingsSectionAudio,
                            accent: accent,
                            children: [
                              ValueListenableBuilder<bool>(
                                valueListenable: AudioHandler.instance.muted,
                                builder: (context, musicMuted, _) {
                                  return _SettingsSwitchTile(
                                    icon: Icons.volume_up_rounded,
                                    title: l10n.settingsMusicTitle,
                                    subtitle: musicMuted
                                        ? l10n.settingsMusicOff
                                        : l10n.settingsMusicOn,
                                    value: !musicMuted,
                                    accent: accent,
                                    onChanged: (v) =>
                                        AppSettings.instance.setMusicMuted(!v),
                                  );
                                },
                              ),
                              const _TileDivider(),
                              ValueListenableBuilder<bool>(
                                valueListenable: AudioHandler.instance.sfxMuted,
                                builder: (context, sfxMuted, _) {
                                  return _SettingsSwitchTile(
                                    icon: Icons.surround_sound_rounded,
                                    title: l10n.settingsSfxTitle,
                                    subtitle: sfxMuted
                                        ? l10n.settingsSfxOff
                                        : l10n.settingsSfxOn,
                                    value: !sfxMuted,
                                    accent: accent,
                                    onChanged: (v) =>
                                        AppSettings.instance.setSfxMuted(!v),
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 14 * sH),
                          _SectionCard(
                            title: l10n.settingsSectionHaptics,
                            accent: accent,
                            children: [
                              ValueListenableBuilder<bool>(
                                valueListenable:
                                    HapticsHandler.instance.enabled,
                                builder: (context, enabled, _) {
                                  return _SettingsSwitchTile(
                                    icon: Icons.vibration_rounded,
                                    title: l10n.settingsHapticsTitle,
                                    subtitle: enabled
                                        ? l10n.settingsHapticsOn
                                        : l10n.settingsHapticsOff,
                                    value: enabled,
                                    accent: accent,
                                    onChanged: (v) => AppSettings.instance
                                        .setHapticsEnabled(v),
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 14 * sH),
                          _SectionCard(
                            title: l10n.settingsSectionAccessibility,
                            accent: accent,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 4,
                                ),
                                child: Text(
                                  l10n.settingsAccessibilityBody,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        height: 1.45,
                                        letterSpacing: 0.4,
                                        color: Colors.white.withValues(
                                          alpha: 0.62,
                                        ),
                                        fontSize: (12.5 * sT).clamp(11.0, 14.5),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14 * sH),
                          _SectionCard(
                            title: l10n.settingsSectionLanguage,
                            accent: accent,
                            children: [
                              ValueListenableBuilder<AppLocalePreference>(
                                valueListenable:
                                    AppSettings.instance.localePreference,
                                builder: (context, pref, _) {
                                  return _LanguageTile(
                                    l10n: l10n,
                                    icon: Icons.language_rounded,
                                    accent: accent,
                                    value: pref,
                                    onChanged: (v) {
                                      if (v == null) return;
                                      AppSettings.instance.setLocalePreference(
                                        v,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 14 * sH),
                          _SectionCard(
                            title: l10n.settingsSectionInfos,
                            accent: accent,
                            children: [
                              _AsyncVersionInfoTile(
                                icon: Icons.info_outline_rounded,
                                title: l10n.settingsVersionLabel,
                                accent: accent,
                              ),
                              const _TileDivider(),
                              _ActionTile(
                                icon: Icons.badge_outlined,
                                title: l10n.settingsCopyPlayerIdTitle,
                                subtitle: l10n.settingsCopyPlayerIdSubtitle,
                                accent: accent,
                                onTap: () {
                                  unawaited(() async {
                                    await FirestoreService.instance
                                        .ensureAnonymousAuthReady();
                                    final String? uid =
                                        FirestoreService.instance.uid;
                                    if (!context.mounted) return;
                                    if (uid == null || uid.isEmpty) {
                                      showVelourSnackBar(
                                        context,
                                        l10n.settingsCopyPlayerIdFailed,
                                        accent: const Color(0xFFFFD700),
                                        icon: Icons.error_outline_rounded,
                                      );
                                      return;
                                    }
                                    await Clipboard.setData(
                                      ClipboardData(text: uid),
                                    );
                                    if (!context.mounted) return;
                                    showVelourSnackBar(
                                      context,
                                      l10n.settingsCopyPlayerIdSnack(uid),
                                      accent: const Color(0xFFFFD700),
                                      icon: Icons.copy_all_rounded,
                                    );
                                  }());
                                },
                              ),
                              const _TileDivider(),
                              _ActionTile(
                                icon: Icons.cloud_done_outlined,
                                title: l10n.settingsPingServerTitle,
                                subtitle: l10n.settingsPingServerSubtitle,
                                accent: accent,
                                onTap: () {
                                  unawaited(() async {
                                    final bool ok = await FirestoreService
                                        .instance
                                        .pingVelourHealth();
                                    if (!context.mounted) return;
                                    showVelourSnackBar(
                                      context,
                                      ok
                                          ? l10n.settingsPingServerOk
                                          : l10n.settingsPingServerFail,
                                      accent: ok
                                          ? const Color(0xFF00E5FF)
                                          : const Color(0xFFE49BFF),
                                      icon: ok
                                          ? Icons.cloud_done_rounded
                                          : Icons.cloud_off_rounded,
                                    );
                                  }());
                                },
                              ),
                              const _TileDivider(),
                              _ActionTile(
                                icon: Icons.copy_all_rounded,
                                title: l10n.settingsCopyDiagnosticsTitle,
                                subtitle: l10n.settingsCopyDiagnosticsSubtitle,
                                accent: accent,
                                onTap: () {
                                  unawaited(() async {
                                    final BuildContext safeContext = context;
                                    final PackageInfo pkg =
                                        await PackageInfo.fromPlatform();
                                    await FirestoreService.instance
                                        .ensureAnonymousAuthReady();
                                    final String uid =
                                        FirestoreService.instance.uid ?? '';
                                    final bool serverOk = await FirestoreService
                                        .instance
                                        .pingVelourHealth();
                                    if (!safeContext.mounted) return;

                                    final Locale loc = Localizations.localeOf(
                                      safeContext,
                                    );
                                    final String diag = [
                                      'Velour diagnostics',
                                      'version=${pkg.version}+${pkg.buildNumber}',
                                      'platform=${Theme.of(safeContext).platform}',
                                      'locale=${loc.toLanguageTag()}',
                                      'uid=${uid.isEmpty ? '(unavailable)' : uid}',
                                      'serverHealth=${serverOk ? 'ok' : 'fail'}',
                                    ].join('\n');

                                    await Clipboard.setData(
                                      ClipboardData(text: diag),
                                    );
                                    if (!safeContext.mounted) return;
                                    showVelourSnackBar(
                                      safeContext,
                                      l10n.settingsCopyDiagnosticsSnack,
                                      accent: const Color(0xFFFFD700),
                                      icon: Icons.copy_all_rounded,
                                    );
                                  }());
                                },
                              ),
                              if (VelourReleaseLinks.hasPrivacyPolicyUrl) ...[
                                const _TileDivider(),
                                _ActionTile(
                                  icon: Icons.privacy_tip_outlined,
                                  title: l10n.settingsPrivacyPolicyTitle,
                                  subtitle: l10n.settingsPrivacyPolicySubtitle,
                                  accent: accent,
                                  onTap: () {
                                    unawaited(
                                      _openPrivacyPolicyUrl(context, l10n),
                                    );
                                  },
                                ),
                              ],
                              const _TileDivider(),
                              _ActionTile(
                                icon: Icons.auto_awesome_rounded,
                                title: l10n.settingsCreditsTitle,
                                subtitle: l10n.settingsCreditsSubtitle,
                                accent: accent,
                                onTap: () => _showCredits(context, accent),
                              ),
                            ],
                          ),
                          if (kDebugMode) ...[
                            SizedBox(height: 14 * sH),
                            _SectionCard(
                              title: l10n.settingsSectionDebug,
                              accent: const Color(0xFFFF4D4D),
                              children: [
                                _ActionTile(
                                  icon: Icons.warning_amber_rounded,
                                  title: l10n.settingsResetTitle,
                                  subtitle: l10n.settingsResetSubtitle,
                                  accent: const Color(0xFFFF4D4D),
                                  onTap: () {
                                    unawaited(() async {
                                      await context
                                          .read<GameState>()
                                          .fullHardReset();
                                      if (!context.mounted) return;
                                      showVelourSnackBar(
                                        context,
                                        l10n.settingsResetSnack,
                                        accent: const Color(0xFFFF4D4D),
                                        icon: Icons.restart_alt_rounded,
                                      );
                                    }());
                                  },
                                ),
                                const _TileDivider(),
                                _ActionTile(
                                  icon: Icons.card_giftcard_rounded,
                                  title: l10n.settingsDebugResetWelcomeTitle,
                                  subtitle:
                                      l10n.settingsDebugResetWelcomeSubtitle,
                                  accent: const Color(0xFFFFD700),
                                  onTap: () {
                                    unawaited(() async {
                                      await context
                                          .read<GameState>()
                                          .debugResetFirstLaunchWelcome();
                                      if (!context.mounted) return;
                                      showVelourSnackBar(
                                        context,
                                        l10n.settingsDebugResetWelcomeSnack,
                                        accent: const Color(0xFFFFD700),
                                        icon: Icons.card_giftcard_rounded,
                                      );
                                    }());
                                  },
                                ),
                              ],
                            ),
                          ],
                          SizedBox(height: (10 * sH).clamp(8.0, 16.0)),
                          Text(
                            l10n.settingsFooterTagline,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  letterSpacing: 2.0,
                                  color: Colors.white.withValues(alpha: 0.30),
                                  fontSize: (10 * sT).clamp(9.0, 12.0),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(top: 6, left: 6, child: UniversalBackButton()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCredits(BuildContext context, Color accent) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppLocalizations dl10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          backgroundColor: SettingsView._panel.withValues(alpha: 0.96),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            dl10n.settingsCreditsDialogTitle,
            style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
              color: accent.withValues(alpha: 0.92),
            ),
          ),
          content: Text(
            dl10n.settingsCreditsBody,
            style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                dl10n.settingsClose,
                style: Theme.of(dialogContext).textTheme.labelLarge?.copyWith(
                  letterSpacing: 3,
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.accent,
    required this.children,
  });

  final String title;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final double sH = Responsive.heightScale(context);
    final double sT = Responsive.textScale(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0C12).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          (12 * sH).clamp(10.0, 16.0),
          (12 * sH).clamp(10.0, 16.0),
          (12 * sH).clamp(10.0, 16.0),
          (10 * sH).clamp(8.0, 14.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 4.2,
                fontWeight: FontWeight.w700,
                fontSize: (11 * sT).clamp(10.0, 13.0),
                color: accent.withValues(alpha: 0.82),
              ),
            ),
            SizedBox(height: (10 * sH).clamp(8.0, 14.0)),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: 0.06),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double sT = Responsive.textScale(context);
    return Row(
      children: [
        _TileIcon(icon: icon, accent: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  fontSize: (14 * sT).clamp(12.0, 16.0),
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 0.6,
                  fontSize: (12 * sT).clamp(11.0, 14.0),
                  color: Colors.white.withValues(alpha: 0.42),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: accent,
          activeTrackColor: accent.withValues(alpha: 0.35),
          inactiveThumbColor: Colors.white.withValues(alpha: 0.28),
          inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
        ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.l10n,
    required this.icon,
    required this.accent,
    required this.value,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final IconData icon;
  final Color accent;
  final AppLocalePreference value;
  final ValueChanged<AppLocalePreference?> onChanged;

  @override
  Widget build(BuildContext context) {
    final double sT = Responsive.textScale(context);
    return Row(
      children: [
        _TileIcon(icon: icon, accent: accent),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            l10n.settingsLanguageRowTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              fontSize: (14 * sT).clamp(12.0, 16.0),
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppLocalePreference>(
                isExpanded: true,
                value: value,
                onChanged: onChanged,
                dropdownColor: const Color(0xFF0A0C12),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  letterSpacing: 1.0,
                ),
                items: [
                  DropdownMenuItem(
                    value: AppLocalePreference.system,
                    child: Text(l10n.settingsLocaleSystem),
                  ),
                  DropdownMenuItem(
                    value: AppLocalePreference.en,
                    child: Text(l10n.settingsLocaleEnglish),
                  ),
                  DropdownMenuItem(
                    value: AppLocalePreference.fr,
                    child: Text(l10n.settingsLocaleFrench),
                  ),
                  DropdownMenuItem(
                    value: AppLocalePreference.de,
                    child: Text(l10n.settingsLocaleGerman),
                  ),
                  DropdownMenuItem(
                    value: AppLocalePreference.zh,
                    child: Text(l10n.settingsLocaleChinese),
                  ),
                  DropdownMenuItem(
                    value: AppLocalePreference.hi,
                    child: Text(l10n.settingsLocaleHindi),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<PackageInfo>? _cachedPackageInfoFuture;

Future<PackageInfo> _packageInfoFuture() =>
    _cachedPackageInfoFuture ??= PackageInfo.fromPlatform();

String _formatAppVersion(PackageInfo info) {
  final String build = info.buildNumber.trim();
  if (build.isEmpty || build == '0') {
    return info.version;
  }
  return '${info.version}+$build';
}

/// One-shot [PackageInfo.fromPlatform] for the settings row (cached).
class _AsyncVersionInfoTile extends StatelessWidget {
  const _AsyncVersionInfoTile({
    required this.icon,
    required this.title,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture(),
      builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
        final String value = snapshot.hasData
            ? _formatAppVersion(snapshot.data!)
            : snapshot.hasError
            ? '—'
            : '…';
        return _InfoTile(
          icon: icon,
          title: title,
          value: value,
          accent: accent,
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double sT = Responsive.textScale(context);
    return Row(
      children: [
        _TileIcon(icon: icon, accent: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              fontSize: (14 * sT).clamp(12.0, 16.0),
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            letterSpacing: 1.6,
            fontSize: (12 * sT).clamp(11.0, 14.0),
            color: Colors.white.withValues(alpha: 0.48),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double sT = Responsive.textScale(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        AudioHandler.instance.playMenuClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _TileIcon(icon: icon, accent: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      fontSize: (14 * sT).clamp(12.0, 16.0),
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 0.6,
                      fontSize: (12 * sT).clamp(11.0, 14.0),
                      color: Colors.white.withValues(alpha: 0.42),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Icon(icon, size: 18, color: accent.withValues(alpha: 0.82)),
    );
  }
}
