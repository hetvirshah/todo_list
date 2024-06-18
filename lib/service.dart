import 'package:cloud_firestore/cloud_firestore.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference tasksCollection =
      FirebaseFirestore.instance.collection('tasks');

  Future<void> addTask(String userId, String title, String description) async {
    try {
      await tasksCollection.add({
        'userId': userId,
        'title': title,
        'description': description,
        'time': DateTime.now().toString(),
        'completed': false,
      });
    } catch (e) {
      print('Error adding task: $e');
    }
  }

  Future<void> updateTask(String taskId, String title, String description) async {
    try {
      await tasksCollection.doc(taskId).update({
        'title': title,
        'description': description,
      });
    } catch (e) {
      print('Error updating task: $e');
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      await tasksCollection.doc(taskId).update({'completed': true});
    } catch (e) {
      print('Error completing task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await tasksCollection.doc(taskId).delete();
    } catch (e) {
      print('Error deleting task: $e');
    }
  }
  Future<Map<String, dynamic>> getUser(String userId) async {
    DocumentSnapshot snapshot = await _firestore.collection('users').doc(userId).get();
    return snapshot.data() as Map<String, dynamic>;
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }
  Stream<List<Map<String, dynamic>>> streamTasks(String userId) {
    return tasksCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
            .toList());
  }
}
