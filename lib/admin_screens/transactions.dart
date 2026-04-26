import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<dynamic> transactions = [];

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('enrollments')
          .select(
          'enrollment_id, enrolled_at, payment_status, payment_method, amount_paid, students(users(full_name, email)), courses(title)')
          .eq('payment_status', true)
          .order('enrolled_at', ascending: false);

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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
          ? const Center(child: Text('No transactions found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final t = transactions[index];
          final student = t['students']?['users'];
          final course = t['courses'];

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF5B6FF5),
                child: Icon(Icons.payment, color: Colors.white),
              ),
              title: Text(course?['title'] ?? 'Unknown Course'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Student: ${student?['full_name'] ?? 'Unknown'}'),
                  Text('Email: ${student?['email'] ?? '-'}'),
                  Text('Payment: ${t['payment_method'] ?? '-'}'),
                  Text('Date: ${t['enrolled_at'] ?? '-'}'),
                ],
              ),
              trailing: Text(
                'RM ${t['amount_paid'] ?? 0}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}