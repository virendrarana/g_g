import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatefulWidget {
  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final String supportEmail = 'gutfulgoodness@gmail.com';
  final String supportPhone = '+919284189765';

  Future<void> _sendEmail() async {
    final String subject = Uri.encodeComponent(_subjectController.text.trim());
    final String message = Uri.encodeComponent(_messageController.text.trim());

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=$subject&body=$message',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the email app')),
      );
    }
  }

  Future<void> _sendWhatsApp() async {
    final String message = Uri.encodeComponent(_messageController.text.trim());
    final String whatsappUrl = "https://wa.me/$supportPhone?text=$message";

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Us'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 100,
                    color: Colors.teal,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'We\'re here to help!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Feel free to reach out with any questions.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            // _buildTextField(
            //   controller: _subjectController,
            //   label: 'Subject',
            //   icon: Icons.subject,
            // ),
            // SizedBox(height: 20),
            // _buildTextField(
            //   controller: _messageController,
            //   label: 'Message',
            //   icon: Icons.message,
            //   maxLines: 5,
            // ),
            SizedBox(height: 30),

            _buildContactButton(
              label: 'Send Email',
              color: Colors.teal,
              icon: Icons.email,
              onPressed: _sendEmail,
            ),
            SizedBox(height: 15),
            _buildContactButtonWithImage(
              label: 'Contact via WhatsApp',
              color: Colors.green,
              imageAssetPath: 'images/WhatsApp_icon.png',
              onPressed: _sendWhatsApp,
            ),
            SizedBox(height: 15),
            _buildContactButton(
              label: 'Call Support',
              color: Colors.blueAccent,
              icon: Icons.phone,
              onPressed: () async {
                final Uri phoneUri = Uri(
                  scheme: 'tel',
                  path: supportPhone,
                );

                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not make the call')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        filled: true,
        fillColor: Colors.teal.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal.shade200),
          borderRadius: BorderRadius.circular(30),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal),
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildContactButtonWithImage({
    required String label,
    required Color color,
    required String imageAssetPath,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imageAssetPath,
            width: 24,
            height: 24,
          ),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
