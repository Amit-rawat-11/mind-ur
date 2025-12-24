
import '../models/journal.dart';

List<JournalEntry> demoJournalEntries = [
  JournalEntry(
    title: "Welcome to Your Journal",
    content:
        "This is your space to reflect, write, and grow. You can add, edit, or delete entries from the Journal screen. These are just sample entries and will be removed once you create your first journal entry.",
    timestamp: DateTime.now().subtract(Duration(hours: 1)),
  ),
  JournalEntry(
    title: "Mindful Start",
    content:
        "Started my day with a short walk and some deep breathing. Felt calmer and more focused. I’m beginning to realize how small changes can make a big difference in how I feel.",
    timestamp: DateTime.now().subtract(Duration(days: 1)),
  ),
  JournalEntry(
    title: "Midweek Check-in",
    content:
        "Feeling a little overwhelmed but making progress. Took 10 minutes to journal and center myself. Grateful I’m building this habit — it’s helping more than I thought.",
    timestamp: DateTime.now().subtract(Duration(days: 2)),
  ),
];
