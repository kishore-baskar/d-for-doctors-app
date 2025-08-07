import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/screens/upload_prescription_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final _user = FirebaseAuth.instance.currentUser;

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat.yMMMd().add_jm().format(dateTime);
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking has been $newStatus.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('doctors').doc(_user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Doctor profile not found.'));
          }

          final doctorData = snapshot.data!.data() as Map<String, dynamic>;
          final isVerified = doctorData['isVerified'] ?? false;
          final isAvailable = doctorData['isAvailable'] ?? false;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Welcome, Dr. ${doctorData['name']}', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 10),
                        Chip(
                          label: Text(
                            isVerified ? 'Verified' : 'Verification Pending',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: isVerified ? Colors.green : Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (!isVerified)
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 15.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your account is pending verification. You will not receive booking requests until approved.',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                Card(
                  child: SwitchListTile(
                    title: const Text('Available for Bookings'),
                    value: isAvailable,
                    onChanged: isVerified
                        ? (value) {
                            FirebaseFirestore.instance
                                .collection('doctors')
                                .doc(_user!.uid)
                                .update({'isAvailable': value});
                          }
                        : null, // Disable toggle if not verified
                    subtitle: Text(isVerified
                        ? (isAvailable ? 'You are online' : 'You are offline')
                        : 'Account not verified'),
                    secondary: Icon(
                      Icons.circle,
                      color: isVerified
                          ? (isAvailable ? Colors.green : Colors.grey)
                          : Colors.red,
                    ),
                    activeColor: Colors.green,
                  ),
                ),
                const Divider(height: 20),
                const Text('Pending Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  flex: 1,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('doctorId', isEqualTo: _user!.uid)
                        .where('status', isEqualTo: 'pending')
                        .orderBy('bookingTime', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No new booking requests.'));
                      }
                      final bookings = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          final data = booking.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text('For: ${data['patientName']}'),
                              subtitle: Text('Booked: ${_formatTimestamp(data['bookingTime'])}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(onPressed: () => _updateBookingStatus(booking.id, 'confirmed'), child: const Text('ACCEPT')),
                                  TextButton(onPressed: () => _updateBookingStatus(booking.id, 'rejected'), child: const Text('REJECT', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 20),
                const Text('Upcoming Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  flex: 1,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('doctorId', isEqualTo: _user!.uid)
                        .where('status', isEqualTo: 'confirmed')
                        .orderBy('bookingTime', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No upcoming appointments.'));
                      }
                      final bookings = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          final data = booking.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text('For: ${data['patientName']}'),
                              subtitle: Text('Confirmed: ${_formatTimestamp(data['bookingTime'])}'),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => UploadPrescriptionScreen(bookingId: booking.id),
                                    ),
                                  );
                                },
                                child: const Text('Upload Rx'),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
