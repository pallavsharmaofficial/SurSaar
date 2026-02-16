import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../core/theme/app_colors.dart';
import '../../repositories/profile_repository.dart';
import '../../widgets/section_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(
        repository: context.read<ProfileRepository>(),
      )..add(const ProfileLoadRequested()),
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

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
              SliverAppBar.large(
                title: Text(l10n.profile),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => context
                            .read<ProfileBloc>()
                            .add(const ProfilePhotoUpdated()),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: AppColors.primary,
                          backgroundImage: profile.photoPath != null
                              ? FileImage(File(profile.photoPath!))
                              : null,
                          child: profile.photoPath == null
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      SectionHeader(title: l10n.settings),
                      const SizedBox(height: 12),
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: l10n.notifications,
                        onTap: () {},
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideX(begin: 0.1, end: 0),
                      _SettingsTile(
                        icon: Icons.language,
                        title: l10n.language,
                        onTap: () {},
                      )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 400.ms)
                          .slideX(begin: 0.1, end: 0),
                      _SettingsTile(
                        icon: Icons.color_lens_outlined,
                        title: l10n.theme,
                        onTap: () {},
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideX(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                      SectionHeader(title: l10n.about),
                      const SizedBox(height: 12),
                      _SettingsTile(
                        icon: Icons.info_outline,
                        title: l10n.aboutApp,
                        onTap: () {},
                      )
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 400.ms)
                          .slideX(begin: 0.1, end: 0),
                      _SettingsTile(
                        icon: Icons.help_outline,
                        title: l10n.help,
                        onTap: () {},
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 400.ms)
                          .slideX(begin: 0.1, end: 0),
                      _SettingsTile(
                        icon: Icons.feedback_outlined,
                        title: l10n.sendFeedback,
                        onTap: () {},
                      )
                          .animate()
                          .fadeIn(delay: 450.ms, duration: 400.ms)
                          .slideX(begin: 0.1, end: 0),
                      const SizedBox(height: 32),
                      Text(
                        '${l10n.appTitle} v1.0.0',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textOnDark,
                            ),
                      ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
