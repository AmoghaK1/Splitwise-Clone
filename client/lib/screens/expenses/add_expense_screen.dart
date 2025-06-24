import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddExpenseScreen extends StatefulWidget {
  final List<Map<String, dynamic>> groupMembers; // Pass from parent screen
  final String currentUserId;
  final String groupId;
  const AddExpenseScreen({
    super.key,
    required this.groupMembers,
    required this.currentUserId,
    required this.groupId,
  });

 
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String? paidBy;
  Set<String> splitBetween = {};

  Future<void> _submitExpense() async {
    final description = _descController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (description.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid description and amount")),
      );
      return;
    }

    if (paidBy == null || splitBetween.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select payer and split members")),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user!.getIdToken();

      final response = await http.post(
        Uri.parse('http://192.168.1.5:3000/groups/${widget.groupId}/expenses'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "description": description,
          "amount": amount,
          "paidBy": paidBy,
          "splitBetween": splitBetween.toList(),
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context); // Close screen after success
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Unknown error';
        throw Exception(error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit: ${e.toString()}")),
      );
    }
  }



  @override
  void initState() {
    super.initState();
    paidBy = widget.currentUserId;
    splitBetween = widget.groupMembers.map((m) => m['_id'].toString()).toSet(); // all by default
  }

  void _showPaidByDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          children: widget.groupMembers.map((member) {
            return RadioListTile(
              title: Text(member['name']),
              value: member['_id'],
              groupValue: paidBy,
              onChanged: (val) {
                setState(() => paidBy = val);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showSplitDialog() {
    final tempSelection = Set<String>.from(splitBetween);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Split Between'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            children: widget.groupMembers.map((member) {
              return CheckboxListTile(
                title: Text(member['name']),
                value: tempSelection.contains(member['_id']),
                onChanged: (bool? selected) {
                  setState(() {
                    if (selected == true) {
                      tempSelection.add(member['_id']);
                    } else {
                      tempSelection.remove(member['_id']);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => splitBetween = tempSelection);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add expense"),
        backgroundColor: Colors.teal[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submitExpense,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Enter a description',
                prefixIcon: Icon(Icons.receipt),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '₹ Amount',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text("Paid by "),
                TextButton(
                  onPressed: _showPaidByDialog,
                  child: Text(widget.groupMembers.firstWhere((m) => m['_id'] == paidBy)['name']),
                ),
                const Text(" and split "),
                TextButton(
                  onPressed: _showSplitDialog,
                  child: Text(splitBetween.length == widget.groupMembers.length
                      ? "equally"
                      : "custom"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
