// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors, avoid_print, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'auth/auth_gate.dart';
import 'service.dart';

class HomePage extends StatefulWidget {
  String username;
  final String userId;

  HomePage({required this.username, required this.userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TaskService _taskService = TaskService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  File? _profileImage;
  String _profileImageUrl = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _usernameController.text = widget.username;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if (userDoc.exists) {
      setState(() {
        _profileImageUrl = userDoc['image_url'];
        _email = userDoc['email'];
        _usernameController.text = userDoc['username'];
      });
    }
  }

  Future<void> _updateProfileImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${widget.userId}.jpg');
      await storageRef.putFile(image);
      String imageUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'image_url': imageUrl,
      });
      setState(() {
        _profileImageUrl = imageUrl;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      await _updateProfileImage(_profileImage!);
    }
  }

  Future<void> _updateUsername() async {
    await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
      'username': _usernameController.text,
    });
    setState(() {
      widget.username = _usernameController.text;
    });
  }

  void _showEditUsernameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.username),
          content: TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: 'Username'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await _updateUsername();
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _addTask(String title, String description) async {
    await _taskService.addTask(widget.userId, title, description);
  }

  void _editTask(String taskId, String title, String description) async {
    await _taskService.updateTask(taskId, title, description);
  }

  void _completeTask(String taskId) async {
    await _taskService.completeTask(taskId);
  }

  void _deleteTask(String taskId) async {
    await _taskService.deleteTask(taskId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending',icon: Icon(Icons.pending_actions),),
            Tab(text: 'Completed',icon: Icon(Icons.check_circle)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => AuthPage()),
              );
            },
          ),
        ],
        leading: Builder(
          builder: (context) => IconButton(
            icon: CircleAvatar(
              backgroundImage: NetworkImage(_profileImageUrl),
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer(); 
            },
          ),
        ),
      ), 
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: _profileImageUrl.isNotEmpty
                          ? NetworkImage(_profileImageUrl)
                          : null,
                      child: _profileImageUrl.isEmpty
                          ? Icon(Icons.camera_alt, size: 40, color: Colors.white)
                          : null,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Hello, ${_usernameController.text}', 
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.edit),
                    title: Text(_usernameController.text),
                    onTap: _showEditUsernameDialog,
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                       SizedBox(width: 11),
                      Icon(Icons.email),
                      
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _email,
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskListStream(widget.userId, false),
          _buildTaskListStream(widget.userId, true),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(25.0),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true, // Make bottom sheet more stretchable
              builder: (context) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create New Task',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(labelText: 'Task Name'),
                        ),
                        TextField(
                          controller: _descriptionController,
                          decoration:
                              InputDecoration(labelText: 'Task Description'),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            _addTask(_titleController.text,
                                _descriptionController.text);
                            _titleController.clear();
                            _descriptionController.clear();
                            Navigator.of(context).pop();
                          },
                          child: Text('Add Task'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTaskListStream(String userId, bool completed) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _taskService.streamTasks(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No tasks found'));
        }

        final tasks = snapshot.data!
            .where((task) => task['completed'] == completed)
            .toList();

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              color: Colors.grey[200], // Darker color
              child: ListTile(
                title:
                Text(
                  task['title'],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['description'],
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Created on: ${DateTime.parse(task['time']).toLocal().toString().substring(0, 16)}',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!task['completed'])
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.black),
                        onPressed: () {
                          _showEditTaskDialog(task);
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.black),
                      onPressed: () {
                        _deleteTask(task['id']);
                      },
                    ),
                    task['completed']
                        ? Icon(Icons.check, color: Colors.black)
                        : IconButton(
                            icon: Icon(Icons.check_box_outline_blank, color: Colors.black),
                            onPressed: () {
                              _completeTask(task['id']);
                            },
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditTaskDialog(Map<String, dynamic> task) {
    _titleController.text = task['title'];
    _descriptionController.text = task['description'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Task',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Task Name'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Task Description'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _editTask(task['id'], _titleController.text,
                        _descriptionController.text);
                    _titleController.clear();
                    _descriptionController.clear();
                    Navigator.of(context).pop();
                  },
                  child: Text('Update Task'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

