import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text('Username1'),
            accountEmail: Text('user1@mobiosoft.com'),
            currentAccountPicture:
            /*CircleAvatar(
              child: ClipOval(
                child: Image.network(
                  'https://oflutter.com/wp-content/uploads/2021/02/girl-profile.png',
                  fit: BoxFit.cover,
                  width: 90,
                  height: 90,
                ),
              ),
            ),*/
            CircleAvatar(
                backgroundColor: Colors.brown[400],
                foregroundColor: Colors.white,
                child: Text("U")
            ),
            decoration: const BoxDecoration(
              color: Colors.blue,
              image: DecorationImage(
                  fit: BoxFit.fill,
                  image: NetworkImage('https://oflutter.com/wp-content/uploads/2021/02/profile-bg3.jpg')
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.event_note),
            title: Text('События'),
            onTap: () => null,
            trailing: ClipOval(
              child: Container(
                color: Colors.red,
                width: 20,
                height: 20,
                child: Center(
                  child: Text(
                    "10",
                    //countEvents.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Настройки'),
            onTap: () => null,
          ),
          const Divider(),
        ],
      ),
    );
  }
}