import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/oracle_pseudo.dart';
import '../l10n/app_localizations.dart';
import '../providers/game_state.dart';
import '../theme/theme_engine.dart';

class OracleNamingDialog extends StatefulWidget {
  const OracleNamingDialog({super.key});

  @override
  State<OracleNamingDialog> createState() => _OracleNamingDialogState();
}

class _OracleNamingDialogState extends State<OracleNamingDialog> {
  final TextEditingController _c = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String? _validate(String raw, AppLocalizations l10n) {
    final String v = raw.trim();
    if (v.isEmpty) return l10n.oracleNamingValidationRequired;
    if (v.length > 15) return l10n.oracleNamingValidationTooLong;
    if (!OraclePseudo.isValid(v)) {
      return l10n.oracleNamingValidationInvalidChars;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String raw = _c.text;
    final String? err = _validate(raw, l10n);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final bool sealed = await context.read<GameState>().updateOracleName(raw);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!sealed) {
      setState(() {
        _error = l10n.oracleNamingSaveError;
      });
      return;
    }
    Navigator.of(context, rootNavigator: true).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeEngine te = context.watch<ThemeEngine>();
    final Color neon = te.colorForId(5);
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.70),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0D12).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: neon.withValues(alpha: 0.12),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.oracleNamingDialogTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.w700,
                                    color: neon.withValues(alpha: 0.92),
                                  ),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.settingsClose,
                            onPressed: () {
                              context.read<GameState>().dismissNamingDialog();
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(false);
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.oracleNamingDialogBody,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          letterSpacing: 0.6,
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _c,
                        maxLength: 15,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: l10n.oracleNamingFieldHint,
                          hintStyle: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                letterSpacing: 2.0,
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                          errorText: _error,
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.35),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: neon.withValues(alpha: 0.55),
                              width: 1.2,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.65),
                          foregroundColor: neon.withValues(alpha: 0.95),
                          side: BorderSide(color: neon.withValues(alpha: 0.55)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 18,
                          ),
                        ),
                        child: Text(
                          l10n.oracleNamingSealButton,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                letterSpacing: 3.0,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
