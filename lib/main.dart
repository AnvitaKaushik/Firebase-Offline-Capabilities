import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'firebase_options.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Firebase Database Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  late FirebaseDatabase database ; // Initialize FirebaseDatabase
  List<String> dataList = []; // List to store user names

  Future<void> _initializeDatabase() async {
     FirebaseDatabase.instance.setPersistenceEnabled(true);
    database = FirebaseDatabase(app: Firebase.app()); // Initialize after enabling persistence
  }

  void _sendDataToFirebase() async {
    final name = _nameController.text;
    final age = int.tryParse(_ageController.text) ?? 0;

    if (name.isNotEmpty && age > 0) {
      final ref = database.reference().child('users').push();

      try {
        await ref.set({
          'name': name,
          'age': age,
        });
        _nameController.clear();
        _ageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data sent to Firebase!'),
          ),
        );
      } on FirebaseException catch (error) {
        // Handle offline scenario or other errors
        if (error.code == 'PERMISSION_DENIED') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You don\'t have permission to write to the database.'),
            ),
          );
        } else if (error.code == 'DISCONNECTED') {
          // Data will be queued and sent when online
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data is queued for offline storage. It will be sent when you\'re online.'),
            ),
          );
        } else {
          // Handle other errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending data: ${error.message}'),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name and a valid age.'),
        ),
      );
    }
  }

  void _listenForData() {
    final ref = database.reference().child('users');
    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      _updateDataList(data);
    });
  }

  void _updateDataList(dynamic data) {
    dataList.clear();
    if (data != null) {
      data.forEach((key, value) {
        final name = value['name'] as String;
        dataList.add(name);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _listenForData(); // Start listening for data changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary, // Use primary color
        title: Text(widget.title),
       // Center the title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding for better layout
        child: SingleChildScrollView( // Allow scrolling if content overflows
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch elements horizontally
            children: <Widget>[
   SizedBox(height: 50), // Add spacing between elements
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Enter your name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                  ),
                ),
              ),
              const SizedBox(height: 16.0), // Add spacing between elements
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter your age',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // ElevatedButton with visual feedback on press
              ElevatedButton(
                onPressed: _sendDataToFirebase,
                child: const Text('Send data to Firebase'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48), // Full width button
                ),
              ),
              const SizedBox(height: 16.0),
              // Get data button with state management (consider using Provider or another state management solution)
              ElevatedButton(
                onPressed: (){ setState(() {

                }); },// Separate function for data retrieval
                child: const Text('Get data from Firebase'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16.0),
              // Display retrieved data
              if (dataList.isNotEmpty) // Only show list if data exists
                ListView.builder(
                  shrinkWrap: true, // Adjust list view height
                  itemCount: dataList.length,
                  itemBuilder: (context, index) {
                    final name = dataList[index];
                    return Text(name);
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        isExtended: true, // Make the button wider
        tooltip: 'Clear data',
        onPressed: _clearData,
        child: Column(
          children: [
            const Icon(Icons.delete),
            Text('Clear data', style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _clearData() async {
    try {
      final ref = database.reference().child('users'); // Replace 'users' with your actual data location
      await ref.remove();
      setState(() {
        dataList.clear(); // Clear local list as well
      });
     // Clear local list as well
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data cleared from Firebase!'),
        ),
      );
    } on FirebaseException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing data: ${error.message}'),
        ),
      );
    }
  }

}
