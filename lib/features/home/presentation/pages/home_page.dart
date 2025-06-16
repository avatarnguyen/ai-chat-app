import 'package:flutter/material.dart';
import '../../../auth/presentation/widgets/auth_wrapper.dart';
import '../../../auth/domain/entities/user.dart';

/// Home page for authenticated users
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const String routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AuthUserBuilder(
      builder:
          (context, user) => Scaffold(
            appBar: AppBar(
              title: const Text('AI Chat'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              actions: [
                IconButton(
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                    child:
                        user.avatarUrl == null
                            ? Text(
                              user.initials,
                              style: const TextStyle(fontSize: 12),
                            )
                            : null,
                  ),
                  onPressed: () => _showProfileMenu(context),
                ),
              ],
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildChatListView(user),
                _buildFoldersView(user),
                _buildSettingsView(user),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: 'Chats',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: 'Folders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
            floatingActionButton:
                _selectedIndex == 0
                    ? FloatingActionButton(
                      onPressed: () => _startNewChat(context),
                      child: const Icon(Icons.add),
                    )
                    : null,
          ),
    );
  }

  Widget _buildChatListView(User user) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${user.displayNameOrEmail}!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continue your conversations or start a new chat',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Recent Conversations',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildChatTile(index),
            childCount: 5, // Placeholder count
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            'New Chat',
            Icons.add_comment,
            () => _startNewChat(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            'Search',
            Icons.search,
            () => _openSearch(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            'Templates',
            Icons.bookmark_outline,
            () => _openTemplates(context),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(int index) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.smart_toy),
      ),
      title: Text('Chat ${index + 1}'),
      subtitle: const Text('Last message preview...'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('2 min ago', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'GPT-4',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
      onTap: () => _openChat(context, index),
    );
  }

  Widget _buildFoldersView(User user) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: const Text('Folders'),
          actions: [
            IconButton(
              icon: const Icon(Icons.create_new_folder),
              onPressed: () => _createFolder(context),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildFolderCard(index),
              childCount: 4, // Placeholder count
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFolderCard(int index) {
    final folders = ['Work', 'Personal', 'Research', 'Projects'];
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];

    return Card(
      child: InkWell(
        onTap: () => _openFolder(context, index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.folder, size: 48, color: colors[index]),
              const Spacer(),
              Text(
                folders[index],
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${index + 3} chats',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsView(User user) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSettingsSection('Account', [
          _buildSettingsTile(
            'Profile',
            Icons.person_outline,
            () => _openProfile(context),
          ),
          _buildSettingsTile(
            'API Keys',
            Icons.key_outlined,
            () => _openApiKeys(context),
          ),
          _buildSettingsTile(
            'Usage & Billing',
            Icons.receipt_outlined,
            () => _openUsage(context),
          ),
        ]),
        const SizedBox(height: 24),
        _buildSettingsSection('Preferences', [
          _buildSettingsTile(
            'Default Model',
            Icons.smart_toy_outlined,
            () => _openModelSettings(context),
          ),
          _buildSettingsTile(
            'Theme',
            Icons.palette_outlined,
            () => _openThemeSettings(context),
          ),
          _buildSettingsTile(
            'Language',
            Icons.language_outlined,
            () => _openLanguageSettings(context),
          ),
        ]),
        const SizedBox(height: 24),
        _buildSettingsSection('Support', [
          _buildSettingsTile(
            'Help & FAQ',
            Icons.help_outline,
            () => _openHelp(context),
          ),
          _buildSettingsTile(
            'Contact Support',
            Icons.support_agent_outlined,
            () => _contactSupport(context),
          ),
          _buildSettingsTile(
            'Privacy Policy',
            Icons.privacy_tip_outlined,
            () => _openPrivacyPolicy(context),
          ),
        ]),
        const SizedBox(height: 24),
        _buildSettingsTile(
          'Sign Out',
          Icons.logout,
          () => _signOut(context),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildSettingsTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  _openProfile(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () {
                  Navigator.pop(context);
                  _signOut(context);
                },
              ),
            ],
          ),
    );
  }

  void _startNewChat(BuildContext context) {
    // TODO: Navigate to chat creation screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Starting new chat...')));
  }

  void _openChat(BuildContext context, int chatIndex) {
    // TODO: Navigate to chat screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening chat ${chatIndex + 1}...')));
  }

  void _openSearch(BuildContext context) {
    // TODO: Open search screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening search...')));
  }

  void _openTemplates(BuildContext context) {
    // TODO: Open templates screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening templates...')));
  }

  void _createFolder(BuildContext context) {
    // TODO: Show create folder dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Creating folder...')));
  }

  void _openFolder(BuildContext context, int folderIndex) {
    // TODO: Navigate to folder contents
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening folder ${folderIndex + 1}...')),
    );
  }

  void _openProfile(BuildContext context) {
    // TODO: Navigate to profile screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening profile...')));
  }

  void _openApiKeys(BuildContext context) {
    // TODO: Navigate to API keys screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening API keys...')));
  }

  void _openUsage(BuildContext context) {
    // TODO: Navigate to usage screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening usage stats...')));
  }

  void _openModelSettings(BuildContext context) {
    // TODO: Navigate to model settings
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening model settings...')));
  }

  void _openThemeSettings(BuildContext context) {
    // TODO: Navigate to theme settings
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening theme settings...')));
  }

  void _openLanguageSettings(BuildContext context) {
    // TODO: Navigate to language settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening language settings...')),
    );
  }

  void _openHelp(BuildContext context) {
    // TODO: Navigate to help screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening help...')));
  }

  void _contactSupport(BuildContext context) {
    // TODO: Navigate to support screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Contacting support...')));
  }

  void _openPrivacyPolicy(BuildContext context) {
    // TODO: Navigate to privacy policy
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening privacy policy...')));
  }

  void _signOut(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.signOut();
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }
}
