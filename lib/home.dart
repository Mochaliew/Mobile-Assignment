import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'user.dart';

class Home extends StatefulWidget {
  Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // ---------------------------------------------------------------------------
  // TODO(2)
  final supabase = Supabase.instance.client;
  // ---------------------------------------------------------------------------

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  List<User> _users = [];
  User? _selectedUser = null;

  void snackbar(String s, [Color? c]) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(s), backgroundColor: c));
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // TODO(3)
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try{
      final response = await supabase.from('users').select();

      final users = response.map(User.fromJson).toList();

      setState(() {
        _users = users;
      });
    } catch (e){
      snackbar('Error fetcing users: $e', Colors.red );


    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // TODO(4)
  Future<void> _addUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty){
      return;
    }

    try{
      setState(() {
        _isLoading = true;
      });

      final response =  await supabase.from('users').insert({
        'name' : name,
        'email' : email,
      }).select();

      _nameController.clear();
      _emailController.clear();

      final user = User.fromJson( response.first );
      setState(() {
        _users.add( user );
      });

      snackbar('User added successfully.');
    } catch (e) {
      snackbar('Error adding user: $e', Colors.red);

    } finally {
      setState(() {
        _isLoading = false;
      });
    }

  }

  // TODO(5)
  Future<void> _updateUser() async {
    if (_selectedUser == null){
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty){
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });
      final response = await supabase.from( 'users' ).update({
        'name' : name,
        'email' : email,
      }).eq('id', _selectedUser!.id).select();

      _nameController.clear();
      _emailController.clear();

      final user = User.fromJson( response.first );
      final index = _users.indexWhere( (u) => u.id == user.id );
      if (index != -1) {
        setState(() {
          _users[index] = user;
        });
      }

      snackbar('User updated successfully.');
    } catch (e){
      snackbar('Error updating user: $e', Colors.red);

    } finally {
      setState(() {
        _isLoading = false;
        _selectedUser = null;
      });
    }

  }

  // TODO(6)
  Future<void> _deleteUser(int id) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await supabase.from('users').delete().eq('id', id);

      setState(() {
        _users.removeWhere((u) => u.id == id );
      });

      snackbar('User deleted successfully.');

    } catch (e) {

      snackbar('Error deleting user: $e', Colors.red);

    } finally {
      setState(() {
        _isLoading = false;
      });
    }

  }
  // ---------------------------------------------------------------------------

  void _selectUserForUpdate(User user) {
    setState(() {
      _selectedUser = user;
      _nameController.text = user.name;
      _emailController.text = user.email;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedUser = null;
      _nameController.clear();
      _emailController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Practical 11: Supabase User App'),
        backgroundColor: Colors.purple[100],
      ),
      body: Padding(
        padding: .all(8),
        child: Column(
          spacing: 8,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _selectedUser != null ? _updateUser : _addUser,
                  child: Text(_selectedUser != null ? 'Update User' : 'Add User'),
                ),
                if (_selectedUser != null)
                  TextButton(
                    onPressed: _clearSelection,
                    child: Text('Cancel'),
                  ),
              ],
            ),
            Divider(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                  ? Center(child: Text('No users found. Add one.'))
                  : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(user.name[0])),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: Row(
                        mainAxisSize: .min,
                        children: [
                          IconButton(
                            onPressed: () => _selectUserForUpdate(user),
                            icon: Icon(Icons.edit, color: Colors.blue),
                          ),
                          IconButton(
                            onPressed: () => _deleteUser(user.id),
                            icon: Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
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
