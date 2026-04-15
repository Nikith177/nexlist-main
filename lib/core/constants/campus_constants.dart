const Map<String, String> campusNames = {
  'nit-kkr': 'NIT Kurukshetra',
  'iit-bhu': 'IIT BHU',
  // future campuses here
};

String getCampusName(String? campusId) {
  if (campusId == null) return 'Unknown Campus';
  return campusNames[campusId] ?? 'Unknown Campus';
}
