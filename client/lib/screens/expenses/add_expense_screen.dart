import 'package:flutter/material.dart';

class AddExpenseScreen extends StatefulWidget {
  final List<Map<String, dynamic>> groupMembers; // Pass from parent screen
  final String currentUserId;

  const AddExpenseScreen({
    super.key,
    required this.groupMembers,
    required this.currentUserId,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String? paidBy;
  Set<String> splitBetween = {};

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

  void _submitExpense() {
    final description = _descController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (description.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid description and amount")),
      );
      return;
    }

    if (paidBy == null || splitBetween.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select payer and split members")),
      );
      return;
    }

    // TODO: Send to backend
    print("Submitting:");
    print("Desc: $description");
    print("Amount: $amount");
    print("Paid by: $paidBy");
    print("Split among: $splitBetween");
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
