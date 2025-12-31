import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'analysis.dart';
import 'history.dart';
import 'settings.dart';
import 'form.dart';
import 'session.dart';
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainApp()
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    AnalysisPage(),
    HistoryPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/icon/3.png', height: 40),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      floatingActionButton: GestureDetector(
        onLongPress: () {
          // Long-press -> open quick add page that hosts AddTransaction
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Quick Add Transaction')),
                body: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: AddTransaction(),
                ),
              ),
            ),
          );
        },
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SecondRoute()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analysis',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ListTile(
              title: const Text('Item 1'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Item 2'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? _chartImage;
  List<dynamic> _todayTransactions = [];
  bool _isLoadingChart = true;
  bool _isLoadingTransactions = true;

  // Fetch the pie chart from the backend
  Future<void> fetchPieChart() async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/pie_chart'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'transactions': [], // You can pass all transactions or filter them
          'chartType': 'category',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _chartImage = response.bodyBytes;
          _isLoadingChart = false;
        });
      } else {
        throw Exception('Failed to load pie chart');
      }
    } catch (e) {
            if (mounted) {
        setState(() {
          _isLoadingChart = false;
        });
      }
      print('Error fetching pie chart: $e');
    }
  }

  // Fetch today's transactions from the backend
  Future<void> fetchTodayTransactions() async {
    try {
      final userId = Session.userId;
      if (userId == null) {
        if (mounted) {
          setState(() { _isLoadingTransactions = false; });
        }
        return;
      }
      final response = await http.get(Uri.parse('http://127.0.0.1:8001/transactions?user_id=$userId'));
      if (response.statusCode == 200) {
        final List<dynamic> transactions = json.decode(response.body);

        // Filter transactions for today
        final today = DateTime.now();
        final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
        final todayTransactions = transactions.where((transaction) {
          return transaction['date'] == todayString;
        }).toList();

        setState(() {
          _todayTransactions = todayTransactions;
          _isLoadingTransactions = false;
        });
      } else {
        throw Exception('Failed to fetch transactions');
      }
    } catch (e) {
      if (mounted) {
      setState(() {
        _isLoadingTransactions = false;
      });
      }
      print('Error fetching transactions: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPieChart();
    fetchTodayTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Top box for the pie chart
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: _isLoadingChart
                    ? const Center(child: CircularProgressIndicator())
                    : _chartImage == null
                        ? const Center(
                            child: Text(
                              'Failed to load pie chart',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          )
                        : Image.memory(
                            _chartImage!,
                            fit: BoxFit.contain,
                          ),
              ),
            ),
          ),

          // Bottom box for today's transactions
          Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Title for today's transactions
      const Padding(
        padding: EdgeInsets.only(bottom: 8.0),
        child: Text(
          "Today's Transactions",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Card for today's transactions
      Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: _isLoadingTransactions
              ? const Center(child: CircularProgressIndicator())
              : _todayTransactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions found for today',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _todayTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _todayTransactions[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction['content'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Amount: ${transaction['amount']} ${transaction['currency']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Category: ${transaction['category']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    ],
  ),
),
        ],
      ),
    );
  }
}