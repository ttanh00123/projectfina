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

  void _showEditDialog(int index, Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (ctx) => EditTransactionDialog(
        transaction: transaction,
        onSave: (updatedTransaction) async {
          await _updateTransaction(index, updatedTransaction);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _updateTransaction(int index, Map<String, dynamic> updatedTransaction) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final token = Session.token;
      final response = await http.put(
        Uri.parse('http://127.0.0.1:8001/updateTransaction/${_transactions[index]['id']}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(updatedTransaction),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          setState(() {
            _transactions[index] = updatedTransaction;
            _isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction updated.')));
      } else {
        throw Exception('Failed to update: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating transaction: $e')));
    }
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
                              const SizedBox(width: 16), // Space between category and edit button
                              // Edit button
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(index, transaction),
                                iconSize: 20,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
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

class EditTransactionDialog extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final Function(Map<String, dynamic>) onSave;

  const EditTransactionDialog({
    required this.transaction,
    required this.onSave,
    super.key,
  });

  @override
  _EditTransactionDialogState createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  late TextEditingController contentController;
  late TextEditingController amountController;
  late TextEditingController tagsController;
  late TextEditingController notesController;
  late TextEditingController dateController;

  String? selectedType;
  String? selectedCategory;
  String? selectedCurrency;

  final List<String> _types = ['expense', 'income'];
    final List<String> _categories = ['Food', 'Transport', 'Entertainment', 'Utilities', 'Other'];
    final List<Map<String, String>> _currencies = [
    {'flag': '🇺🇸', 'code': 'USD'},
    {'flag': '🇪🇺', 'code': 'EUR'},
    {'flag': '🇻🇳', 'code': 'VND'},
    {'flag': '🇸🇬', 'code': 'SGD'},
    {'flag': '🇬🇧', 'code': 'GBP'},
  ];

  @override
  void initState() {
    super.initState();
    contentController = TextEditingController(text: widget.transaction['content'] ?? '');
    amountController = TextEditingController(text: widget.transaction['amount']?.toString() ?? '');
    tagsController = TextEditingController(text: widget.transaction['tags'] ?? '');
    notesController = TextEditingController(text: widget.transaction['notes'] ?? '');
    dateController = TextEditingController(text: widget.transaction['date'] ?? '');
    selectedType = widget.transaction['type'] ?? 'expense';
    if (!_types.contains(selectedType)) {
      selectedType = _types.first;
    }

    selectedCategory = widget.transaction['category'] ?? 'Other';
    if (!_categories.contains(selectedCategory)) {
      selectedCategory = _categories.first;
    }

    selectedCurrency = widget.transaction['currency'] ?? 'USD';
    final currencyCodes = _currencies.map((c) => c['code']).whereType<String>().toSet();
    if (!currencyCodes.contains(selectedCurrency)) {
      selectedCurrency = _currencies.first['code'];
    }
  }

  @override
  void dispose() {
    contentController.dispose();
    amountController.dispose();
    tagsController.dispose();
    notesController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final baseDate = DateTime.tryParse(dateController.text) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: baseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  void _saveTransaction() {
    final updatedTransaction = {
      ...widget.transaction,
      'content': contentController.text,
      'amount': double.parse(amountController.text),
      'type': selectedType,
      'category': selectedCategory,
      'currency': selectedCurrency,
      'tags': tagsController.text,
      'notes': notesController.text,
      'date': dateController.text,
    };
    widget.onSave(updatedTransaction);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Transaction'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: _currencies
                        .map((c) => DropdownMenuItem(
                              value: c['code'],
                              child: Text('${c['flag']} ${c['code']}'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedCurrency = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (value) => setState(() => selectedType = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: 'Date',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCategory = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveTransaction,
          child: const Text('Save'),
        ),
      ],
    );
  }
}