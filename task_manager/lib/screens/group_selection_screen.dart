import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import 'task_board_screen.dart';

class GroupSelectionScreen extends StatefulWidget {
  const GroupSelectionScreen({super.key});

  @override
  State<GroupSelectionScreen> createState() => _GroupSelectionScreenState();
}

class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();
  List<Group> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _groupService.getUserGroups();
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading groups: $e')));
    }
  }

  void _selectGroup(Group group) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => TaskBoardScreen(group: group)),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a group name')),
                );
                return;
              }

              // Salvează referința la ScaffoldMessenger ÎNAINTE de Navigator.pop
              final messenger = ScaffoldMessenger.of(context);
              final name = nameController.text.trim();
              final desc = descController.text.trim().isEmpty
                  ? null
                  : descController.text.trim();

              try {
                // Închide dialog-ul
                Navigator.pop(context);

                setState(() => _isLoading = true);

                final group = await _groupService.createGroup(name, desc);

                await _loadGroups();
                setState(() => _isLoading = false);

                // Folosește referința salvată (nu contextul)
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Group "${group.name}" created! Code: ${group.inviteCode}',
                    ),
                  ),
                );
              } catch (e) {
                setState(() => _isLoading = false);
                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Group'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Invite Code',
            border: OutlineInputBorder(),
            hintText: 'Enter 6-character code',
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (codeController.text.trim().length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invite code must be 6 characters'),
                  ),
                );
                return;
              }

              // Salvează contextul scaffold-ului ÎNAINTE de a închide dialogul
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              try {
                navigator.pop();
                setState(() => _isLoading = true);

                final group = await _groupService.joinGroupByCode(
                  codeController.text.trim(),
                );

                await _loadGroups();

                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Joined group "${group.name}"!')),
                );
              } catch (e) {
                setState(() => _isLoading = false);
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
          ? _buildEmptyState()
          : _buildGroupList(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _showJoinGroupDialog,
            icon: const Icon(Icons.login),
            label: const Text('Join Group'),
            heroTag: 'join',
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: _showCreateGroupDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Group'),
            heroTag: 'create',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No Groups Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a group or join one using an invite code',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                group.name[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              group.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (group.description != null && group.description!.isNotEmpty)
                  Text(group.description!),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.vpn_key, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Code: ${group.inviteCode}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: group.inviteCode),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _selectGroup(group),
          ),
        );
      },
    );
  }
}
