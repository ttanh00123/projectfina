import 'package:flutter_test/flutter_test.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/services/local_transaction_parser.dart';

void main() {
  group('LocalTransactionParser - Vietnamese Expenses', () {
    test('parses explicit verb expense with location', () {
      final result = LocalTransactionParser.parse(
        'Mua cafe 35k ở Circle K',
        defaultCurrency: 'VND',
        locale: 'vi',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.EXPENSE));
      expect(data.amount, equals(35000.0));
      expect(data.currency, equals('VND'));
      expect(data.category, equals(9)); // Food & Drink
      expect(data.note, equals('Circle K'));
      expect(data.content?.toLowerCase(), contains('cafe'));
    });

    test('parses explicit food verb and place', () {
      final result = LocalTransactionParser.parse(
        'Ăn trưa phở bò 45k tại Cầu Giấy',
        defaultCurrency: 'VND',
        locale: 'vi',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.EXPENSE));
      expect(data.amount, equals(45000.0));
      expect(data.category, equals(9)); // Food & Drink
      expect(data.note, equals('Cầu Giấy'));
      expect(data.content?.toLowerCase(), contains('phở bò'));
    });

    test('parses implicit expense without verbs (Item + Amount)', () {
      final result = LocalTransactionParser.parse(
        'Cafe 30k',
        defaultCurrency: 'VND',
        locale: 'vi',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.EXPENSE));
      expect(data.amount, equals(30000.0));
      expect(data.category, equals(9));
      expect(data.content?.toLowerCase(), contains('cafe'));
    });

    test('parses transport expenses', () {
      final result = LocalTransactionParser.parse(
        'Grab 32k đi làm',
        defaultCurrency: 'VND',
        locale: 'vi',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.EXPENSE));
      expect(data.amount, equals(32000.0));
      expect(data.category, equals(10)); // Transport
    });

    test('parses fuel expenses', () {
      final result = LocalTransactionParser.parse(
        'Đổ xăng 70k',
        defaultCurrency: 'VND',
        locale: 'vi',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.EXPENSE));
      expect(data.amount, equals(70000.0));
      expect(data.category, equals(13)); // Fuel
    });

    test('parses utility bills with million multiplier', () {
      final result = LocalTransactionParser.parse(
        'Tiền nhà 3.5tr',
        defaultCurrency: 'VND',
        locale: 'vi',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.EXPENSE));
      expect(data.amount, equals(3500000.0));
      expect(data.category, equals(28)); // Rent
    });

    test('parses electric bill', () {
      final result = LocalTransactionParser.parse(
        'Tiền điện 650k',
        defaultCurrency: 'VND',
        locale: 'vi',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.EXPENSE));
      expect(data.amount, equals(650000.0));
      expect(data.category, equals(29)); // Electricity
    });

    test('parses slang multipliers like củ and lít', () {
      final cuResult = LocalTransactionParser.parse(
        'Học phí 2 củ',
        defaultCurrency: 'VND',
        locale: 'vi',
      );
      expect(cuResult, isNotNull);
      expect(cuResult!.data.amount, equals(2000000.0));
      expect(cuResult.data.category, equals(31)); // Education

      final litResult = LocalTransactionParser.parse(
        'Ăn tối 3 lít',
        defaultCurrency: 'VND',
        locale: 'vi',
      );
      expect(litResult, isNotNull);
      expect(litResult!.data.amount, equals(300000.0));
      expect(litResult.data.category, equals(9));
    });

    test('parses relative date "hôm qua"', () {
      final result = LocalTransactionParser.parse(
        'Ăn trưa 50k hôm qua',
        defaultCurrency: 'VND',
        locale: 'vi',
      );

      expect(result, isNotNull);
      final data = result!.data;
      final parsedDate = DateTime.parse(data.dateTime);
      final now = DateTime.now();
      expect(parsedDate.day, equals(now.subtract(const Duration(days: 1)).day));
    });

    test('parses relative date "hôm kia" and "2 ngày trước"', () {
      final resHomKia = LocalTransactionParser.parse('Cafe 35k hôm kia');
      expect(resHomKia, isNotNull);
      final d1 = DateTime.parse(resHomKia!.data.dateTime);
      expect(d1.day, equals(DateTime.now().subtract(const Duration(days: 2)).day));

      final res2Ngay = LocalTransactionParser.parse('Mua áo 250k 2 ngày trước');
      expect(res2Ngay, isNotNull);
      expect(res2Ngay!.data.amount, equals(250000.0));
      expect(res2Ngay.data.category, equals(15)); // Clothing
      final d2 = DateTime.parse(res2Ngay.data.dateTime);
      expect(d2.day, equals(DateTime.now().subtract(const Duration(days: 2)).day));
    });

    test('parses internet and gym categories', () {
      final resNet = LocalTransactionParser.parse('Tiền mạng 300k');
      expect(resNet?.data.category, equals(12)); // Internet
      expect(resNet?.data.amount, equals(300000.0));

      final resGym = LocalTransactionParser.parse('Tập gym 500k');
      expect(resGym?.data.category, equals(23)); // Fitness
      expect(resGym?.data.amount, equals(500000.0));
    });
  });

  group('LocalTransactionParser - English Expenses', () {
    test('parses English verb expense with location', () {
      final result = LocalTransactionParser.parse(
        'Bought coffee for \$4.50 at Starbucks',
        defaultCurrency: 'USD',
        locale: 'en',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.EXPENSE));
      expect(data.amount, equals(4.50));
      expect(data.currency, equals('USD'));
      expect(data.category, equals(9)); // Food & Drink
      expect(data.note, equals('Starbucks'));
    });

    test('parses implicit English expense without verb (Kopi 1.80)', () {
      final result = LocalTransactionParser.parse(
        'Kopi 1.80',
        defaultCurrency: 'SGD',
        locale: 'en',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.EXPENSE));
      expect(data.amount, equals(1.80));
      expect(data.currency, equals('SGD'));
      expect(data.category, equals(9));
    });

    test('parses English lunch with SGD unit and food court location', () {
      final result = LocalTransactionParser.parse(
        'Lunch 12 SGD at food court',
        defaultCurrency: 'SGD',
        locale: 'en',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.EXPENSE));
      expect(data.amount, equals(12.0));
      expect(data.currency, equals('SGD'));
      expect(data.category, equals(9));
      expect(data.note, equals('food court'));
    });

    test('parses English rent payment', () {
      final result = LocalTransactionParser.parse(
        'Paid rent 800',
        defaultCurrency: 'SGD',
        locale: 'en',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.EXPENSE));
      expect(data.amount, equals(800.0));
      expect(data.category, equals(28)); // Rent
    });

    test('parses relative date "yesterday"', () {
      final result = LocalTransactionParser.parse(
        'Dinner 25 dollars yesterday',
        defaultCurrency: 'USD',
        locale: 'en',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.amount, equals(25.0));
      expect(data.currency, equals('USD'));
      final parsedDate = DateTime.parse(data.dateTime);
      final now = DateTime.now();
      expect(parsedDate.day, equals(now.subtract(const Duration(days: 1)).day));
    });
  });

  group('LocalTransactionParser - Income', () {
    test('parses Vietnamese salary', () {
      final result = LocalTransactionParser.parse(
        'Nhận lương 25 triệu',
        defaultCurrency: 'VND',
        locale: 'vi',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.INCOME));
      expect(data.amount, equals(25000000.0));
      expect(data.category, equals(1)); // Salary
    });

    test('parses Vietnamese bonus', () {
      final result = LocalTransactionParser.parse(
        'Thưởng tết 10tr',
        defaultCurrency: 'VND',
        locale: 'vi',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.INCOME));
      expect(data.amount, equals(10000000.0));
      expect(data.category, equals(2)); // Bonus
    });

    test('parses English salary', () {
      final result = LocalTransactionParser.parse(
        'Salary 3000 USD',
        defaultCurrency: 'USD',
        locale: 'en',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.INCOME));
      expect(data.amount, equals(3000.0));
      expect(data.currency, equals('USD'));
      expect(data.category, equals(1)); // Salary
    });

    test('parses English bonus', () {
      final result = LocalTransactionParser.parse(
        'Received bonus 500 dollars',
        defaultCurrency: 'USD',
        locale: 'en',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.INCOME));
      expect(data.amount, equals(500.0));
      expect(data.currency, equals('USD'));
      expect(data.category, equals(2)); // Bonus
    });
  });

  group('LocalTransactionParser - Transfers', () {
    test('parses Vietnamese transfer with source and destination', () {
      final result = LocalTransactionParser.parse(
        'Chuyển 500k từ VCB sang MoMo',
        defaultCurrency: 'VND',
        locale: 'vi',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.TRANSFER));
      expect(data.amount, equals(500000.0));
      expect(data.currency, equals('VND'));
      expect(data.content, contains('từ VCB'));
      expect(data.content, contains('đến MoMo'));
    });

    test('parses English transfer', () {
      final result = LocalTransactionParser.parse(
        'Transfer 200 from bank to cash',
        defaultCurrency: 'USD',
        locale: 'en',
      );

      expect(result, isNotNull);
      final data = result!.data;
      expect(data.type, equals(AppConstants.TRANSFER));
      expect(data.amount, equals(200.0));
      expect(data.content, contains('from bank'));
      expect(data.content, contains('to cash'));
    });
  });

  group('LocalTransactionParser - Formats and Currencies', () {
    test('parses currency symbols', () {
      final res1 = LocalTransactionParser.parse('\$15 lunch');
      expect(res1?.data.amount, equals(15.0));
      expect(res1?.data.currency, equals('USD'));

      final res2 = LocalTransactionParser.parse('S\$ 12.50 food');
      expect(res2?.data.amount, equals(12.50));
      expect(res2?.data.currency, equals('SGD'));

      final res3 = LocalTransactionParser.parse('₫100,000 mua sach');
      expect(res3?.data.amount, equals(100000.0));
      expect(res3?.data.currency, equals('VND'));

      final res4 = LocalTransactionParser.parse('50.000đ quan ao');
      expect(res4?.data.amount, equals(50000.0));
      expect(res4?.data.currency, equals('VND'));
    });
  });
}
