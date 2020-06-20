import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:todo/models/task.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class TaskProvider extends ChangeNotifier {
  // Get Platform of current device
  getPlatform() {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        if (Platform.isAndroid) {
          return "android";
        }
        if (Platform.isIOS) {
          return "ios";
        }
      } else {
        return "web";
      }
    } catch (e) {
      return "web";
    }
  }


  getURL() {
    if (getPlatform() == "android") {
      return "http://10.0.2.2:8000/todo";
    } else {
      return "http://127.0.0.1:8000/todo";
    }
  }
  // var url = "http://10.0.2.2:8000/todo";
  // var url = "http://127.0.0.1:8000/todo";

  TaskProvider() {
    this.fetchTaks();
  }

  List<Task> _tasks = [];

  UnmodifiableListView<Task> get allTasks => UnmodifiableListView(_tasks);
  UnmodifiableListView<Task> get incompleteTasks =>
      UnmodifiableListView(_tasks.where((todo) => !todo.completed));
  UnmodifiableListView<Task> get completedTasks =>
      UnmodifiableListView(_tasks.where((todo) => todo.completed));

  void addTodo(Task task) async {
    final response = await http.post(
      getURL(),
      headers: {"Content-Type": "application/json"},
      body: json.encode(task),
    );
    if (response.statusCode == 201) {
      task.id = json.decode(response.body)['id'];
      _tasks.add(task);
      notifyListeners();
    }
  }

  void toggleTodo(Task task) async {
    final taskIndex = _tasks.indexOf(task);
    _tasks[taskIndex].toggleCompleted();
    final response = await http.patch(
      getURL() + "/${task.id}",
      headers: {"Content-Type": "application/json"},
      body: json.encode(task),
    );
    if (response.statusCode == 200) {
      notifyListeners();
    } else {
      _tasks[taskIndex].toggleCompleted(); //revert back
    }
  }

  void deleteTodo(Task task) async {
    final response = await http.delete(
      getURL() + "/${task.id}",
    );
    if (response.statusCode == 204) {
      _tasks.remove(task);
      notifyListeners();
    }
  }

  fetchTaks() async {
    final response = await http.get(getURL());
    if (response.statusCode == 200) {
      var data = json.decode(response.body) as List;
      _tasks = data.map<Task>((json) => Task.fromJason(json)).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to load data!');
    }
  }
}
