import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:splitwise_clone/screens/groups/add_group_member_screen.dart';

class GroupSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupSettingsScreen({super.key, required this.group});
  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late TextEditingController _nameController;
  bool simplifyDebts = false;
  List<Map<String, dynamic>> _membersWithDetails = [];
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group['name']);
    _fetchMembersWithDetails();
  }

  Future<void> _fetchMembersWithDetails() async {
    try {
      final memberIds = List<String>.from(widget.group['members'] ?? []);
      final firestore = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user!.getIdToken();
      
      // Fetch expenses for this group to calculate balances
      final expensesResponse = await http.get(
        Uri.parse('http://192.168.1.5:3000/groups/${widget.group['_id']}/expenses'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
      
      List<dynamic> expenses = [];
      if (expensesResponse.statusCode == 200) {
        final decoded = jsonDecode(expensesResponse.body);
        expenses = decoded['expenses'] ?? [];
      }
      
      // Calculate balances for each member
      Map<String, double> memberBalances = {};
      for (String memberId in memberIds) {
        memberBalances[memberId] = 0.0;
      }
      
      // Calculate balances based on expenses
      for (var expense in expenses) {
        final amount = (expense['amount'] as num).toDouble();
        final paidBy = expense['paidBy'] as String;
        final splitBetween = List<String>.from(expense['splitBetween'] ?? []);
        final splitType = expense['splitType'] ?? 'equal';
        
        if (splitType == 'equal' && splitBetween.isNotEmpty) {
          final sharePerPerson = amount / splitBetween.length;
          
          // Person who paid gets credited
          if (memberBalances.containsKey(paidBy)) {
            memberBalances[paidBy] = memberBalances[paidBy]! + amount;
          }
          
          // Everyone in split owes their share
          for (String memberId in splitBetween) {
            if (memberBalances.containsKey(memberId)) {
              memberBalances[memberId] = memberBalances[memberId]! - sharePerPerson;
            }
          }
        } else if (splitType == 'unequal' && expense['unequalShares'] != null) {
          final unequalShares = Map<String, dynamic>.from(expense['unequalShares']);
          
          // Person who paid gets credited
          if (memberBalances.containsKey(paidBy)) {
            memberBalances[paidBy] = memberBalances[paidBy]! + amount;
          }
          
          // Everyone owes their specific share
          unequalShares.forEach((memberId, share) {
            if (memberBalances.containsKey(memberId)) {
              memberBalances[memberId] = memberBalances[memberId]! - (share as num).toDouble();
            }
          });
        }
      }
      
      // Fetch member details from Firestore
      final List<Map<String, dynamic>> membersWithDetails = [];
      for (String memberId in memberIds) {
        final doc = await firestore.collection('users').doc(memberId).get();
        if (doc.exists) {
          final data = doc.data()!;
          membersWithDetails.add({
            'id': memberId,
            'name': data['name'] ?? 'Unknown',
            'balance': memberBalances[memberId] ?? 0.0,
          });
        }
      }
      
      setState(() {
        _membersWithDetails = membersWithDetails;
        _isLoadingMembers = false;
      });
    } catch (e) {
      print('Error fetching members: $e');
      setState(() {
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _updateGroupName() async {
    final newName = _nameController.text.trim();
    
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }

    if (newName == widget.group['name']) {
      // No change needed
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final idToken = await user.getIdToken();
      
      final response = await http.put(
        Uri.parse('http://192.168.1.5:3000/groups/${widget.group['_id']}/name'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': newName,
        }),
      );

      if (response.statusCode == 200) {
        // Update the local group data
        setState(() {
          widget.group['name'] = newName;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group name updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update group name');
      }
    } catch (e) {
      print('Error updating group name: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update group name: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Reset the text field to original name
      setState(() {
        _nameController.text = widget.group['name'] ?? '';
      });
    }
  }

  Future<void> _leaveGroup() async {
    // First confirmation dialog
    bool? confirmLeave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Group'),
          content: Text('Are you sure you want to leave "${widget.group['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (confirmLeave != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final idToken = await user.getIdToken();
      
      final response = await http.post(
        Uri.parse('http://192.168.1.5:3000/groups/${widget.group['_id']}/leave'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left group successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to home screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to leave group');
      }
    } catch (e) {
      print('Error leaving group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave group: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteGroup() async {
    // First confirmation dialog
    bool? confirmDelete1 = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Group'),
          content: Text('Are you sure you want to delete "${widget.group['name']}"?\n\nThis action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete1 != true) return;

    // Second confirmation dialog
    bool? confirmDelete2 = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This will permanently delete:'),
              const SizedBox(height: 8),
              Text('• Group "${widget.group['name']}"'),
              const Text('• All expenses in this group'),
              const Text('• All member data for this group'),
              const SizedBox(height: 16),
              const Text(
                'This action is irreversible. Are you reallyy reallyy sure?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              child: const Text('YES, DELETE PERMANENTLY'),
            ),
          ],
        );
      },
    );

    if (confirmDelete2 != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final idToken = await user.getIdToken();
      
      final response = await http.delete(
        Uri.parse('http://192.168.1.5:3000/groups/${widget.group['_id']}'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to home screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete group');
      }
    } catch (e) {
      print('Error deleting group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete group: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group settings"),
        backgroundColor: Colors.teal[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group name section
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.teal,
                  child: const Icon(Icons.group, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Group name",
                      suffixIcon: Icon(Icons.edit),
                    ),
                    onSubmitted: (_) => _updateGroupName(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Add Members
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text("Add people to group"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddGroupMembersScreen(groupId: widget.group['_id']),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Group Members List with balances
            Text(
              "Group Members (${_membersWithDetails.length})",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_isLoadingMembers)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_membersWithDetails.isEmpty)
              Text(
                "No members found",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              )
            else
              ..._membersWithDetails.map<Widget>((member) {
                final name = member['name'] as String;
               
                final balance = member['balance'] as double;
                
                final isOwing = balance < 0;
                
                String balanceText;
                Color balanceColor;
                
                if (balance == 0) {
                  balanceText = "settled up";
                  balanceColor = Colors.green;
                } else if (isOwing) {
                  balanceText = "owes ₹${balance.abs().toStringAsFixed(2)}";
                  balanceColor = Colors.red;
                } else {
                  balanceText = "gets back ₹${balance.toStringAsFixed(2)}";
                  balanceColor = Colors.green;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal[100],
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Colors.teal[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                   
                    trailing: Text(
                      balanceText,
                      style: TextStyle(
                        color: balanceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),

            // Simplify Group Debts
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sync_alt),
              title: const Text("Simplify group debts"),
              trailing: Switch(
                value: simplifyDebts,
                onChanged: (val) {
                  setState(() => simplifyDebts = val);
                },
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  "Automatically combines debts to reduce the number of repayments between group members.",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Leave Group Button
            Card(
              color: Colors.orange[100],
              child: ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.orange),
                title: const Text("Leave Group"),
                onTap: _leaveGroup,
              ),
            ),
            const SizedBox(height: 10),

            // Delete Group Button
            Card(
              color: Colors.red[100],
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("Delete Group"),
                onTap: _deleteGroup,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
