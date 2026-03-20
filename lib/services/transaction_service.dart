Future<Map<String, dynamic>> saveTransaction(
      Map<String, dynamic> data, String token) async {
    // final r = await http.post(
    //   Uri.parse('${AppConfig.baseUrl}/transactions'),
    //   headers: _authH(token),
    //   body: jsonEncode(data),
    // ).timeout(const Duration(seconds: 15));
    // if (r.statusCode == 201) return jsonDecode(r.body);
    // throw ApiException(_extractError(r), statusCode: r.statusCode);
    return Future.delayed(const Duration(seconds: 2), () {
      return {
        'id': 123,
        'type': data['type'],
        'amount': data['amount'],
        'category': data['category'],
        'note': data['note'],
        'date_time': data['date_time'],
      };
    });
}

Future<List<dynamic>> getTransactions(String token,
    {int limit = 50, int offset = 0}) async {
  // final r = await http.get(
  //   Uri.parse('${AppConfig.baseUrl}/transactions?limit=$limit&offset=$offset'),
  //   headers: _authH(token),
  // ).timeout(const Duration(seconds: 15));
  // if (r.statusCode == 200) return jsonDecode(r.body);
  // throw ApiException(_extractError(r), statusCode: r.statusCode);
  return Future.delayed(const Duration(seconds: 2), () {
    return List.generate(10, (index) => {
      'id': index,
      'type': index % 2 == 0 ? 'expense' : 'income',
      'amount': (index + 1) * 10000,
      'category': 'Category ${index % 5}',
      'note': 'Note for transaction $index',
      'date_time': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
    });
  });
}