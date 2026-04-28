import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<dynamic> transactions = [];
  String formatDate(String? value) {
    if (value == null) return '-';
    return value.replaceFirst('T', ' ').split('.').first;
  }
  String filter = 'All';
  final filters = ['All', 'Paid', 'Unpaid'];

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<File> createCSVFile() async {
    String csv = 'Student,Email,Course,Amount,Payment Method,Status,Date\n';

    for (var t in transactions) {
      final enrollment = t['enrollments'];
      final student = enrollment?['users'];
      final course = enrollment?['courses'];
      final status = t['payment_status'] == true ? 'Paid' : 'Unpaid';

      csv +=
      '${student?['full_name'] ?? ''},'
          '${student?['email'] ?? ''},'
          '${course?['title'] ?? ''},'
          '${t['amount_paid'] ?? 0},'
          '${t['payment_method'] ?? ''},'
          '$status,'
          '${t['transaction_date'] ?? ''}\n';
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.csv',
    );

    return file.writeAsString(csv);
  }

  Future<void> shareCSV() async {
    try {
      final file = await createCSVFile();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Transaction Report',
      );
    } catch (e) {
      showMessage('Share failed: $e');
    }
  }

  Future<void> downloadCSV() async {
    try {
      final csvFile = await createCSVFile();

      final downloadDir = Directory('/storage/emulated/0/Download');
      final savedFile = File(
        '${downloadDir.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      await savedFile.writeAsString(await csvFile.readAsString());

      showMessage('Saved to Downloads folder');
    } catch (e) {
      showMessage('Download failed: $e');
    }
  }

  Future<void> fetchTransactions() async {
    setState(() => _isLoading = true);

    try {
      var query = supabase
          .from('transaction')
          .select(
        'transaction_id, payment_status, payment_method, amount_paid, transaction_date, enrollments(enrollment_id, users(full_name, email), courses(title))',
      );

      if (filter == 'Paid') {
        query = query.eq('payment_status', true);
      } else if (filter == 'Unpaid') {
        query = query.eq('payment_status', false);
      }

      final response = await query.order('transaction_date', ascending: false);

      setState(() {
        transactions = response;
      });
    } catch (e) {
      showMessage('Error loading transactions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: const Color(0xFF5B6FF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: fetchTransactions,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: downloadCSV,
            icon: const Icon(Icons.download),
          ),
          IconButton(
            onPressed: shareCSV,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: filter,
              decoration: const InputDecoration(
                labelText: 'Filter Payment',
                border: OutlineInputBorder(),
              ),
              items: filters.map((f) {
                return DropdownMenuItem(value: f, child: Text(f));
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => filter = value);
                fetchTransactions();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                ? const Center(child: Text('No transactions found.'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final t = transactions[index];
                final enrollment = t['enrollments'];
                final student = enrollment?['users'];
                final course = enrollment?['courses'];
                final isPaid = t['payment_status'] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPaid ? Colors.green : Colors.red,
                      child: Icon(
                        isPaid ? Icons.check : Icons.close,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(course?['title'] ?? 'Unknown Course'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Student: ${student?['full_name'] ?? 'Unknown'}'),
                        Text('Email: ${student?['email'] ?? '-'}'),
                        Text('Payment: ${t['payment_method'] ?? '-'}'),
                        Text('Status: ${isPaid ? 'Paid' : 'Unpaid'}'),
                        Text('Date: ${formatDate(t['transaction_date'])}'),
                      ],
                    ),
                    trailing: Text(
                      'RM ${t['amount_paid'] ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPaid ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}