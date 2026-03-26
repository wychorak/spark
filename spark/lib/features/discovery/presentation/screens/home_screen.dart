import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:spark/core/constants/app_colors.dart';
import 'package:spark/shared/widgets/spark_bottom_nav.dart';
import 'package:spark/features/discovery/presentation/screens/discovery_screen.dart';
import 'package:spark/features/matching/presentation/screens/matches_list_screen.dart';
import 'package:spark/features/chat/presentation/screens/chats_list_screen.dart';
import 'package:spark/features/profile/presentation/screens/profile_screen.dart';

/// Provider tracking the current tab index for the home shell.
final homeTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(homeTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: currentTab,
        children: const [
          DiscoveryScreen(),
          MatchesListScreen(),
          ChatsListScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: const SparkBottomNav(),
    );
  }
}

