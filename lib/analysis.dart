import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'session.dart';
class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  Uint8List? _chartImage;
  bool _isLoading = true;

  // Function to fetch the pie chart image
  Future<void> fetchPieChart(String chartType) async {
  try {
    final userId = Session.userId;
    if (userId == null) {
      setState(() { _isLoading = false; });
      return;
    }
    // Step 1: Fetch transactions from '/transactions'
    final transactionsResponse = await http.get(Uri.parse('http://127.0.0.1:8001/transactions?user_id=$userId'));
    if (transactionsResponse.statusCode != 200) {
      throw Exception('Failed to fetch transactions');
    }

    // Parse the transactions data
    final List<dynamic> transactions = json.decode(transactionsResponse.body);
    print('Fetched transactions: $transactions');

    // Step 2: Send transactions to '/pie_chart' via POST
    final pieChartResponse = await http.post(
      Uri.parse('http://127.0.0.1:8000/pie_chart'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'transactions': transactions, // Send transactions as JSON
        'chartType': chartType.toString(),       // Include the additional parameter
      }), // Send transactions as JSON
    );

    if (pieChartResponse.statusCode == 200) {
      setState(() {
        _chartImage = pieChartResponse.bodyBytes; // Get the image bytes
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load pie chart');
    }
  } catch (e) {  if (mounted) {
    setState(() {
      _isLoading = false;
    });
  }
    print('Error fetching pie chart: $e');
  }
}

  @override
  void initState() {
    super.initState();
    fetchPieChart('category'); // Fetch the pie chart when the page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show a loading spinner while fetching data
          : _chartImage == null
              ? const Center(
                  child: Text(
                    'Failed to load pie chart',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ) // Show an error message if the chart fails to load
              : Center(
                  child: Image.memory(
                    _chartImage!,
                    fit: BoxFit.contain,
                  ),
                ), // Display the pie chart
    );
  }
}