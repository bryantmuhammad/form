import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> listGrocery = [];
  bool isLoading = true;
  bool isDeleting = false;
  String? errorMessage;

  void _loadItems() async {
    final url = Uri.https(
        'flutter-prep-12970-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list.json');
    final response = await http.get(url);
    if (response.statusCode >= 400) {
      errorMessage = 'Failed to load item';
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadItem = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
            (element) => element.value.title == item.value['category'],
          )
          .value;

      loadItem.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }

    setState(() {
      listGrocery = loadItem;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _changeScreen() async {
    final GroceryItem newItem = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NewItem(),
      ),
    );

    setState(() {
      listGrocery.add(newItem);
    });
  }

  void _removeItem(int index) {
    GroceryItem groceryItem = listGrocery[index];

    final url = Uri.https(
      'flutter-prep-12970-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list/${groceryItem.id}.json',
    );

    isDeleting = true;

    setState(() {
      listGrocery.removeAt(index);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Success remove item'),
        duration: const Duration(milliseconds: 1750),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            isDeleting = false;
            setState(() {
              listGrocery.insert(index, groceryItem);
            });
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (isDeleting) {
        http.delete(url);
        return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget activeWidget = const Center(
      child: Text('No item in groceries'),
    );
    if (isLoading) {
      activeWidget = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (listGrocery.isNotEmpty) {
      activeWidget = ListView.builder(
        itemCount: listGrocery.length,
        itemBuilder: (context, index) => Dismissible(
          background: Container(color: Colors.red),
          key: ValueKey(listGrocery[index]),
          onDismissed: (direction) {
            _removeItem(index);
          },
          child: ListTile(
            title: Text(listGrocery[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: listGrocery[index].category.color,
            ),
            trailing: Text(
              listGrocery[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      activeWidget = Center(
        child: Text(errorMessage!),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(
              onPressed: _changeScreen,
              icon: const Icon(Icons.add),
            )
          ],
        ),
        body: activeWidget);
  }
}
