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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransaction()),
          );
        },
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20),
            Text('Add', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(Icons.home, color: _selectedIndex == 0 ? Colors.amber[800] : Colors.grey),
                    Text('Home', style: TextStyle(fontSize: 12, color: _selectedIndex == 0 ? Colors.amber[800] : Colors.grey)),
                  ],
                ),
              ),
            ),
            Container(width: 1, color: Colors.transparent),
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(Icons.analytics, color: _selectedIndex == 1 ? Colors.amber[800] : Colors.grey),
                    Text('Analysis', style: TextStyle(fontSize: 12, color: _selectedIndex == 1 ? Colors.amber[800] : Colors.grey)),
                  ],
                ),
              ),
            ),
            Container(width: 1, color: Colors.transparent),
            const SizedBox(width: 48), // Space for FAB
            Container(width: 1, color: Colors.transparent),
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(Icons.history, color: _selectedIndex == 2 ? Colors.amber[800] : Colors.grey),
                    Text('History', style: TextStyle(fontSize: 12, color: _selectedIndex == 2 ? Colors.amber[800] : Colors.grey)),
                  ],
                ),
              ),
            ),
            Container(width: 1, color: Colors.transparent),
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(Icons.settings, color: _selectedIndex == 3 ? Colors.amber[800] : Colors.grey),
                    Text('Settings', style: TextStyle(fontSize: 12, color: _selectedIndex == 3 ? Colors.amber[800] : Colors.grey)),
                  ],
                ),
              ),
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
  List<dynamic> _todayTransactions = [];
  List<dynamic> _allTransactions = [];
  bool _isLoadingTransactions = true;

  // Fetch transactions from the backend
  Future<void> fetchTransactions() async {
    try {
      final userId = Session.userId;
      if (userId == null) {
        if (mounted) {
          setState(() { _isLoadingTransactions = false; });
        }
        return;
      }
      final response = await http.get(Uri.parse('http://api.conaudio.vn:8000/transactions?user_id=$userId'));
      if (response.statusCode == 200) {
        final List<dynamic> transactions = json.decode(response.body);

        // Filter transactions for today
        final today = DateTime.now();
        final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
        final todayTransactions = transactions.where((transaction) {
          return transaction['date'] == todayString;
        }).toList();

        setState(() {
          _allTransactions = transactions;
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

  // Calculate total spending for the current month
  double getMonthlySpending() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    double total = 0;
    for (var transaction in _allTransactions) {
      try {
        final dateParts = (transaction['date'] as String).split('-');
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);

        if (year == currentYear && month == currentMonth) {
          total += double.parse(transaction['amount'].toString());
        }
      } catch (e) {
        print('Error parsing transaction: $e');
      }
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    // Extract username from email (part before @)
    final email = Session.email ?? '';
    final userName = email.contains('@') ? email.split('@')[0] : email;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Welcome message
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Welcome, $userName',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Two boxes for monthly spending and placeholder
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Left box: Monthly spending
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "This Month's Spending",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              '\$${getMonthlySpending().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Right box: Placeholder
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: const Center(
                        child: Text(
                          'Placeholder',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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