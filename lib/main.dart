import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(InventoryApp());
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InventoryHomePage(title: 'Inventory Management'),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  final String title;

  InventoryHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final CollectionReference items =
      FirebaseFirestore.instance.collection('items');

  void _showItemDialog({DocumentSnapshot? doc}) {
    final TextEditingController nameController = TextEditingController(
      text: doc != null ? doc['name'] : '',
    );
    final TextEditingController quantityController = TextEditingController(
      text: doc != null ? doc['quantity'].toString() : '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc != null ? 'Edit Item' : 'Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Item Name')),
            TextField(controller: quantityController, decoration: InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text(doc != null ? 'Update' : 'Add'),
            onPressed: () async {
              final String name = nameController.text;
              final int quantity = int.tryParse(quantityController.text) ?? 0;

              if (name.isNotEmpty) {
                if (doc != null) {
                  await items.doc(doc.id).update({'name': name, 'quantity': quantity});
                } else {
                  await items.add({'name': name, 'quantity': quantity});
                }
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _deleteItem(String id) async {
    await items.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<QuerySnapshot>(
        stream: items.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error loading data'));
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

          final data = snapshot.data!.docs;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final doc = data[index];
              return ListTile(
                title: Text(doc['name']),
                subtitle: Text('Quantity: ${doc['quantity']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.edit), onPressed: () => _showItemDialog(doc: doc)),
                    IconButton(icon: Icon(Icons.delete), onPressed: () => _deleteItem(doc.id)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(),
        tooltip: 'Add Item',
        child: Icon(Icons.add),
      ),
    );
  }
}
