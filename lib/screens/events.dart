import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

import '../main.dart';
import '../navbar.dart';

class Event {
  final String id;
  final String eventFormat;
  final String eventDateTime;
  final String eventTimeZone;
  final bool eventShowStatus;
  final bool eventReadStatus;
  final Map<String, dynamic> eventData;

  Event(this.id, this.eventFormat, this.eventDateTime, this.eventTimeZone, this.eventShowStatus, this.eventReadStatus, this.eventData);

  factory Event.fromJSON(dynamic dataJSON) {
    return Event(
        dataJSON['ID'] as String,
        dataJSON['EventFormat'] as String,
        dataJSON['EventDateTime'] as String,
        dataJSON['EventTimeZone'] as String,
        dataJSON['EventShowStatus'] as bool,
        dataJSON['EventReadStatus'] as bool,
        dataJSON['EventData'] as Map<String, dynamic>
    );
  }
}

List<Event> events = [];
 int countEvents = 10;

class EventsScreen extends StatefulWidget {
  static const String id = 'events_screen';

  final formKey = GlobalKey<FormState>();

  final Map data = {'name': String, 'email': String, 'age': int};

  Future<String> getData() async {
    final response = await http.get(
        Uri.parse("http://188.225.75.241/out/events?user=user1@mobiosoft.com"),
        headers: {
          "Accept": "application/json"
        }
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        // Time has run out, do what you wanted to do.
        return http.Response('Error', 408); // Request Timeout response status code
      },
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
    } else if (response.statusCode == 408) {
      throw Exception('Истек таймаут выполнения запроса');
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
      var showStatus = newEvent.eventShowStatus.toString();
      print('Show status of new event: $showStatus');
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

  //Create item rows for ListView of new events (Type = SD1)
  Widget _buildRowSD1(Event item) => Container(
      decoration: BoxDecoration(
          color: item.eventShowStatus ? Colors.white : Colors.grey[200],
          border: const Border(bottom: BorderSide(color: Colors.black12))
      ),
      child: SizedBox(
          height: 65,
          child:
          Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child:
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                            backgroundColor: Colors.blue[400],
                            foregroundColor: Colors.white,
                            radius: 24,
                            child: Text(item.eventData['name'].toString()[0]))
                      ]),
                ),
                Expanded(
                    flex: 4,
                    child:
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Padding(
                                      padding: const EdgeInsets.only(right: 8.0, bottom: 2.0),
                                      child:
                                      Text(item.eventData['name'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.bold))
                                  ),
                                ),
                                Column(
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.only(right: 10.0, bottom: 2.0),
                                          child:
                                          Text(item.eventDateTime.toString(),
                                              style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.normal))
                                      )
                                    ]
                                )
                              ]
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child:
                                    Column(
                                        children: [
                                          //Text("Статус заказа: Доставка товара в пункт выдачи, который находится рядом с домом. Получение по коду доступа.",
                                          Text(item.eventData['content'].toString(),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: Colors.grey[600], fontSize: 14))
                                        ]
                                    ),
                                  ),
                                ),
                                const Column(
                                    children: [
                                      /*Padding(
                                            padding: EdgeInsets.only(right: 10.0),
                                            child:
                                              Icon(
                                                Icons.access_alarms_rounded,
                                                color: Colors.black26
                                              )
                                        )*/
                                    ]
                                )
                              ]
                          ),
                        ]
                    )
                )
              ]
          )
      )
  );

//Create item rows for ListView of new events (Type = FN1)
  Widget _buildRowFN1(Event item) => Container(
      decoration: BoxDecoration(
          color: item.eventShowStatus ? Colors.white : Colors.grey[200],
          border: const Border(bottom: BorderSide(color: Colors.black12))
      ),
      child: SizedBox(
          height: 65,
          child:
          Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child:
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                            backgroundColor: Colors.green[400],
                            foregroundColor: Colors.white,
                            radius: 24,
                            child: Text(item.eventData['name'].toString()[0]))
                      ]),
                ),
                Expanded(
                    flex: 4,
                    child:
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Padding(
                                      padding: const EdgeInsets.only(right: 8.0, bottom: 2.0),
                                      child:
                                      Text(item.eventData['name'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.bold))
                                  ),
                                ),
                                Column(
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.only(right: 10.0, bottom: 2.0),
                                          child:
                                          Text(item.eventDateTime.toString(),
                                              style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.normal))
                                      )
                                    ]
                                )
                              ]
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                              style: TextStyle(color: Colors.grey[600], fontSize: 14))
                                        ]
                                    ),
                                  ),
                                ),
                                const Column(
                                    children: [
                                      Padding(
                                          padding: EdgeInsets.only(right: 10.0),
                                          child:
                                          Icon(
                                              Icons.access_alarms_rounded,
                                              color: Colors.black26
                                          )
                                      )
                                    ]
                                )
                              ]
                          ),
                        ]
                    )
                )
              ]
          )
      )
  );

//Create item rows for ListView of new events (Type = SE1)
  Widget _buildRowSE1(Event item) => Container(
      decoration: BoxDecoration(
          color: item.eventShowStatus ? Colors.white : Colors.grey[200],
          border: const Border(bottom: BorderSide(color: Colors.black12))
      ),
      child: SizedBox(
          height: 65,
          child:
          Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child:
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                            backgroundColor: Colors.brown[400],
                            foregroundColor: Colors.white,
                            radius: 24,
                            child: Text(item.eventData['name'].toString()[0]))
                      ]),
                ),
                Expanded(
                    flex: 4,
                    child:
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Padding(
                                      padding: const EdgeInsets.only(right: 8.0, bottom: 2.0),
                                      child:
                                      Text(item.eventData['name'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.bold))
                                  ),
                                ),
                                Column(
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.only(right: 10.0, bottom: 2.0),
                                          child:
                                          Text(item.eventDateTime.toString(),
                                              style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.normal))
                                      )
                                    ]
                                )
                              ]
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                              style: TextStyle(color: Colors.grey[600], fontSize: 14))
                                        ]
                                    ),
                                  ),
                                ),
                                const Column(
                                    children: [
                                      Padding(
                                          padding: EdgeInsets.only(right: 10.0),
                                          child:
                                          Icon(
                                              Icons.access_alarms_rounded,
                                              color: Colors.black26
                                          )
                                      )
                                    ]
                                )
                              ]
                          ),
                        ]
                    )
                )
              ]
          )
      )
  )


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavBar(),
      appBar: AppBar(title: const Text("События"), backgroundColor: Colors.blue),
      body:
        ListView.builder(
          //reverse: true,
          itemCount: events == null ? 0 : events.length,
          itemBuilder: (BuildContext context, int index){
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