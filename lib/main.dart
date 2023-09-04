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
  final String id;
  final String eventFormat;
  final String eventDateTime;
  final String eventTimeZone;
  final Map<String, dynamic> eventData;

  Event(this.id, this.eventFormat, this.eventDateTime, this.eventTimeZone, this.eventData);

  factory Event.fromJSON(dynamic dataJSON) {
    return Event(
        dataJSON['ID'] as String,
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
        Uri.parse("http://188.225.75.241/out/events?user=user1@mobiosoft.com"),
        headers: {
          "Accept": "application/json"
        }
    );

    if ((response.statusCode == 200) || (response.statusCode == 201)) {
      setState(() {
        if (response.body != '') {
          //data = json.decode(response.body);
          final events2 = (json.decode(response.body) as List).map((i) => Event.fromJSON(i)).toList();
          //Sorting List of events
          events = events2.map((event) => event).toList()
            ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
        }
      });
      return "Success!";
    } else {
        throw Exception('Ошибка загрузки данных');
    }
  }

  //Get SSE events
  subscribe() async {
    Response<ResponseBody> rs = await Dio().get<ResponseBody>(
      "http://188.225.75.241/out/autoevent?user=user1@mobiosoft.com",
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
              //Add a new event to the EventList if EventList doesn't contain such an event id
              if (events.any((listEvent) => listEvent.id == newEvent.id) == false) {
                events.insert(0, newEvent);
              }
            });
    });
  }

  @override
  void initState(){
    getData();
    subscribe();
  }

  //Create item rows for ListView of new events
  Widget _buildRowSD1(Event item) => Container(
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey))
    ),
    margin: const EdgeInsets.fromLTRB(1, 1, 1, 1),
    child: ListTile(
      visualDensity: const VisualDensity(vertical: -2),
      leading: CircleAvatar(child: Text(item.eventData['name'].toString()[0])),
      title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child:
                  Column(
                    children: [
                      Text(item.eventData['name'].toString(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.blue[500], fontSize: 16, fontWeight: FontWeight.bold))
                      ]
                  ),
              ),
            ),
            Column(
                children: [
                  Text(item.eventDateTime.toString(),
                      style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.normal))
                ]
            )
          ]
      ),
      subtitle:
      Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child:
                Column(
                    children: [
                      Text(item.eventData['content'].toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600]))
                    ]
                ),
              ),
            ),
            const Column(
                children: [
                  Icon(
                    Icons.access_alarms_rounded,
                    color: Colors.black26
                  )
                ]
            )
          ]
      ),
    ),
  );

  //Create item rows for ListView of new events
  Widget _buildRowFN1(Event item) => Container(
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey))
    ),
    margin: const EdgeInsets.fromLTRB(1, 1, 1, 1),
    child: ListTile(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.eventDateTime.toString(), style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.eventData['name'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.green[500], fontWeight: FontWeight.bold))
            ),
        ],
      ),
      subtitle: Text(item.eventData['content'].toString()),
    ),
  );

  //Create item rows for ListView of new events
  Widget _buildRowSE1(Event item) => Container(
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey))
    ),
    margin: const EdgeInsets.fromLTRB(1, 1, 1, 1),
    child: ListTile(
      //tileColor: Colors.lightBlue,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.eventDateTime.toString(), style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.eventData['name'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.brown[500], fontWeight: FontWeight.bold))
          ),
        ],
      ),
      subtitle: Text(item.eventData['content'].toString()),
    ),
  );

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text("События"), backgroundColor: Colors.blue),
      body: ListView.builder(
        //reverse: true,
        itemCount: events == null ? 0 : events.length,
        itemBuilder: (BuildContext context, int index){
          /*return Card(
            child: Text(events[index].eventData.toString()),
          );*/
          if (events[index].eventFormat == 'SD1') {
            return _buildRowSD1(events[index]);
          } else if (events[index].eventFormat == 'FN1') {
            return _buildRowFN1(events[index]);
          } else if (events[index].eventFormat == 'SE1') {
            return _buildRowSE1(events[index]);
          }
          else {
            return _buildRowSD1(events[index]);
          }
        },
      ),
    );
  }
}