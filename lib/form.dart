import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';
import 'speech_service.dart'; // adjust path if needed, e.g. 'package:yourapp/speech_service.dart'
import 'session.dart';

class AddTransaction extends StatefulWidget {
  const AddTransaction({super.key});

  @override
  _AddTransactionState createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  final TextEditingController promptController = TextEditingController();

  // --- Speech service fields ---
  final SpeechService _speechService = SpeechService();
  bool _speechAvailable = false; // true after successful init
  bool _isListening = false; // local listening state
  // --------------------------------

  Map<String, dynamic>? generatedTransaction;
  bool _isGenerating = false;
  bool _isPosting = false;
  String? _error;

  Future<void> _generateTransaction() async {
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) return;
    if (mounted) {
      setState(() {
        _isGenerating = true;
        _error = null;
        generatedTransaction = null;
      });
    }

    try {
      final url = Uri.parse('http://160.191.101.179:8000/generate');
      final resp = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'prompt': prompt}));
      if (resp.statusCode == 200) {
        final respText = resp.body;
        dynamic body;
        // Try decode JSON directly first
        try {
          body = json.decode(respText);
        } catch (_) {
          // If direct decode fails, try to extract a JSON object or array substring
          final objMatch = RegExp(r"\{[\s\S]*\}").firstMatch(respText);
          final arrMatch = RegExp(r"\[[\s\S]*\]").firstMatch(respText);
          String? jsonPart;
          if (objMatch != null)
            jsonPart = objMatch.group(0);
          else if (arrMatch != null) jsonPart = arrMatch.group(0);

          if (jsonPart != null) {
            try {
              body = json.decode(jsonPart);
            } catch (e2) {
              // Try replacing single quotes with double quotes as a last resort
              try {
                final alt = jsonPart.replaceAll("'", '"');
                body = json.decode(alt);
              } catch (e3) {
                body = respText; // give up, keep raw text
              }
            }
          } else {
            body = respText; // no JSON substring found
          }
        }

        Map<String, dynamic>? tx;
        if (body is Map<String, dynamic>) {
          tx = body;
        } else if (body is List && body.isNotEmpty && body[0] is Map) {
          tx = Map<String, dynamic>.from(body[0]);
        } else if (body is String) {
          // Maybe the model returned a JSON string inside text
          try {
            final parsed = json.decode(body);
            if (parsed is Map<String, dynamic>) tx = parsed;
          } catch (_) {
            // no-op
          }
        }

        if (tx == null)
          throw Exception('Unexpected response format: $respText');

        if (mounted) {
          setState(() {
            generatedTransaction = tx;
            _isGenerating = false;
          });
        }
      } else {
        throw Exception('Generation failed: ${resp.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _confirmAddTransaction() async {
    if (generatedTransaction == null) return;
    if (mounted) {
      setState(() {
        _isPosting = true;
        _error = null;
      });
    }

    try {
      final userId = Session.userId;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isPosting = false;
            _error = 'Please log in again to add transactions.';
          });
        }
        return;
      }

      final token = Session.token;
      final url = Uri.parse('http://160.191.101.179:8000/addTransaction');
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          ...generatedTransaction!,
          'user_id': userId,
        }),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (mounted) {
          setState(() {
            _isPosting = false;
          });
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Transaction added.')));
        Navigator.pop(context);
      } else {
        throw Exception('Failed to add: ${resp.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPosting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // init speech-to-text
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speechService.init();
      if (mounted) {
        setState(() {
          _speechAvailable = ok;
        });
      }
    } catch (e) {
      // keep _speechAvailable false; optionally log
      debugPrint('Speech init failed: $e');
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      // optionally show message to user
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Speech not available')));
      return;
    }

    if (_isListening) {
      await _speechService.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    // Start listening; onResult receives recognized text and whether it's final
    await _speechService.start((recognizedText, isFinal) {
      if (mounted) {
        setState(() {
          // Update the prompt text but keep the caret at end
          promptController.text = recognizedText;
          promptController.selection = TextSelection.fromPosition(
              TextPosition(offset: recognizedText.length));
        });

        // Optionally auto-generate when final result arrives:
        if (isFinal) {
          // stop listening visual state
          _speechService.stop();
          _isListening = false;
          // Optionally trigger generation automatically:
          // _generateTransaction();
        }
      }
    });

    if (mounted) setState(() => _isListening = true);
  }

  @override
  void dispose() {
    promptController.dispose();
    // Ensure speech stopped and resources released
    if (_speechService.isListening) {
      _speechService.stop();
    }
    super.dispose();
  }

  List<Widget> _buildTransactionDetails(Map<String, dynamic> transaction) {
    final widgets = <Widget>[];
    
    transaction.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${key}: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: value.toString(),
                    style: const TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });
    
    return widgets.isEmpty
        ? [const Text('No transaction data generated')]
        : widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Generate Transaction')),
      body: Column(
        children: [
          // Button to switch to manual form
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SecondRoute()),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Switch to Manual Form'),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: promptController,
                      decoration: InputDecoration(
                        labelText: 'Describe the transaction',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening ? Colors.red : null),
                          onPressed: _toggleListening,
                          tooltip: _isListening
                              ? 'Stop listening'
                              : 'Start voice input',
                        ),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _isGenerating ? null : _generateTransaction,
                        child: _isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Generate'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text('Error: $_error',
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  if (generatedTransaction != null) ...[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Generated Transaction',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              ..._buildTransactionDetails(generatedTransaction!),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isPosting ? null : _confirmAddTransaction,
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(
                                      Colors.green),
                            ),
                            child: _isPosting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white)),
                                  )
                                : const Text('Confirm'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SecondRoute(
                                    initialTransaction: generatedTransaction,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Continue to Edit'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

class SecondRoute extends StatefulWidget {
  final Map<String, dynamic>? initialTransaction;

  const SecondRoute({super.key, this.initialTransaction});

  @override
  _SecondRouteState createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Text editing controllers
  final TextEditingController textController1 = TextEditingController();
  final TextEditingController textController2 = TextEditingController();
  final TextEditingController textController3 = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController finalTextController = TextEditingController();

  // Drop-down values
  Map<String, String>? dropdownValue0;
  String? dropdownValue1;
  String? dropdownValue2;
  String? dropdownValue3;

  // Currency data
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
    if (widget.initialTransaction != null) {
      textController1.text = widget.initialTransaction!['content'] ?? '';
      textController2.text = widget.initialTransaction!['amount']?.toString() ?? '';
      
      // Use current date if no date provided
      String dateValue = widget.initialTransaction!['date'] ?? '';
      if (dateValue.isEmpty) {
        dateValue = DateTime.now().toString().split(' ')[0];
      }
      dateController.text = dateValue;
      
      finalTextController.text = widget.initialTransaction!['notes'] ?? '';

      final currencyCode = widget.initialTransaction!['currency'];
      if (currencyCode != null) {
        try {
          dropdownValue0 = _currencies.firstWhere(
            (c) => c['code'] == currencyCode,
          );
        } catch (e) {
          dropdownValue0 = null; // Invalid currency code
        }
      }

      final type = widget.initialTransaction!['type'];
      if (type != null && ['income', 'expense'].contains(type)) {
        dropdownValue1 = type;
      }

      final category = widget.initialTransaction!['category'];
      final validCategories = ['Food & Drinks', 'Education', 'Transportation', 'Health', 'Entertainment', 'Utilities', 'Devices', 'Others'];
      if (category != null && validCategories.contains(category)) {
        dropdownValue2 = category;
      }

      final tags = widget.initialTransaction!['tags'];
      final validTags = ['Personal', 'Family', 'Work'];
      if (tags != null && validTags.contains(tags)) {
        dropdownValue3 = tags;
      }
    } else {
      // Set default date if no initial transaction
      dateController.text = DateTime.now().toString().split(' ')[0];
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    // Prevent duplicate submissions
    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
    });

    final userId = Session.userId;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please log in before adding transactions.')),
        );
      }
      return;
    }

    final token = Session.token;
    final url = Uri.parse('http://160.191.101.179:8000/addTransaction');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'content': textController1.text,
          'currency': dropdownValue0!['code'],
          'amount': textController2.text,
          'type': dropdownValue1,
          'date': dateController.text,
          'category': dropdownValue2,
          'tags': dropdownValue3,
          'notes': finalTextController.text,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added.')),
        );
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const Home()));
      } else {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to submit form (${response.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit form: $e')),
      );
    }
  }

  List<Widget> _buildGeneratedDataDisplay() {
    if (widget.initialTransaction == null) {
      return [];
    }

    final widgets = <Widget>[
      const Divider(thickness: 2),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Generated Transaction Data:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    ];

    widget.initialTransaction!.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$key: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: value.toString(),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });

    widgets.add(const Divider(thickness: 2));
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Column(
        children: [
          // Button to switch to AI form - only show if not editing AI-generated transaction
          if (widget.initialTransaction == null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddTransaction()),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Switch to AI Form'),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Display generated transaction data if available
                      ..._buildGeneratedDataDisplay(),
                      TextFormField(
                        controller: textController1,
                        decoration: InputDecoration(
                          labelText: 'Content',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          // Currency Dropdown
                          Expanded(
                            flex: 2, // Adjusts the width ratio for dropdown
                            child: DropdownButtonFormField<Map<String, String>>(
                              decoration: InputDecoration(
                                labelText: 'Currency',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 16),
                              ),
                              isExpanded: true,
                              value: dropdownValue0,
                              items: _currencies
                                  .map((currency) => DropdownMenuItem(
                                        value: currency,
                                        child: Row(
                                          children: [
                                            Text(currency['flag']!),
                                            SizedBox(width: 8),
                                            Text(currency['code']!),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  dropdownValue0 = value;
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Please select a currency'
                                  : null,
                              selectedItemBuilder: (context) => _currencies
                                  .map((currency) => Row(
                                        children: [
                                          Text(currency['flag']!),
                                          SizedBox(width: 8),
                                          Text(currency['code']!),
                                        ],
                                      ))
                                  .toList(),
                            ),
                          ),
                          SizedBox(
                              width:
                                  10), // Margin between dropdown and text field
                          // Amount Text Field
                          Expanded(
                            flex: 5, // Adjusts the width ratio for text field
                            child: TextFormField(
                              controller: textController2,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an amount';
                                }
                                final n = num.tryParse(value);
                                if (n == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        value: dropdownValue1,
                        items: ['income', 'expense']
                            .map((option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            dropdownValue1 =
                                value; // Update dropdownValue1 when a new value is selected
                          });
                        },
                        validator: (value) => value == null
                            ? 'Please select the transaction type'
                            : null,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          labelText: 'Select Date',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        value: dropdownValue2,
                        items: ['Food & Drinks', 'Education', 'Transportation', 'Health', 'Entertainment', 'Utilities', 'Devices', 'Others']
                            .map((option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            dropdownValue2 =
                                value; // Update dropdownValue1 when a new value is selected
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a category' : null,
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Tags',
                          border: OutlineInputBorder(),
                        ),
                        value: dropdownValue3,
                        items: ['Personal', 'Family', 'Work']
                            .map((option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            dropdownValue3 =
                                value; // Update dropdownValue1 when a new value is selected
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a tag' : null,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: finalTextController,
                        decoration: InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Redirect back to Home without stacking another route
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const Home()));
                            },
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                  side: BorderSide(
                                      color: const Color.fromRGBO(
                                          255, 203, 54, 244)),
                                ),
                              ),
                            ),
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : () async {
                              if (_formKey.currentState!.validate()) {
                                await _submitForm();
                              }
                            },
                            style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return Colors.grey;
                                  }
                                  return const Color.fromARGB(255, 203, 54, 244);
                                },
                              ),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                  side: BorderSide(
                                      color: const Color.fromARGB(
                                          255, 203, 54, 244)),
                                ),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white)),
                                  )
                                : const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
