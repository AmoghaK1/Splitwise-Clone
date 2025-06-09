import 'package:flutter/material.dart';
import 'package:splitwise_clone/screens/groups/add_group_member_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  final Map<String, dynamic> group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> expenses = group['expenses'] ?? [];
    final List<dynamic> members = group['members'] ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(group['pfpUrl'] ?? ''),
              child: group['pfpUrl'] == null ? const Icon(Icons.group) : null,
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
              // TODO: Group settings logic
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Add expense logic
        },
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
                        builder: (context)  => AddGroupMembersScreen(groupId: group['_id']),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.currency_rupee),
                  label: const Text("Settle Up"),
                  onPressed: () {
                    // TODO: Settle up logic
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.sync_alt),
                  label: const Text("Simplify"),
                  onPressed: () {
                    // TODO: Simplify payments logic
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
                            onPressed: () {
                              // TODO: Add expense
                            },
                          )
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
                          subtitle: Text(
                              "${exp['payerName']} paid ₹${exp['amount']}"),
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
