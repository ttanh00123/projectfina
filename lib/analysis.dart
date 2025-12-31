import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'session.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

enum TimeFrame { day, week, month, year }

class _AnalysisPageState extends State<AnalysisPage> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  TimeFrame _selectedTimeFrame = TimeFrame.month;
  Map<String, double> _spendingData = {};

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final userId = Session.userId;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final transactionsResponse = await http.get(
        Uri.parse('http://127.0.0.1:8001/transactions?user_id=$userId'),
      );

      if (transactionsResponse.statusCode != 200) {
        throw Exception('Failed to fetch transactions');
      }

      final List<dynamic> transactions = json.decode(transactionsResponse.body);
      print('Fetched transactions: $transactions');

      setState(() {
        _transactions = transactions;
        _isLoading = false;
        _updateSpendingData();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error fetching transactions: $e');
    }
  }

  void _updateSpendingData() {
    _spendingData.clear();

    for (var transaction in _transactions) {
      try {
        // Parse amount and date from transaction
        final amount = double.parse(transaction['amount'].toString());
        final dateStr = transaction['date'] as String;
        final date = DateTime.parse(dateStr);

        String key;
        switch (_selectedTimeFrame) {
          case TimeFrame.day:
            key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour}:00';
            break;
          case TimeFrame.week:
            final weekStart = date.subtract(Duration(days: date.weekday - 1));
            key =
                '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
            break;
          case TimeFrame.month:
            key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            break;
          case TimeFrame.year:
            key = '${date.year}';
            break;
        }

        _spendingData[key] = (_spendingData[key] ?? 0) + amount;
      } catch (e) {
        print('Error parsing transaction: $e');
      }
    }

    // Sort by date
    final sortedEntries = _spendingData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    _spendingData = Map.fromEntries(sortedEntries);
  }

  List<FlSpot> _getChartSpots() {
    final entries = _spendingData.entries.toList();
    return List.generate(
      entries.length,
      (index) => FlSpot(index.toDouble(), entries[index].value),
    );
  }

  List<String> _getXAxisLabels() {
    return _spendingData.keys.map((key) {
      switch (_selectedTimeFrame) {
        case TimeFrame.day:
          return key.split(' ')[1]; // Return hour
        case TimeFrame.week:
          return key;
        case TimeFrame.month:
          return key;
        case TimeFrame.year:
          return key;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analysis'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(
                  child: Text(
                    'No transactions available',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Time Frame:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Day'),
                                selected: _selectedTimeFrame == TimeFrame.day,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedTimeFrame = TimeFrame.day;
                                    _updateSpendingData();
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Week'),
                                selected: _selectedTimeFrame == TimeFrame.week,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedTimeFrame = TimeFrame.week;
                                    _updateSpendingData();
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Month'),
                                selected: _selectedTimeFrame == TimeFrame.month,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedTimeFrame = TimeFrame.month;
                                    _updateSpendingData();
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Year'),
                                selected: _selectedTimeFrame == TimeFrame.year,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedTimeFrame = TimeFrame.year;
                                    _updateSpendingData();
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _spendingData.isEmpty
                            ? const Center(
                                child: Text(
                                  'No spending data for this time frame',
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            : BarChart(
                                BarChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: 50,
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        getTitlesWidget: (value, meta) {
                                          final labels = _getXAxisLabels();
                                          if (value.toInt() < 0 || value.toInt() >= labels.length) {
                                            return const SizedBox();
                                          }
                                          return Transform.rotate(
                                            angle: -0.5,
                                            child: Text(
                                              labels[value.toInt()],
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 50,
                                        reservedSize: 42,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            '${value.toInt()}',
                                            style: const TextStyle(fontSize: 10),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  barGroups: _getChartSpots()
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => BarChartGroupData(
                                          x: entry.key,
                                          barRods: [
                                            BarChartRodData(
                                              toY: entry.value.y,
                                              color: Colors.blue,
                                              width: 12,
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                                  minY: 0,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}