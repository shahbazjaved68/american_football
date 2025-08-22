import 'package:flutter/material.dart';
import 'playerdetails.dart'; // Import Item and models

class PlayerBrief extends StatelessWidget {
  final Item player;

  const PlayerBrief({Key? key, required this.player}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final birthPlace = player.birthPlace;
    final college = player.college;
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final labelColor = theme.colorScheme.primary;
    final valueColor = theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onBackground;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(player.headshot.href),
              backgroundColor: theme.cardColor,
            ),
            const SizedBox(height: 16),
            Text(
              player.fullName,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _infoRow("Position", player.position.displayName, labelColor, valueColor),
            _infoRow("Jersey", player.jersey ?? "N/A", labelColor, valueColor),
            _infoRow("Height", player.displayHeight, labelColor, valueColor),
            _infoRow("Weight", player.displayWeight, labelColor, valueColor),
            _infoRow("Age", player.age?.toString() ?? "N/A", labelColor, valueColor),
            _infoRow("Date of Birth", _formatDateOfBirth(player.dateOfBirth), labelColor, valueColor),
            _infoRow("Experience", "${player.experience.years} year(s)", labelColor, valueColor),
            _infoRow("College", college.name, labelColor, valueColor),
            _infoRow("College Mascot", college.mascot, labelColor, valueColor),
            _infoRow("Birthplace", _formatBirthPlace(birthPlace.city, birthPlace.state, birthPlace.country), labelColor, valueColor),
            const SizedBox(height: 10),
            if (player.injuries.isNotEmpty) ...[
              Divider(color: labelColor),
              Text(
                "Injuries",
                style: TextStyle(color: labelColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...player.injuries.map((injury) =>
                _infoRow("Status (${injury.date})", injury.status, labelColor, valueColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ",
              style: TextStyle(color: labelColor, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBirthPlace(String city, String? state, Country country) {
    final c = country.toString().split('.').last;
    return (state != null && state.isNotEmpty)
        ? "$city, $state, $c"
        : "$city, $c";
  }

  String _formatDateOfBirth(String? dateOfBirth) {
    if (dateOfBirth == null || dateOfBirth.isEmpty) return "N/A";
    try {
      final d = DateTime.parse(dateOfBirth);
      return "${_monthName(d.month)} ${d.day}, ${d.year}";
    } catch (e) {
      return dateOfBirth;
    }
  }

  String _monthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : "";
  }
}
