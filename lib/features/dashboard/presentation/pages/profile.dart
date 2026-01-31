import 'package:blogify/core/providers/profile_provider.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/features/auth/presentation/pages/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(userSessionServiceProvider);

    final state = ref.watch(profileProvider);
    final controller = ref.read(profileProvider.notifier);

    final name = session.getCurrentUserFullName() ?? "User";
    final email = session.getCurrentUserEmail() ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar + camera icon
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: (state.imageUrl != null && state.imageUrl!.isNotEmpty)
                      ? NetworkImage(state.imageUrl!)
                      : null,
                  child: (state.imageUrl == null || state.imageUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 55, color: Colors.white)
                      : null,
                ),
                FloatingActionButton.small(
                  onPressed: state.loading ? null : () => _showPicker(context, controller),
                  child: const Icon(Icons.camera_alt),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(email, style: TextStyle(color: Colors.grey.shade700)),

            const SizedBox(height: 20),

            if (state.loading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 10),
              const Text("Uploading..."),
            ],

            if (state.error != null) ...[
              const SizedBox(height: 10),
              Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await session.clearSession();
                  ref.read(profileProvider.notifier).clear(); // ✅ clear local state
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, ProfileController controller) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text("Take photo"),
              onTap: () {
                Navigator.pop(context);
                controller.pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from gallery"),
              onTap: () {
                Navigator.pop(context);
                controller.pickAndUpload(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
