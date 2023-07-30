import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:dio/dio.dart';

void main() => runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: MyBody(),))
    )
);

class Event {
  final String eventFormat;
  final String eventDateTime;
  final String eventTimeZone;
  final Map<String, dynamic> eventData;

  Event(this.eventFormat, this.eventDateTime, this.eventTimeZone, this.eventData);

  factory Event.fromJSON(dynamic dataJSON) {
    return Event(
        dataJSON['EventFormat'] as String,
        dataJSON['EventDateTime'] as String,
        dataJSON['EventTimeZone'] as String,
        dataJSON['EventData'] as Map<String, dynamic>
    );
  }
}

class MyBody extends StatefulWidget {
  @override
  createState() => MyBodyState();
}

class MyBodyState extends State<MyBody> {
  //List data = [];
  List<Event> events = [];
  //List<Event> newEvents = [];

  Future<String> getData() async {
    final response = await http.get(
        Uri.parse("http://188.225.75.241/getmdata?user=user1@mobiosoft.com"),
        headers: {
          "Accept": "application/json"
        }
    );

    if ((response.statusCode == 200) || (response.statusCode == 201)) {
      setState(() {
        if (response.body != '') {
          //data = json.decode(response.body);
          events = (json.decode(response.body) as List).map((i) => Event.fromJSON(i)).toList();
          //print(events[0].eventData);
        }
      });
      return "Success!";
    } else {
        throw Exception('Ошибка загрузки данных');
    }
  }


  subscribe2() async {
    Response<ResponseBody> rs = await Dio().get<ResponseBody>(
      "http://188.225.75.241/sse/events?user=user1@mobiosoft.com",
      options: Options(headers: {
        "Accept": "text/event-stream",
        "Cache-Control": "no-cache",
      }, responseType: ResponseType.stream), // set responseType to `stream`
    );

    StreamTransformer<Uint8List, List<int>> unit8Transformer =
    StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        sink.add(List<int>.from(data));
      },
    );

    rs.data?.stream
        .transform(unit8Transformer)
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen((rawEvent) {
            //Map<String, dynamic> jstr = json.decode(rawEvent);
            //print("JSONEvent: $jstr");
            Event newEvent = Event.fromJSON(json.decode(rawEvent));
            setState(() {
              events.add(newEvent);
            });
    });
  }

  @override
  void initState(){
    getData();
    subscribe2();
  }

  //Create item rows for ListView of new events
  Widget _buildRowSD1(Event item) => Container(
    decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey))
    ),
    margin: const EdgeInsets.fromLTRB(1, 1, 1, 1),
    child: ListTile(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.eventDateTime.toString(), style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
          SizedBox(width: 10),
          Text(item.eventData['name'].toString(), style: TextStyle(color: Colors.blue[500], fontWeight: FontWeight.bold)),
        ],
      ),
      subtitle: Text(item.eventData['content'].toString()),
      trailing: Text('>'),
    ),
  );

  //Create item rows for ListView of new events
  Widget _buildRowSD2(Event item) => Container(
    decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey))
    ),
    margin: const EdgeInsets.fromLTRB(1, 1, 1, 1),
    child: ListTile(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.eventDateTime.toString(), style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
          SizedBox(width: 10),
          Text(item.eventData['name'].toString(), style: TextStyle(color: Colors.green[500], fontWeight: FontWeight.bold)),
        ],
      ),
      subtitle: Text(item.eventData['content'].toString()),
      trailing: Text('>'),
    ),
  );

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text("Listviews"), backgroundColor: Colors.blue),
      body: ListView.builder(
        itemCount: events == null ? 0 : events.length,
        itemBuilder: (BuildContext context, int index){
          /*return Card(
            child: Text(events[index].eventData.toString()),
          );*/
          if (events[index].eventFormat == 'SD1') {
            return _buildRowSD1(events[index]);
          } else if (events[index].eventFormat == 'SD2') {
            return _buildRowSD2(events[index]);
          }
          else {
            return _buildRowSD1(events[index]);
          }
        },
      ),
    );
  }
}