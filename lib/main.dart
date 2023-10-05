import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white60,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: AnimatedTextKit(
            animatedTexts: [
              TyperAnimatedText(
                'Search Animals Here...',
                speed: Duration(milliseconds: 100),
              ),
            ],
          ),
          actions: [
            SearchBar(),
          ],
        ),
        body: AnimalGrid(),
      ),
    );
  }
}

class AnimalGrid extends StatefulWidget {
  @override
  _AnimalGridState createState() => _AnimalGridState();
}

class _AnimalGridState extends State<AnimalGrid> {
  List<Map<String, dynamic>> animals = [];
  bool isLoading = true;

  Future<void> fetchAnimals() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse('https://animals-api-080s.onrender.com/animals'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Map<String, dynamic>> allAnimals =
          jsonData.cast<Map<String, dynamic>>();
      setState(() {
        animals = allAnimals;
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAnimals();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                )
              : GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: animals.length,
                  itemBuilder: (BuildContext context, int index) {
                    return AnimalCard(
                      name: animals[index]['name'],
                      imageUrl: animals[index]['image_url'],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class AnimalCard extends StatelessWidget {
  final String name;
  final String imageUrl;

  AnimalCard({required this.name, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Image.network(
            imageUrl,
            height: 100,
            width: double.maxFinite,
            fit: BoxFit.cover,
          ),
          Text(
            name,
            style: TextStyle(fontSize: 12, fontFamily: 'lato'),
          ),
        ],
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.search),
      onPressed: () async {
        final result = await showSearch(
          context: context,
          delegate: AnimalSearchDelegate(),
        );

        if (result != null) {
          // Handle the selected search result
          print('Selected: $result');
        }
      },
    );
  }
}

class AnimalSearchDelegate extends SearchDelegate<String> {
  final List<String> suggestions = [
    'dogs',
    'dinosaurs',
    'lions',
    'tigers',
    'deers',
    'bears'
  ];

  @override
  String get searchFieldLabel => 'Search by Animal Type';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      primaryColor: Colors.white,
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text('Enter a search query'),
      );
    } else {
      return FutureBuilder(
        future: fetchSearchResults(query),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Search results not found for: $query'));
          } else {
            return AnimalSearchResults(animals: snapshot.data!);
          }
        },
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchSearchResults(
      String searchInput) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://animals-api-080s.onrender.com/animals/type/$searchInput'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<Map<String, dynamic>> searchResults =
            jsonData.cast<Map<String, dynamic>>();
        return searchResults;
      } else {
        // Handle non-200 response gracefully
        return [];
      }
    } catch (e) {
      // Handle exceptions gracefully
      print('Error: $e');
      return [];
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? suggestions
        : suggestions
            .where((animal) =>
                animal.toLowerCase().startsWith(query.toLowerCase()))
            .toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (BuildContext context, int index) {
        return MouseRegion(
          onEnter: (_) {
            // Change cursor pointer when entering the suggestion
            SystemMouseCursors.click;
          },
          onExit: (_) {
            // Reset cursor pointer when exiting the suggestion
            SystemMouseCursors.basic;
          },
          child: InkWell(
            onTap: () {
              query = suggestionList[index];
              showResults(context);
            },
            hoverColor: Colors.blue[100], // Hover effect color
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.grey[200], // Background color
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.blue, // Icon color
                  ),
                  SizedBox(width: 16.0),
                  Text(
                    'Search for ${suggestionList[index]}', // Pre-text
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.black, // Text color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimalSearchResults extends StatelessWidget {
  final List<Map<String, dynamic>> animals;

  AnimalSearchResults({required this.animals});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.92,
      ),
      itemCount: animals.length,
      itemBuilder: (BuildContext context, int index) {
        return AnimalCard(
          name: animals[index]['name'],
          imageUrl: animals[index]['image_url'],
        );
      },
    );
  }
}
