import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/scheduler.dart';
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
  
  // Line chart data
  Map<String, double> _lineChartData = {};
  List<FlSpot> _lineSpots = [];
  List<String> _lineLabels = [];
  
  // Pie chart data (now storing amounts, not counts)
  Map<String, double> _categoryAmount = {};
  Map<String, double> _tagAmount = {};

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
        Uri.parse('http://api.conaudio.vn:8000/transactions?user_id=$userId'),
      );

      if (transactionsResponse.statusCode != 200) {
        throw Exception('Failed to fetch transactions');
      }

      final List<dynamic> transactions = json.decode(transactionsResponse.body);
      print('Fetched transactions: $transactions');

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _processAllData();
          if (mounted) setState(() {});
        });
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

  void _processAllData() {
    _lineChartData.clear();
    _categoryAmount.clear();
    _tagAmount.clear();
    _lineLabels.clear();

    // Build ordered maps for line chart based on timeframe
    Map<String, double> orderedData = {};
    Map<String, String> keyToLabel = {};

    for (var transaction in _transactions) {
      try {
        final amount = double.parse(transaction['amount'].toString());
        final dateStr = transaction['date'] as String;
        final date = DateTime.parse(dateStr);
        final category = transaction['category']?.toString() ?? 'Uncategorized';
        final tags = transaction['tags'];
        final isIncome = transaction['type']?.toString().toLowerCase() == 'income';

        // Process line chart data
        String timeKey;
        String timeLabel;
        switch (_selectedTimeFrame) {
          case TimeFrame.day:
            timeKey = '${date.hour.toString().padLeft(2, '0')}:00';
            timeLabel = timeKey;
            break;
          case TimeFrame.week:
            final dayOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
            timeKey = date.weekday.toString().padLeft(2, '0');
            timeLabel = dayOfWeek;
            break;
          case TimeFrame.month:
            final weekNum = ((date.day - 1) ~/ 7) + 1;
            timeKey = weekNum.toString().padLeft(2, '0');
            timeLabel = 'Week $weekNum';
            break;
          case TimeFrame.year:
            final monthName = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
            timeKey = date.month.toString().padLeft(2, '0');
            timeLabel = monthName;
            break;
        }

        orderedData[timeKey] = (orderedData[timeKey] ?? 0) + amount;
        keyToLabel[timeKey] = timeLabel;

        // Process category pie chart (sum amounts)
        if (!isIncome) {
          _categoryAmount[category] = (_categoryAmount[category] ?? 0) + amount;
        }

        // Process tag pie chart (sum amounts)
        if (!isIncome && tags is List) {
          for (var tag in tags) {
            final tagStr = tag.toString();
            _tagAmount[tagStr] = (_tagAmount[tagStr] ?? 0) + amount;
          }
        }
      } catch (e) {
        print('Error processing transaction: $e');
      }
    }

    // Build sorted line chart data
    final sortedKeys = orderedData.keys.toList()..sort();
    _lineSpots = [];
    _lineLabels = [];
    
    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      _lineSpots.add(FlSpot(i.toDouble(), orderedData[key]!));
      _lineLabels.add(keyToLabel[key]!);
    }
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeframe Dropdown
                      DropdownButton<TimeFrame>(
                        value: _selectedTimeFrame,
                        items: TimeFrame.values.map((frame) {
                          return DropdownMenuItem(
                            value: frame,
                            child: Text(frame.toString().split('.').last.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (newFrame) {
                          if (newFrame != null) {
                            _selectedTimeFrame = newFrame;
                            SchedulerBinding.instance.addPostFrameCallback((_) {
                              _processAllData();
                              if (mounted) setState(() {});
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Line Chart - Spending Over Time
                      const Text(
                        'Amount Spent Over Time',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 300,
                        child: _lineSpots.isEmpty
                            ? const Center(
                                child: Text('No data for this timeframe'),
                              )
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true),
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
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 || index >= _lineLabels.length) {
                                            return const SizedBox();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              _lineLabels[index],
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            '\$${value.toInt()}',
                                            style: const TextStyle(fontSize: 10),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _lineSpots,
                                      isCurved: true,
                                      color: Colors.blue,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: true),
                                    ),
                                  ],
                                  minY: 0,
                                ),
                              ),
                      ),
                      const SizedBox(height: 32),

                      // Category Pie Chart
                      const Text(
                        'Transactions by Category',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 300,
                        child: _categoryAmount.isEmpty
                            ? const Center(child: Text('No category data'))
                            : PieChart(
                                PieChartData(
                                  sections: _buildPieSections(_categoryAmount),
                                  centerSpaceRadius: 40,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      _buildPieLegend(_categoryAmount),
                      const SizedBox(height: 32),

                      // Tags Pie Chart
                      const Text(
                        'Transactions by Tags',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 300,
                        child: _tagAmount.isEmpty
                            ? const Center(child: Text('No tag data'))
                            : PieChart(
                                PieChartData(
                                  sections: _buildPieSections(_tagAmount),
                                  centerSpaceRadius: 40,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      _buildPieLegend(_tagAmount),
                    ],
                  ),
                ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> data) {
    final total = data.values.fold<double>(0, (sum, val) => sum + val);
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];

    return data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final percentage = (item.value / total) * 100;

      return PieChartSectionData(
        value: item.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[index % colors.length],
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildPieLegend(Map<String, double> data) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: data.entries.toList().asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text('${item.key} (\$${item.value.toStringAsFixed(2)})'),
          ],
        );
      }).toList(),
    );
  }
}