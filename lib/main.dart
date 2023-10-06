import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white60,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: AnimatedTextKit(
            animatedTexts: [
              TyperAnimatedText(
                'Search Animals Here...',
                speed: const Duration(milliseconds: 100),
              ),
            ],
          ),
          actions: const [
            SearchBar(),
          ],
        ),
        body: const AnimalGrid(),
      ),
    );
  }
}

class AnimalGrid extends StatefulWidget {
  const AnimalGrid({super.key});

  @override
  _AnimalGridState createState() => _AnimalGridState();
}

class _AnimalGridState extends State<AnimalGrid> {
  List<Map<String, dynamic>> animals = [];
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;
  int start = 0;
  int end = 17;
  bool isError = false;
  bool isFirstLoad = true; // Flag to track the first load
  bool isFetching = false; // Flag to track if data is already being fetched

  Future<void> fetchAnimals({
    required int start,
    required int end,
  }) async {
    if (isFetching) return; // Don't fetch if data is already being fetched
    setState(() {
      isFetching = true;
      isError = false; // Reset error flag
    });

    try {
      print("Fetching animals from $start to $end");
      final response = await http.get(
        Uri.parse('https://animals-api-080s.onrender.com/animals/$start/$end'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<Map<String, dynamic>> allAnimals =
            jsonData.cast<Map<String, dynamic>>();
        if (allAnimals.isEmpty) {
          setState(() {
            isError = false; // Reset error flag
          });
          return;
        }
        setState(() {
          animals.addAll(allAnimals);
          isLoading = false;
          isFetching = false; // Data fetched successfully, reset fetching flag
        });
      } else {
        // Handle non-200 response
        setState(() {
          isError = true; // Set error flag
          isFetching = false; // Error occurred, reset fetching flag
        });
      }
    } catch (e) {
      // Handle exceptions gracefully
      print('Error: $e');
      setState(() {
        isError = true; // Set error flag
        isFetching = false; // Error occurred, reset fetching flag
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAnimals(
      start: start,
      end: end,
    );
    // Add scroll listener to fetch more data when user reaches the bottom of the list
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (isFirstLoad) {
          isFirstLoad = false;
        }
        start = 18;
        end = 31;
        fetchAnimals(
          start: start,
          end: end,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isLoading
          ? isFirstLoad
              ? CircularProgressIndicator(
                  color: Colors.blue,
                )
              : CircularProgressIndicator(
                  color: Colors.blue,
                  strokeWidth:
                      2.0, // Reduce the stroke width for subsequent loads
                )
          : isError
              ? const Text('Failed to load data. Please try again later.')
              : Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        controller: _scrollController,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.92,
                        ),
                        itemCount: animals.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: AnimalCard(
                              name: animals[index]['name'],
                              imageUrl: animals[index]['image_url'],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class AnimalCard extends StatelessWidget {
  final String name;
  final String imageUrl;

  const AnimalCard({super.key, required this.name, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Image.network(
            imageUrl,
            height: 90,
            width: double.maxFinite,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 8.0),
          SizedBox(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontFamily: 'lato'),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search),
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
        titleLarge: const TextStyle(
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
          icon: const Icon(Icons.clear),
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
      return const Center(
        child: Text('Enter a search query'),
      );
    } else {
      return FutureBuilder(
        future: fetchSearchResults(query),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.grey[200], // Background color
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: Colors.blue, // Icon color
                  ),
                  const SizedBox(width: 16.0),
                  Text("Search for: "),
                  Text(
                    suggestionList[index],
                    style: const TextStyle(
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

  const AnimalSearchResults({super.key, required this.animals});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.92,
      ),
      itemCount: animals.length,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: AnimalCard(
            name: animals[index]['name'],
            imageUrl: animals[index]['image_url'],
          ),
        );
      },
    );
  }
}
