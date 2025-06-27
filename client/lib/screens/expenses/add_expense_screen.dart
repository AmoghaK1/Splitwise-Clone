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
  // Add state for unequal splitting
  String splitType = 'equal';
  String unequal_splitType = 'amount'; // 'amount' or 'percentage'
  Map<String, double> unequalShares = {};
  double totalAmount = 0.0;

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
    }    // Validate for unequal splits
    if (splitType == 'unequal') {
      // Make sure we have valid splits
      double totalShareAmount = 0.0;
      for (var id in splitBetween) {
        totalShareAmount += unequalShares[id] ?? 0.0;
      }
      
      if ((totalShareAmount - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("The sum of all shares must equal the total amount")),
        );
        return;
      }
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
          "splitType": splitType,
          "unequalShares": splitType == 'unequal' ? unequalShares : null,
          "splitMethod": splitType == 'unequal' ? unequal_splitType : null,
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
    
    // Initialize unequal shares with zero values for all members
    for (var member in widget.groupMembers) {
      unequalShares[member['_id']] = 0.0;
    }
    
    // Listen for amount changes to update calculations
    _amountController.addListener(_updateTotalAmount);
  }
  
  @override
  void dispose() {
    _amountController.removeListener(_updateTotalAmount);
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }
  
  void _updateTotalAmount() {
    setState(() {
      totalAmount = double.tryParse(_amountController.text) ?? 0.0;
      // If using percentages, we need to recalculate the actual amounts
      if (unequal_splitType == 'percentage' && splitType == 'unequal') {
        _recalculateAmountsFromPercentages();
      }
    });
  }
  
  void _recalculateAmountsFromPercentages() {
    if (totalAmount <= 0) return;
    
    for (var member in widget.groupMembers) {
      String id = member['_id'];
      double percentage = unequalShares[id] ?? 0.0;
      unequalShares[id] = (percentage / 100) * totalAmount;
    }
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
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Select Members for Equal Split'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                children: [
                  Text(
                    'Selected: ${tempSelection.length} of ${widget.groupMembers.length} members',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            tempSelection.clear();
                            tempSelection.addAll(widget.groupMembers.map((m) => m['_id'].toString()));
                          });
                        },
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            tempSelection.clear();
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: widget.groupMembers.map((member) {
                        final isSelected = tempSelection.contains(member['_id']);
                        return CheckboxListTile(
                          title: Text(member['name']),
                          subtitle: Text(member['email'] ?? ''),
                          value: isSelected,
                          onChanged: (bool? selected) {
                            setDialogState(() {
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Cancel')
              ),
              ElevatedButton(
                onPressed: tempSelection.isEmpty ? null : () {
                  setState(() => splitBetween = tempSelection);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          );
        }
      ),
    );
  }
  // Show dialog to select split type (equal or unequal)
  void _showSplitTypeDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.balance),
              title: const Text('Split equally among all members'),
              subtitle: const Text('Split between all group members equally'),
              onTap: () {
                setState(() {
                  splitType = 'equal';
                  splitBetween = widget.groupMembers.map((m) => m['_id'].toString()).toSet();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Split equally among selected members'),
              subtitle: const Text('Choose specific members to split equally'),
              onTap: () {
                setState(() => splitType = 'equal');
                Navigator.pop(context);
                _showSplitDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text('Split by exact amounts'),
              subtitle: const Text('Enter specific amounts for each member'),
              onTap: () {
                setState(() {
                  splitType = 'unequal';
                  unequal_splitType = 'amount';
                });
                Navigator.pop(context);
                _showUnequalSplitDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.percent),
              title: const Text('Split by percentages'),
              subtitle: const Text('Enter percentage shares for each member'),
              onTap: () {
                setState(() {
                  splitType = 'unequal';
                  unequal_splitType = 'percentage';
                });
                Navigator.pop(context);
                _showUnequalSplitDialog();
              },
            ),
          ],
        );
      },
    );
  }

  // Show dialog for unequal splitting (by amount or percentage)
  void _showUnequalSplitDialog() {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0 && unequal_splitType == 'percentage') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount first")),
      );
      return;
    }
    
    final tempShares = Map<String, double>.from(unequalShares);
    double totalEntered = 0.0;
    final List<TextEditingController> controllers = 
        widget.groupMembers.map((_) => TextEditingController()).toList();
    
    // Initialize controllers with current values
    for (int i = 0; i < widget.groupMembers.length; i++) {
      String id = widget.groupMembers[i]['_id'];
      controllers[i].text = tempShares[id]?.toString() ?? "0";
    }
    
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Calculate total entered
          void recalculateTotal() {
            totalEntered = 0.0;
            for (int i = 0; i < widget.groupMembers.length; i++) {
              String id = widget.groupMembers[i]['_id'];
              tempShares[id] = double.tryParse(controllers[i].text) ?? 0.0;
              totalEntered += tempShares[id] ?? 0.0;
            }
            setDialogState(() {});
          }
          
          // Set initial values
          for (int i = 0; i < controllers.length; i++) {
            controllers[i].addListener(recalculateTotal);
          }
          
          recalculateTotal(); // Initial calculation
          
          return AlertDialog(
            title: Text('Split by ${unequal_splitType == 'amount' ? 'Amount' : 'Percentage'}'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300, // Fixed height for scroll
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total: ${unequal_splitType == 'amount' ? '₹$amount' : '100%'}'),
                      Text(
                        '${unequal_splitType == 'amount' ? 'Entered' : 'Allocated'}: ${unequal_splitType == 'amount' ? '₹$totalEntered' : '$totalEntered%'}', 
                        style: TextStyle(
                          color: unequal_splitType == 'amount' 
                              ? (totalEntered != amount ? Colors.red : Colors.green)
                              : (totalEntered != 100 ? Colors.red : Colors.green)
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.groupMembers.length,
                      itemBuilder: (context, index) {
                        final member = widget.groupMembers[index];
                        return ListTile(
                          title: Text(member['name']),
                          trailing: SizedBox(
                            width: 100,
                            child: TextField(
                              controller: controllers[index],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: unequal_splitType == 'amount' ? '₹ Amount' : '%',
                                suffixText: unequal_splitType == 'percentage' ? '%' : '',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Cancel')
              ),
              ElevatedButton(
                onPressed: () {
                  // Validation
                  if (unequal_splitType == 'amount' && totalEntered != amount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Total must equal ₹$amount")),
                    );
                    return;
                  }
                  
                  if (unequal_splitType == 'percentage' && totalEntered != 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Percentages must sum to 100%")),
                    );
                    return;
                  }
                  
                  setState(() {
                    unequalShares = tempShares;
                    if (unequal_splitType == 'percentage') {
                      _recalculateAmountsFromPercentages();
                    }
                    splitBetween = widget.groupMembers
                        .where((m) => (unequalShares[m['_id']] ?? 0) > 0)
                        .map((m) => m['_id'].toString())
                        .toSet();
                  });
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          );
        }
      ),
    );
  }

  String _getSplitDisplayText() {
    if (splitType == 'equal') {
      if (splitBetween.length == widget.groupMembers.length) {
        return "split equally among all";
      } else {
        return "split equally among ${splitBetween.length} members";
      }
    } else {
      return "split ${unequal_splitType == 'amount' ? 'by amount' : 'by percentage'}";
    }
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
            const SizedBox(height: 20),            Row(
              children: [
                const Text("Paid by "),
                TextButton(
                  onPressed: _showPaidByDialog,
                  child: Text(widget.groupMembers.firstWhere((m) => m['_id'] == paidBy)['name']),
                ),
                const Text(" and "),
                Expanded(
                  child: TextButton(
                    onPressed: _showSplitTypeDialog,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _getSplitDisplayText(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (splitType == 'equal' && splitBetween.length < widget.groupMembers.length) 
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Card(
                  color: Colors.teal[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Split equally among ${splitBetween.length} selected members:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: widget.groupMembers
                              .where((member) => splitBetween.contains(member['_id']))
                              .map((member) => Chip(
                                    label: Text(
                                      member['name'],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.teal[100],
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _showSplitDialog,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.teal[100],
                            foregroundColor: Colors.teal[800],
                          ),
                          child: const Text('Change Selection'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (splitType == 'unequal') 
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton(
                  onPressed: _showUnequalSplitDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[100],
                    foregroundColor: Colors.teal[800],
                  ),
                  child: Text('Edit ${unequal_splitType == 'amount' ? 'Amount' : 'Percentage'} Distribution'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
