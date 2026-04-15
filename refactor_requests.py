import sys

with open('lib/features/requests/presentation/requests_screen.dart', 'r') as f:
    text = f.read()

target = """    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Campus Requests',
          style: AppTypography.h2.copyWith(color: colors.onSurface),
        ),
        centerTitle: true,
      ),
      body: Column("""

replacement = """    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Campus Requests',
          style: AppTypography.h2.copyWith(color: colors.onSurface),
        ),
        centerTitle: true,
      ),
      body: const RequestsScreenContent(),
    );
  }
}

class RequestsScreenContent extends StatefulWidget {
  const RequestsScreenContent({super.key});

  @override
  State<RequestsScreenContent> createState() => _RequestsScreenContentState();
}

class _RequestsScreenContentState extends State<RequestsScreenContent> {
  String? _campusId;
  String searchQuery = '';
  Stream<QuerySnapshot>? _requestsStream;

  @override
  void initState() {
    super.initState();
    _loadCampusId();
  }

  Future<void> _loadCampusId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('campus_id');
    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _campusId = cached;
          _requestsStream = FirebaseFirestore.instance
              .collection('listings')
              .where('campus_id', isEqualTo: _campusId)
              .where('status', isEqualTo: 'available')
              .limit(50)
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
            _requestsStream = FirebaseFirestore.instance
                .collection('listings')
                .where('campus_id', isEqualTo: _campusId)
                .where('status', isEqualTo: 'available')
                .limit(50)
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

    return Column("""

if target in text:
    text = text.replace(target, replacement)
    print("Refactored RequestsScreen safely.")
else:
    print("Target not found.")

with open('lib/features/requests/presentation/requests_screen.dart', 'w') as f:
    f.write(text)
