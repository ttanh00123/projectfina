import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'session.dart';
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  final Set<int> _selectedTransactions = {}; // Store indices of selected transactions

  // Function to fetch transactions from the API
  Future<void> fetchTransactions() async {
    try {
      final userId = Session.userId;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8001/transactions?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _transactions = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
            if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error fetching transactions: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTransactions(); // Fetch transactions when the page loads
  }

  void _editSelectedTransactions() {
    // Placeholder for edit functionality
    print('Edit transactions: $_selectedTransactions');
  }

  Future<void> _deleteSelectedTransactions() async {
    // Confirm with the user
    print('Delete transactions: $_selectedTransactions');
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_selectedTransactions.length} transaction(s)?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete != true) return;

    if (_selectedTransactions.isEmpty) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Collect selected indices and sort descending so removals don't shift later indices
      final indices = _selectedTransactions.toList()..sort((a, b) => b.compareTo(a));

      // Map indices to ids (assumes each transaction has an 'id' field)
      final ids = <int>[];
      for (final i in indices) {
        if (i >= 0 && i < _transactions.length) {
          final idVal = _transactions[i]['id'];
          if (idVal is int) ids.add(idVal);
          print('Delete transactions: $idVal');
        }
      }

      if (ids.isEmpty) {
        // Nothing we can delete on server side; inform user
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid IDs found for selected transactions.')));
        return;
      }

      // Send DELETE requests in parallel
      final responses = await Future.wait(ids.map((id) => http.delete(Uri.parse('http://127.0.0.1:8001/deleteTransaction/$id'))));

      // Check results
      bool anyFailure = false;
      for (final r in responses) {
        if (r.statusCode != 200 && r.statusCode != 204) {
          anyFailure = true;
          break;
        }
      }

      // Remove local entries for successful deletions
      if (mounted) {
        setState(() {
          for (final idx in indices) {
            if (idx >= 0 && idx < _transactions.length) {
              _transactions.removeAt(idx);
            }
          }
          _selectedTransactions.clear();
          _isLoading = false;
        });
      }

      if (anyFailure) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Some deletions failed on the server.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected transactions deleted.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting transactions: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _selectedTransactions.isEmpty
                ? null
                : _deleteSelectedTransactions, // Disable if no transactions are selected
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show a loading spinner while fetching data
          : _transactions.isEmpty
              ? const Center(child: Text('No transactions found')) // Show a message if no transactions are available
              : ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    final isExpense = transaction['type'] == 'expense';
                    final amountPrefix = isExpense ? '-' : '+';
                    final amountColor = isExpense ? Colors.red : Colors.green;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              // Checkbox for selecting transactions
                              Checkbox(
                                value: _selectedTransactions.contains(index),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedTransactions.add(index);
                                    } else {
                                      _selectedTransactions.remove(index);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8), // Space between checkbox and content
                              // Amount with prefix
                              Text(
                                '$amountPrefix${transaction['amount']} ${transaction['currency']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: amountColor,
                                ),
                              ),
                              const SizedBox(width: 16), // Space between amount and content
                              // Content
                              Expanded(
                                child: Text(
                                  transaction['content'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis, // Truncate if too long
                                ),
                              ),
                              const SizedBox(width: 16), // Space between content and category
                              // Category
                              Text(
                                transaction['category'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis, // Truncate if too long
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}