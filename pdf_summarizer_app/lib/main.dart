import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _selectedFile;
  String _summary = "";

  Future<void> _uploadAndSummarize() async {
    if (_selectedFile == null) {
      setState(() {
        _summary = "Error: No file selected.";
      });

      return;
    }

    setState(() {
      _summary = "Getting Summary, Please Wait.";
    });

    final uri = Uri.parse('http://192.168.4.42:5000/summarise');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
            await http.MultipartFile.fromPath('file', _selectedFile!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        setState(() {
          _summary = jsonResponse['summary'] ?? "Error: No summary available.";
        });
      } else {
        setState(() {
          _summary = "Error: Unable to summarize PDF.";
        });
      }
    } catch (e) {
      setState(() {
        _summary = "Error: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Summarizer App'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom, allowedExtensions: ['pdf']);
                if (result != null && result.files.isNotEmpty) {
                  setState(() {
                    _selectedFile = File(result.files.single.path!);
                  });
                }
              },
              child: Text('Select PDF File'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _selectedFile != null ? _uploadAndSummarize : null,
              child: Text('Upload and Summarize'),
            ),
            SizedBox(height: 16.0),
            _selectedFile != null
                ? Text(
                    'Selected PDF: ${_selectedFile!.path}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )
                : Container(),
            SizedBox(height: 16.0),
            _summary.isNotEmpty
                ? Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _summary,
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
