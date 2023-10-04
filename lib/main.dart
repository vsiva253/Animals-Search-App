import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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

class AnimalGrid extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final searchText = useState('');
    final animals = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState<bool>(true);

    Future<void> fetchAnimals(String search) async {
      isLoading.value = true;
      final response = await http
          .get(Uri.parse('https://animals-api-080s.onrender.com/animals'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<Map<String, dynamic>> allAnimals =
            jsonData.cast<Map<String, dynamic>>();
        final filteredAnimals = allAnimals.where((animal) {
          return animal['type'].toLowerCase().contains(search.toLowerCase());
        }).toList();
        animals.value = filteredAnimals;
      } else {
        throw Exception('Failed to load data');
      }
      isLoading.value = false;
    }

    useEffect(() {
      fetchAnimals(searchText.value);
      return null;
    }, [searchText.value]);

    return Column(
      children: [
        Expanded(
          child: isLoading.value
              ? Center(
                  child: SpinKitWave(
                    color: Colors.blue, // Customize the color
                    size: 50.0, // Customize the size
                  ),
                )
              : GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.92, // Adjust this for the desired aspect ratio
                  ),
                  itemCount: animals.value.length,
                  itemBuilder: (BuildContext context, int index) {
                    return AnimalCard(
                      name: animals.value[index]['name'],
                      imageUrl: animals.value[index]['image_url'],
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
            height: 100, // Adjust this for image size
            width: 100, // Adjust this for image size
            fit: BoxFit.cover,
          ),
          Text(name),
        ],
      ),
    );
  }
}

class SearchBar extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final searchText = useState('');

    return IconButton(
      icon: Icon(Icons.search),
      onPressed: () async {
        final result = await showSearch(
          context: context,
          delegate: AnimalSearchDelegate(searchText: searchText.value),
        );
        if (result != null) {
          searchText.value = result;
        }
      },
    );
  }
}

class AnimalSearchDelegate extends SearchDelegate<String> {
  final String searchText;

  AnimalSearchDelegate({required this.searchText});

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
    // Perform filtering and display results here
    return Center(child: Text('Search Results: $query'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // You can implement search suggestions here
    return Center(
      child: Text(
        'Type to search animals by type...',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
