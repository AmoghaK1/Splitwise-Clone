import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:splitwise_clone/screens/expenses/add_expense_screen.dart';
import 'package:splitwise_clone/screens/groups/add_group_member_screen.dart';
import 'package:splitwise_clone/screens/groups/group_settings_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Future<Map<String, dynamic>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = fetchExpensesAndNames();
  }

  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user!.getIdToken();

    final response = await http.get(
      Uri.parse('http://192.168.1.5:3000/groups/${widget.group['_id']}/expenses'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch expenses");
    }

    final decoded = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(decoded['expenses']);
  }

  Future<Map<String, String>> fetchGroupMemberNames(String groupId) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user!.getIdToken();

    final response = await http.get(
      Uri.parse('http://192.168.1.5:3000/groups/$groupId/members'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch group members");
    }

    final memberIds = List<String>.from(jsonDecode(response.body)['members']);
    final firestore = FirebaseFirestore.instance;
    final nameMap = <String, String>{};

    for (String uid in memberIds) {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        nameMap[uid] = doc.data()?['name'] ?? 'No Name';
      }
    }

    return nameMap;
  }

  Future<Map<String, dynamic>> fetchExpensesAndNames() async {
    final expenses = await fetchExpenses();
    final nameMap = await fetchGroupMemberNames(widget.group['_id']);
    return {
      'expenses': expenses,
      'nameMap': nameMap,
    };
  }

  void _navigateToAddExpense(BuildContext context) async {
    try {
      final members = await fetchGroupMemberNames(widget.group['_id']);
      final firestore = FirebaseFirestore.instance;
      final memberDetails = <Map<String, dynamic>>[];

      for (final entry in members.entries) {
        final doc = await firestore.collection('users').doc(entry.key).get();
        if (doc.exists) {
          memberDetails.add({
            '_id': entry.key,
            'name': entry.value,
            'email': doc.data()?['email'] ?? '',
          });
        }
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddExpenseScreen(
            groupId: widget.group['_id'],
            groupMembers: memberDetails,
            currentUserId: FirebaseAuth.instance.currentUser!.uid,
          ),
        ),
      );

      setState(() {
        futureData = fetchExpensesAndNames();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load members: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.group['pfpUrl'] != null && widget.group['pfpUrl'].isNotEmpty
                  ? NetworkImage(widget.group['pfpUrl'])
                  : null,
              child: widget.group['pfpUrl'] == null || widget.group['pfpUrl'].isEmpty
                  ? const Icon(Icons.group)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.group['name'] ?? 'Group',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => 
                GroupSettingsScreen(group: widget.group),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddExpense(context),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text("Add Expense"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Buttons Row (restored)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text("Add Members"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddGroupMembersScreen(groupId: widget.group['_id']),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.currency_rupee),
                  label: const Text("Settle Up"),
                  onPressed: () {
                    // TODO: Implement settle logic
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
               
              ],
            ),
            const SizedBox(height: 20),

            FutureBuilder<Map<String, dynamic>>(
              future: futureData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Expanded(child: Center(child: CircularProgressIndicator()));
                }

                if (snapshot.hasError) {
                  return Expanded(child: Center(child: Text("Error: ${snapshot.error}")));
                }

                final expenses = snapshot.data?['expenses'] ?? [];
                final Map<String, String> nameMap =
                    Map<String, String>.from(snapshot.data?['nameMap'] ?? {});

                double totalPaid = 0;
                double totalOwe = 0;
                double totalLent = 0;

                List<Widget> expenseWidgets = [];

                for (var exp in expenses) {
                  final amount = exp['amount'] as num;
                  final List splitBetween = exp['splitBetween'] as List;
                  final String splitType = exp['splitType'] ?? 'equal';
                  final bool isUnequalSplit = splitType == 'unequal';

                  Map<String, double> unequalShares = {};
                  if (isUnequalSplit && exp['unequalShares'] != null) {
                    final rawShares = exp['unequalShares'] as Map<String, dynamic>;
                    rawShares.forEach((key, value) {
                      unequalShares[key] = (value as num).toDouble();
                    });
                  }

                  final double share = isUnequalSplit && unequalShares.containsKey(currentUserId)
                      ? unequalShares[currentUserId]!
                      : amount / splitBetween.length;

                  final bool isPayer = exp['paidBy'] == currentUserId;
                  final bool isInSplit = splitBetween.contains(currentUserId);

                  String payerName = nameMap[exp['paidBy']] ?? 'Someone';
                  String message;
                  Color color;

                  if (isPayer && isInSplit && splitBetween.length == 1) {
                    message = "You paid ₹$amount";
                    color = Colors.black;
                    totalPaid += amount;
                  } else if (isPayer) {
                    double lent = isUnequalSplit
                        ? amount - (unequalShares[currentUserId] ?? 0)
                        : share * (splitBetween.length - 1);
                    message = "You are owed ₹${lent.toStringAsFixed(2)}";
                    color = Colors.green;
                    totalPaid += amount;
                    totalLent += lent;
                  } else if (isInSplit) {
                    message = "You owe ₹${share.toStringAsFixed(2)}";
                    color = Colors.red;
                    totalOwe += share;
                  } else {
                    message = "$payerName paid ₹$amount";
                    color = Colors.black;
                  }

                  expenseWidgets.add(
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal[100],
                        child: const Icon(Icons.receipt_long, color: Colors.teal),
                      ),
                      title: Text(exp['description'] ?? 'No description'),
                      subtitle: Text("Paid by: $payerName (₹$amount)"),
                      trailing: Text(message,
                          style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                    ),
                  );
                }

                return Expanded(
                  child: Column(
                    children: [
                      Card(
                        color: Colors.grey[100],
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(children: [
                                const Text("You paid",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                Text("₹${totalPaid.toStringAsFixed(2)}",
                                    style: const TextStyle(color: Colors.black)),
                              ]),
                              Column(children: [
                                const Text("You owe",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                Text("₹${totalOwe.toStringAsFixed(2)}",
                                    style: const TextStyle(color: Colors.red)),
                              ]),
                              Column(children: [
                                const Text("You lent",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                Text("₹${totalLent.toStringAsFixed(2)}",
                                    style: const TextStyle(color: Colors.green)),
                              ]),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: expenses.isEmpty
                            ? const Center(child: Text("No expenses added yet."))
                            : ListView.separated(
                                itemCount: expenseWidgets.length,
                                itemBuilder: (_, index) => expenseWidgets[index],
                                separatorBuilder: (_, __) => const Divider(),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
