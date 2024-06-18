import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:todo_list/home.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _username = '';
  String _email = '';
  String _password = '';
  File? _image;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();

  void _switchAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${_auth.currentUser!.uid}.jpg');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        UserCredential authResult;
        if (_isLogin) {
          authResult = await _auth.signInWithEmailAndPassword(
            email: _email,
            password: _password,
          );
        } else {
          authResult = await _auth.createUserWithEmailAndPassword(
            email: _email,
            password: _password,
          );

          String? imageUrl;
          if (_image != null) {
            imageUrl = await _uploadImage(_image!);
          }

          await _firestore.collection('users').doc(authResult.user!.uid).set({
            'username': _username,
            'email': _email,
            'image_url': imageUrl ?? '',
          });
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(
              username: _username,
              userId: authResult.user!.uid,
            ),
          ),
        );
      } catch (e) {
        print(e);
        // Show error message
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLogin)
                      const Text(
                        'Welcome again!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (!_isLogin)
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (!_isLogin) SizedBox(height: 20),
                    if (!_isLogin)
                      const Text(
                        'Create an account',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (!_isLogin) SizedBox(height: 20),
                    if (!_isLogin)
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              _image != null ? FileImage(_image!) : null,
                          child: _image == null
                              ? Icon(Icons.camera_alt, size: 40)
                              : null,
                        ),
                      ),
                    if (!_isLogin) SizedBox(height: 20),
                    if (!_isLogin)
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Username',
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onSaved: (value) {
                          _username = value!;
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onSaved: (value) {
                        _email = value!;
                      },
                      validator: (value) {
                        if (value!.isEmpty || !value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      obscureText: true,
                      onSaved: (value) {
                        _password = value!;
                      },
                      validator: (value) {
                        if (value!.isEmpty || value.length < 6) {
                          return 'Password must be at least 6 characters long';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 50),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(
                        _isLogin ? 'Login' : 'Register',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20), // Adjust text size
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 50, vertical: 16), // Button padding
                      ),
                    ),
                    TextButton(
                      onPressed: _switchAuthMode,
                      child: Text(
                        _isLogin
                            ? 'Create new account'
                            : 'Already have an account?',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
