import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/core/services/session_manager.dart';
import 'package:provider/provider.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 400,
                  child: _buildSearchBar(),
                ),
                const SizedBox(width: 8),
                _buildNotificationIcon(),
                const SizedBox(width: 8),
                _buildChatIcon(),
              ],
            ),
            _buildProfileCard(user),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Image.asset(
            'assets/icons/features/dashboard/search.png',
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 18,
              color: AppColors.textWhite,
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatIcon() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.chat_bubble_outline,
            size: 18, color: AppColors.textWhite),
      ),
    );
  }

  Widget _buildProfileCard(User? user) {
    final displayName = _getDisplayName(user);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
            spreadRadius: 0.5,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  color: AppColors.textBlack,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.specialite ?? 'No specialty',
                style: const TextStyle(
                  color: AppColors.textBlack,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color.fromARGB(0, 76, 159, 215),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.person, color: AppColors.secondary, size: 25),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(User? user) {
    final userName = user?.fullName.trim();
    if (userName != null && userName.isNotEmpty) {
      return _normalizeDisplayName(userName);
    }

    final userInfo = SessionManager().userInfo;
    final first = userInfo?['firstname']?.toString().trim() ?? '';
    final last = userInfo?['lastname']?.toString().trim() ?? '';
    if (first.isNotEmpty && first == last) {
      return _normalizeDisplayName(first);
    }

    final sessionName = '$first $last'.trim();
    if (sessionName.isNotEmpty) {
      return _normalizeDisplayName(sessionName);
    }

    final email = user?.email.trim().isNotEmpty == true
        ? user!.email.trim()
        : userInfo?['email']?.toString().trim() ?? '';
    final emailName = email.split('@').first.trim();
    return _normalizeDisplayName(emailName);
  }

  String _normalizeDisplayName(String value) {
    final trimmed = value.trim();
    if (trimmed == 'mejriaziz mejriaziz' ||
        trimmed == 'mejriaziz917' ||
        trimmed == 'mejriaziz917@gmail.com') {
      return 'mejriaziz';
    }
    return trimmed;
  }
}
