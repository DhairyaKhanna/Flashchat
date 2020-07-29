import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flashchat/constants.dart';
import 'registration_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _database = Firestore.instance;
FirebaseUser loggedin;

class ChatScreen extends StatefulWidget {
  static const String id = 'ChatScreen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messagecontroller = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String message;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    final user = await _auth.currentUser();

    try {
      if (user != null) {
        loggedin = user;
      }
    } catch (e) {
      print(e);
    }
  }

  void getMessages() async {
    final previousmessages =
        await _database.collection('messages').getDocuments();
    for (var message in previousmessages.documents) {
      print(message.data);
    }
  }

  void streamMessages() async {
    await for (var snapshots in _database.collection('messages').snapshots()) {
      for (var message in snapshots.documents) {
        print(message.data);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                streamMessages();
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Messagestream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messagecontroller,
                      onChanged: (value) {
                        message = value;
                        //Do something with the user input.
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      if (message != null) {
                        messagecontroller.clear();
                        _database
                            .collection('messages')
                            .add({'text': message, 'sender': loggedin.email});
                      }
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
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

class Messagestream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _database.collection('messages').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        final messages = snapshot.data.documents.reversed;
        List<Messagebubble> Messagebubbles = [];
        for (var message in messages) {
          final messagetext = message.data['text'];
          final messagesender = message.data['sender'];
          final currentuser = loggedin.email;

          if (messagetext != null && currentuser == messagesender) {
            final messagebubble = Messagebubble(
              sender: messagesender,
              text: messagetext,
              isMe: true,
            );
            Messagebubbles.add(messagebubble);
          } else if (messagetext != null && currentuser != messagesender) {
            final messagebubble = Messagebubble(
              sender: messagesender,
              text: messagetext,
              isMe: false,
            );
            Messagebubbles.add(messagebubble);
          } else {
            Messagebubbles.add(Messagebubble(
              sender: messagesender,
              text: '',
              isMe: currentuser == messagesender,
            ));
          }
        }

        return Expanded(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: ListView(reverse: true, children: Messagebubbles)));
      },
    );
  }
}

class Messagebubble extends StatelessWidget {
  Messagebubble({this.text, this.sender, this.isMe});

  final text;
  final sender;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(color: Colors.black26, fontSize: 12),
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30))
                : BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
            elevation: 5,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 15, color: isMe ? Colors.white : Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
