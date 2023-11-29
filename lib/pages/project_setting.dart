import 'package:flutter/material.dart';

class ProjectSetting extends StatelessWidget {
  const ProjectSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("项目设置"));
  }
}

class ProjectSettingPage extends StatefulWidget {
  const ProjectSettingPage({super.key});

  @override
  State<ProjectSettingPage> createState() => _ProjectSettingPageState();
}

class _ProjectSettingPageState extends State<ProjectSettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("项目设置"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Column(
        children: [
          Expanded(
              child: Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: ProjectSetting(),
          ))
        ],
      ),
    );
  }
}
