import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/screens/doctor_home_screen.dart';
import 'package:mobile_app/screens/home_screen.dart';
import 'package:mobile_app/screens/login_screen.dart';

class UserRoleWrapper extends StatelessWidget {
  const UserRoleWrapper({super.key});

  Future<bool> _isDoctor(User user) async {
    final doc = await FirebaseFirestore.instance.collection('doctors').doc(user.uid).get();
    return doc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasData && authSnapshot.data != null) {
          // User is logged in, check their role
          return FutureBuilder<bool>(
            future: _isDoctor(authSnapshot.data!),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (roleSnapshot.hasData && roleSnapshot.data == true) {
                // User is a doctor
                return const DoctorHomeScreen();
              } else {
                // User is a customer
                return const HomeScreen();
              }
            },
          );
        } else {
          // User is not logged in
          return const LoginScreen();
        }
      },
    );
  }
}
