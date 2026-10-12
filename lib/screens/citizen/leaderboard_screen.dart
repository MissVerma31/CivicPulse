import 'package:flutter/material.dart';
import '../../core/network/dio_client.dart';
import '../../models/reward_model.dart';
import '../../repositories/reward_repo.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final RewardRepository _rewardRepository;
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rewardRepository = RewardRepository(DioClient.createDio());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final entries = await _rewardRepository.getLeaderboard();
      setState(() => _entries = entries);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.grey.shade500;
      case 3:
        return Colors.brown.shade400;
      default:
        return Colors.blueGrey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
          children: [
            const SizedBox(height: 100),
            Center(child: Text(_error!)),
          ],
        )
            : _entries.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 150),
            Center(child: Text('No leaderboard data yet')),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _entries.length,
          itemBuilder: (context, index) {
            final e = _entries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _rankColor(e.rank),
                  child: Text(
                    '${e.rank}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(e.city),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${e.reputationPoints}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Text('points', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}