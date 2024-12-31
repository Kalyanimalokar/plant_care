// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:plant_care/services/firestore.dart';
//
// class databaseTest extends StatefulWidget {
//   const databaseTest({super.key});
//
//
//   @override
//   State<databaseTest> createState() => _databaseTestState();
// }
//
// class _databaseTestState extends State<databaseTest> {
//
//   // FireStore
//   final FirestoreService firestoreService = FirestoreService();
//
//   // Text Controller
//   final TextEditingController textController = TextEditingController();
//   // Open Dialog Box
//   void openNoteBox() {
//     showDialog(
//       context: context,
//       builder: (context)=> AlertDialog(
//         content: TextField(
//           controller: textController,
//         ),
//         actions: [
//           // Button to save
//           ElevatedButton(
//               onPressed: (){
//               //   add a new note
//                 firestoreService.addNote(textController.text);
//               //   clear the text
//                 textController.clear();
//
//               //   close the box
//                 Navigator.pop(context);
//               },
//               child: Text("Add"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Notes"),),
//       floatingActionButton: FloatingActionButton(
//         onPressed: openNoteBox,
//         child: const Icon(Icons.add),
//       ),
//       body: StreamBuilder(
//           stream: firestoreService.getNotesStream(),
//           builder: (context, snapshot) {
//             if (snapshot.hasData) {
//               List notesList = snapshot.data!.docs;
//               return ListView.builder(
//                 itemCount: notesList.length,
//                   itemBuilder: (context, index) {
//                     // Get each individual doc
//                     DocumentSnapshot document = notesList[index];
//                     String docID = document.id;
//                   //   get note from each doc
//                     Map<String, dynamic> data =
//                         document.data() as Map<String, dynamic>;
//                     String noteText = data['note'];
//
//                     return ListTile(
//                       title: Text(noteText),
//                     );
//                   },
//               );
//             } else {
//               return const Text("No Notes..");
//             }
//           }),
//     );
//   }
// }
