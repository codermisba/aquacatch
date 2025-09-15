import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'components.dart';
import 'generated/l10n.dart';


class ProfilePage extends StatelessWidget {
  final Function(Locale) setLocale; // required to change language dynamically

  const ProfilePage({super.key, required this.setLocale});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No user logged in")),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          S.of(context).profile, // localized
          style: const TextStyle(color: Colors.white, fontSize: 28),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No user data found"));
          }

          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  data['name'] ?? S.of(context).unknown,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  data['email'] ?? S.of(context).noEmail,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(Icons.settings, color: primaryColor),
                    title: Text(S.of(context).settings),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(Icons.language, color: Colors.teal),
                    title: Text(S.of(context).languagePreference),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(S.of(context).selectLanguage),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text("English"),
                                onTap: () {
                                  setLocale(const Locale('en'));
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: const Text("Hindi"),
                                onTap: () {
                                  setLocale(const Locale('hi'));
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: const Text("Kannada"),
                                onTap: () {
                                  setLocale(const Locale('kn'));
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: const Text("Marathi"),
                                onTap: () {
                                  setLocale(const Locale('mr'));
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(S.of(context).close),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                customButton(S.of(context).logout, () => _logout(context)),
              ],
            ),
          );
        },
      ),
    );
  }
}
