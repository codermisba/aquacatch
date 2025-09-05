import 'package:flutter/material.dart';
import 'components.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Profile",style: TextStyle(color: Colors.white, fontSize: 28),),
        backgroundColor: primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // back arrow
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // User info
            CircleAvatar(
              radius: 50,
              backgroundColor: primaryColor,
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              "John Doe",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "johndoe@example.com",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Settings option
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.settings, color: primaryColor),
                title: const Text("Settings"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 16),

            // Language Preference option
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.language, color: Colors.teal),
                title: const Text("Language Preference"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Show simple language selection options
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: const Text("Select Language"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                ListTile(
                                  title: Text("English"),
                                ),
                                ListTile(
                                  title: Text("Hindi"),
                                ),
                                ListTile(
                                  title: Text("Kannada"),
                                ),
                                ListTile(
                                  title: Text("Marathi"),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Close"))
                            ],
                          ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
