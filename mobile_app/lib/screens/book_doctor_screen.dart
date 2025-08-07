import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookDoctorScreen extends StatefulWidget {
  final DocumentSnapshot patientDoc;

  const BookDoctorScreen({super.key, required this.patientDoc});

  @override
  State<BookDoctorScreen> createState() => _BookDoctorScreenState();
}

class _BookDoctorScreenState extends State<BookDoctorScreen> {
  bool _isLoading = false;

  Future<void> _confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book a visit.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Find an available doctor
      final availableDoctors = await FirebaseFirestore.instance
          .collection('doctors')
          .where('isAvailable', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .limit(1)
          .get();

      if (availableDoctors.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sorry, no doctors are available right now. Please try again later.')),
          );
        }
        return;
      }

      final doctorDoc = availableDoctors.docs.first;
      final doctorData = doctorDoc.data();

      // 2. Create a booking record
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'patientId': widget.patientDoc.id,
        'patientName': (widget.patientDoc.data() as Map<String, dynamic>)['name'],
        'doctorId': doctorDoc.id,
        'doctorName': doctorData['name'],
        'bookingTime': FieldValue.serverTimestamp(),
        'status': 'pending', // e.g., pending, confirmed, completed
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking successful! A doctor will be in touch.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Failed to create booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred during booking: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientData = widget.patientDoc.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Doctor'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Booking a visit for:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                patientData['name'],
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Booking', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
