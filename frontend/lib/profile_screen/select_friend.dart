// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:frontend/api_services/friend_chat_service.dart';
import 'package:frontend/components/standard_app_bar.dart';
import 'package:frontend/profile_screen/chat_screen.dart';
import 'package:frontend/theme.dart';

class SelectFriendScreen extends StatefulWidget {
  const SelectFriendScreen({super.key});

  @override
  State<SelectFriendScreen> createState() => _SelectFriendScreenState();
}

class _SelectFriendScreenState extends State<SelectFriendScreen> {
  List<dynamic> friends = [];
  bool isLoading = true;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndFriends();
  }

  Future<void> _loadCurrentUserAndFriends() async {
    try {
      final id = await FriendChatService.getCurrentUserId();
      if (id == null) throw Exception('User ID not found, please login again');
      final result = await FriendChatService.getFriends();

      setState(() {
        currentUserId = id;
        friends = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading friends: $e')),
        );
      }
    }
  }

  void _showSearchPopup() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Search by Email or Phone"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter email or phone"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final user =
                    await FriendChatService.searchUser(controller.text);
                _showFriendResultPopup(user);
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: Text("Continue"),
          ),
        ],
      ),
    );
  }

  void _showFriendResultPopup(Map user) {
    final String? imageUrl = user['profile_pic'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add Friend"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null ? Icon(Icons.person) : null,
            ),
            SizedBox(height: 10),
            Text(user['full_name']),
            Text(user['email'] ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await FriendChatService.addFriend(user['id'].toString());
                Navigator.pop(ctx);
                if (currentUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User ID not found')));
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatRoomId: _getRoomId(user['id']),
                      receiverId: user['id'],
                      receiverName: user['full_name'],
                      receiverProfilePic: user['profile_pic'],
                      currentUserId: currentUserId!,
                    ),
                  ),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: Text("Add & Chat"),
          ),
        ],
      ),
    );
  }

  String _getRoomId(int receiverId) {
    if (currentUserId == null) return 'chat_0_0';
    final ids = [currentUserId!, receiverId]..sort();
    return 'chat_${ids[0]}_${ids[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        appBarTitle: "Select Friend",
        showBackButton: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.only(left: 25,right: 25,top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // New Friend Tile
                  GestureDetector(
                    onTap: _showSearchPopup,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.person_add, size: 28),
                          SizedBox(width: 12),
                          Text(
                            "New friend",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Friends Title
                  const Text(
                    "Friends",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Friend List
                  Expanded(
                    child: ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (_, index) {
                        final friend = friends[index];
                        final String? imageUrl = friend['profile_pic'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: imageUrl != null
                                    ? NetworkImage(imageUrl)
                                    : null,
                                child: imageUrl == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                friend['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () {
                                if (currentUserId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('User ID not found')),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      chatRoomId: _getRoomId(friend['id']),
                                      receiverId: friend['id'],
                                      receiverName: friend['name'],
                                      receiverProfilePic: friend['profile_pic'],
                                      currentUserId: currentUserId!,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
