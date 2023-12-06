import 'package:flutter/material.dart';

import '../config.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    final apiUrl = TextEditingController(text: Config.apiUrl.value);
    final apiToken = TextEditingController(text: Config.apiToken.value);
    final httpProxy = TextEditingController(text: Config.httpProxy.value);
    return Scaffold(
        appBar: AppBar(
          title: const Text("设置"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Container(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: ListView(
            children: [
              Card(
                  child: Row(children: [
                const Expanded(
                  flex: 1,
                  child: ListTile(title: Text("API URL:")),
                ),
                Expanded(
                    flex: 4,
                    child: TextField(
                      controller: apiUrl,
                      decoration: InputDecoration(
                          hintText: 'https://api.openai.com/v1/',
                          hintStyle:
                              TextStyle(color: Colors.grey.withAlpha(80))),
                      onChanged: (value) {
                        Config.apiUrl.value = value;
                      },
                    ))
              ])),
              Card(
                child: Row(children: [
                  const Expanded(
                    flex: 1,
                    child: ListTile(title: Text("API TOKEN:")),
                  ),
                  Flexible(
                      flex: 4,
                      child: TextField(
                        controller: apiToken,
                        onChanged: (value) {
                          Config.apiToken.value = value;
                        },
                      ))
                ]),
              ),
              Card(
                child: Row(children: [
                  const Expanded(
                    flex: 1,
                    child: ListTile(title: Text("HTTP 代理:")),
                  ),
                  Flexible(
                      flex: 4,
                      child: TextField(
                        controller: httpProxy,
                        decoration: InputDecoration(
                            hintText: "localhost:7890",
                            hintStyle:
                                TextStyle(color: Colors.grey.withAlpha(80))),
                        onChanged: (value) {
                          Config.httpProxy.value = value;
                        },
                      ))
                ]),
              ),
            ],
          ),
        ));
  }
}
