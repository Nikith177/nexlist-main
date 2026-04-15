import sys

with open('lib/features/services/presentation/services_screen.dart', 'r') as f:
    text = f.read()

target = """    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Campus Services',
          style: AppTypography.h2.copyWith(color: colors.onSurface),
        ),
        centerTitle: true,
      ),
      body: SafeArea("""

replacement = """    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Campus Services',
          style: AppTypography.h2.copyWith(color: colors.onSurface),
        ),
        centerTitle: true,
      ),
      body: const ServicesScreenContent(),
    );
  }
}

class ServicesScreenContent extends StatefulWidget {
  const ServicesScreenContent({super.key});

  @override
  State<ServicesScreenContent> createState() => _ServicesScreenContentState();
}

class _ServicesScreenContentState extends State<ServicesScreenContent> {
  String selectedCategory = 'All Services';
  String searchQuery = '';
  String? _campusId;
  Stream<QuerySnapshot>? _servicesStream;

  @override
  void initState() {
    super.initState();
    _loadUserCampus();
  }

  Future<void> _loadUserCampus() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('campus_id');
    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _campusId = cached;
          _servicesStream = FirebaseFirestore.instance
              .collection('listings')
              .where('campus_id', isEqualTo: _campusId)
              .where('status', isEqualTo: 'available')
              .snapshots();
        });
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final fetched = doc.data()?['campus_id'] as String?;
      if (fetched != null && fetched.isNotEmpty) {
        await prefs.setString('campus_id', fetched);
        if (mounted) {
          setState(() {
            _campusId = fetched;
            _servicesStream = FirebaseFirestore.instance
                .collection('listings')
                .where('campus_id', isEqualTo: _campusId)
                .where('status', isEqualTo: 'available')
                .snapshots();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_campusId == null) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    return SafeArea("""

if target in text:
    text = text.replace(target, replacement)
    print("Refactored ServicesScreen safely.")
else:
    print("Target not found.")

with open('lib/features/services/presentation/services_screen.dart', 'w') as f:
    f.write(text)
