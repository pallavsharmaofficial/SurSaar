import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_settings.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../widgets/section_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProfileBloc(repository: context.read<ProfileRepository>())
            ..add(const ProfileLoadRequested()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  UserSettings _settings = const UserSettings();

  @override
  void initState() {
    super.initState();
    context.read<SettingsRepository>().getSettings().then((value) {
      if (mounted) setState(() => _settings = value);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _updateSettings(UserSettings value) async {
    setState(() => _settings = value);
    await context.read<SettingsRepository>().saveSettings(value);
  }

  ImageProvider? _photo(String? data) {
    if (data == null || !data.startsWith('data:')) return null;
    final comma = data.indexOf(',');
    if (comma < 0) return null;
    try {
      return MemoryImage(base64Decode(data.substring(comma + 1)));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final profile = state.profile;
          if (_nameController.text != profile.name) {
            _nameController.text = profile.name;
          }
          if (_bioController.text != profile.bio) {
            _bioController.text = profile.bio;
          }

          return CustomScrollView(
            slivers: <Widget>[
              SliverAppBar.large(title: Text(l10n.profile)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      GestureDetector(
                            onTap: () => context.read<ProfileBloc>().add(
                              const ProfilePhotoUpdated(),
                            ),
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: AppColors.primary,
                              backgroundImage: _photo(profile.photoData),
                              child: profile.photoData == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColors.surfaceLight,
                                    )
                                  : null,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 8),
                      Text(
                        l10n.changePhoto,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(title: l10n.profileDetails),
                      const SizedBox(height: 12),
                      _ProfileField(
                        label: l10n.nameLabel,
                        controller: _nameController,
                      ),
                      const SizedBox(height: 12),
                      _ProfileField(
                        label: l10n.bioLabel,
                        controller: _bioController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.read<ProfileBloc>().add(
                          ProfileSaved(
                            name: _nameController.text.trim(),
                            bio: _bioController.text.trim(),
                          ),
                        ),
                        icon: const Icon(Icons.save),
                        label: Text(l10n.saveProfile),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surfaceLight,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(title: l10n.teacherSettings),
                      const SizedBox(height: 8),
                      _SettingSwitch(
                        icon: Icons.back_hand_outlined,
                        title: l10n.leftHanded,
                        value: _settings.leftHanded,
                        onChanged: (v) =>
                            _updateSettings(_settings.copyWith(leftHanded: v)),
                      ),
                      _SettingSwitch(
                        icon: Icons.flip,
                        title: l10n.mirrorCamera,
                        value: _settings.mirrorCamera,
                        onChanged: (v) => _updateSettings(
                          _settings.copyWith(mirrorCamera: v),
                        ),
                      ),
                      _SettingSwitch(
                        icon: Icons.gesture,
                        title: l10n.showHandOverlay,
                        value: _settings.showHandOverlay,
                        onChanged: (v) => _updateSettings(
                          _settings.copyWith(showHandOverlay: v),
                        ),
                      ),
                      _SettingSwitch(
                        icon: Icons.timer_outlined,
                        title: l10n.metronome,
                        value: _settings.metronomeEnabled,
                        onChanged: (v) => _updateSettings(
                          _settings.copyWith(metronomeEnabled: v),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.speed),
                        title: Text(
                          '${l10n.defaultTempo}: ${_settings.defaultBpm} BPM',
                        ),
                        subtitle: Slider(
                          value: _settings.defaultBpm.toDouble(),
                          min: 40,
                          max: 160,
                          divisions: 120,
                          onChanged: (v) => setState(
                            () => _settings = _settings.copyWith(
                              defaultBpm: v.round(),
                            ),
                          ),
                          onChangeEnd: (v) => _updateSettings(
                            _settings.copyWith(defaultBpm: v.round()),
                          ),
                        ),
                        tileColor: AppColors.surfaceLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(title: l10n.about),
                      const SizedBox(height: 8),
                      _LinkTile(
                        icon: Icons.language,
                        title: l10n.website,
                        url: AppConstants.websiteUrl,
                      ),
                      _LinkTile(
                        icon: Icons.code,
                        title: l10n.sourceCode,
                        url: AppConstants.repositoryUrl,
                      ),
                      _LinkTile(
                        icon: Icons.feedback_outlined,
                        title: l10n.sendFeedback,
                        url: AppConstants.feedbackUrl,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.privacyNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnDark.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.appTitle} v${AppConstants.version}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textOnLight),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textOnLight),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(title),
        value: value,
        onChanged: onChanged,
        tileColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.title, required this.url});

  final IconData icon;
  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        tileColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
