import 'dart:convert'; // ✅ for jsonDecode
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // ✅ correct import
import 'package:splitwise_clone/screens/expenses/add_expense_screen.dart';
import 'package:splitwise_clone/screens/groups/add_group_member_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  final Map<String, dynamic> group;

  const GroupDetailScreen({super.key, required this.group});

  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user!.getIdToken();

    final response = await http.get(
      Uri.parse('http://192.168.1.5:3000/groups/$groupId/members'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch group members");
    }

    final memberIds = List<String>.from(jsonDecode(response.body)['members']);
    final firestore = FirebaseFirestore.instance;
    final memberDetails = <Map<String, dynamic>>[];

    for (String uid in memberIds) {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        memberDetails.add({
          '_id': uid,
          'name': doc.data()?['name'] ?? 'No Name',
          'email': doc.data()?['email'] ?? 'No Email',
        });
      }
    }

    return memberDetails;
  }

  void _navigateToAddExpense(BuildContext context) async {
    try {
      final members = await fetchGroupMembers(group['_id']);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddExpenseScreen(
            groupMembers: members,
            currentUserId: FirebaseAuth.instance.currentUser!.uid,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load members: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> expenses = group['expenses'] ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: group['pfpUrl'] != null && group['pfpUrl'].isNotEmpty
                  ? NetworkImage(group['pfpUrl'])
                  : null,
              child: group['pfpUrl'] == null || group['pfpUrl'].isEmpty
                  ? const Icon(Icons.group)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                group['name'] ?? 'Group',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Group settings
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
                            AddGroupMembersScreen(groupId: group['_id']),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.currency_rupee),
                  label: const Text("Settle Up"),
                  onPressed: () {
                    // TODO: Settle up logic
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.sync_alt),
                  label: const Text("Simplify"),
                  onPressed: () {
                    // TODO: Simplify logic
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: expenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Ready for Contri?",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text("Add an expense now!"),
                            onPressed: () => _navigateToAddExpense(context),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: expenses.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final exp = expenses[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal[100],
                            child: const Icon(Icons.receipt_long, color: Colors.teal),
                          ),
                          title: Text(exp['description']),
                          subtitle: Text("${exp['payerName']} paid ₹${exp['amount']}"),
                          trailing: Text(
                            "${exp['owesName']} owes ₹${exp['share']}",
                            style: TextStyle(
                              color: exp['owesName'] == 'You' ? Colors.red : Colors.black,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
