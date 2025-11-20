import 'package:flutter/material.dart';

class ParentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Awareness Dashboard'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              // Action for the user profile button
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Progress Over Time Graph
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  Text('Progress Over Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // You can use packages like fl_chart to display graphs
                  // Placeholder for chart
                  Container(
                    height: 200,
                    color: Colors.blue[100],
                    child: Center(child: Text('Progress Graph')),
                  ),
                ],
              ),
            ),
            // Word Category Performance
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  Text('Word Category Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // Placeholder for bar chart
                  Container(
                    height: 200,
                    color: Colors.green[100],
                    child: Center(child: Text('Word Category Chart')),
                  ),
                ],
              ),
            ),
            // Session Completion
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Session Completion', style: TextStyle(fontSize: 18)),
                  // Pie chart or progress indicator
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue[300],
                    ),
                    child: Center(child: Text('75%', style: TextStyle(color: Colors.white))),
                  ),
                ],
              ),
            ),
            // Average Score Trend
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  Text('Average Score Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // Placeholder for line chart
                  Container(
                    height: 200,
                    color: Colors.orange[100],
                    child: Center(child: Text('Score Trend Graph')),
                  ),
                ],
              ),
            ),
            // AI Assistant
            Container(
              margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.blueAccent,
              ),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.chat, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Hi! How can I help you?',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  // Text input for AI query
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
