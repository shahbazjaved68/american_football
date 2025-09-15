import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'teams.dart';
import 'fixtures.dart';
import 'news.dart';
import 'score.dart';
import 'currentweekmatches.dart';
import 'Admob/native_ads.dart';
import 'livestream.dart'; // Live stream screen
import 'update_dialog.dart'; //  Update popup
import 'fcm_setup_android.dart'; //  Firebase FCM + Notifications
import 'share.dart'; // ✅ Share functionality

AppOpenAd? openAd;
bool _hasShownAppOpenAd = false;

Future<void> loadAd() async {
  await AppOpenAd.load(
     // adUnitId: 'ca-app-pub-6736849953392817/7673389778', // actual ad unit ID
     adUnitId: 'ca-app-pub-3940256099942544/3419835294', // test ad unit ID
    request: const AdRequest(),
    adLoadCallback: AppOpenAdLoadCallback(
      onAdLoaded: (ad) {
        openAd = ad;
        if (!_hasShownAppOpenAd) {
          openAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
          );
          openAd!.show();
          _hasShownAppOpenAd = true;
          openAd = null;
        }
      },
      onAdFailedToLoad: (error) {
        print('AppOpenAd failed to load: $error');
      },
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Mobile Ads
  await MobileAds.instance.initialize();
  await loadAd();

  // ✅ Initialize Notifications + Firebase FCM
  await initLocalNotifications();
  await initFirebaseAndFCM();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NFL League',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        ),
        colorScheme: const ColorScheme.light(
            background: Colors.white,
            onBackground: Colors.black,
            primary: Colors.black),
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        ),
        colorScheme: const ColorScheme.dark(
            background: Colors.black,
            onBackground: Colors.white,
            primary: Colors.white),
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: MainPage(
        toggleTheme: _toggleTheme,
        themeMode: _themeMode,
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;
  const MainPage({
    Key? key,
    required this.toggleTheme,
    required this.themeMode,
  }) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String? _selectedTeamId;
  String? _selectedTeamName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateDialog.checkForUpdate(context); // ✅ Check Play Store version
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 2) {
        _selectedTeamId = null;
        _selectedTeamName = null;
      }
      _selectedIndex = index;
    });
  }

  void _onTeamSelected(Map<String, String> team) {
    setState(() {
      _selectedTeamId = team['id'];
      _selectedTeamName = team['name'];
      _selectedIndex = 2;
    });
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Teams';
      case 2:
        return _selectedTeamName ?? 'Fixtures';
      case 3:
        // ✅ Dynamically switch
        return Score.hasLiveScores ? 'Live Scores' : 'Highlights';
      case 4:
        return 'Live Stream';
      default:
        return 'News';
    }
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 1:
        return TeamsScreen(onTeamSelected: _onTeamSelected);
      case 2:
        return _selectedTeamId == null
            ? ScoreboardScreen()
            : FixturesScreen(teamId: _selectedTeamId!);
      case 3:
        return Score();
      case 4:
        return const LiveStreamScreen(); // ✅ Live Stream tab
      default:
        return Column(
          children: const [
            Expanded(child: NewsScreen()),
            NativeAdWidget(),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;
    final navTheme = Theme.of(context).bottomNavigationBarTheme;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: Icon(Icons.share), // ✅ Share button
            tooltip: "Share App",
            onPressed: () {
              ShareApp.shareApp(); // ✅ Call share function
            },
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: widget.toggleTheme,
          ),
        ],
      ),

      // ✅ Animated page switching
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0.05), // subtle slide
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildPage(),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: navTheme.backgroundColor,
        selectedItemColor: navTheme.selectedItemColor,
        unselectedItemColor: navTheme.unselectedItemColor,
        selectedLabelStyle: navTheme.selectedLabelStyle,
        unselectedLabelStyle: navTheme.unselectedLabelStyle,
        items: [
          _navItem(Icons.home_outlined, 'Home', 0),
          _navItem(Icons.sports_football, 'Teams', 1),
          _navItem(Icons.calendar_month, 'Fixtures', 2),
          _navItem(Icons.live_tv, 'Live Score', 3),
          _navItem(Icons.videocam, 'Stream', 4), // ✅ Added
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final navTheme = Theme.of(context).bottomNavigationBarTheme;
    final iconColor = isSelected
        ? navTheme.selectedItemColor!
        : navTheme.unselectedItemColor!;

    return BottomNavigationBarItem(
      icon: Icon(icon, color: iconColor, size: isSelected ? 30 : 24),
      label: label,
    );
  }
}
