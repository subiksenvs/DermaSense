import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ds/ds_card.dart';
import '../../widgets/ds/ds_button.dart';
import '../../widgets/ds/ds_toast.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Analysis History"),
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, historyProvider, child) {
          if (historyProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final records = historyProvider.records;

          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surfaceHighlight),
                      ),
                      child: const Icon(
                        Icons.history_outlined,
                        size: 48,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space24),
                    Text(
                      "No Analysis History Yet",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      "Your previous skin scans and diagnostic scores will appear here after your first analysis.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          final displayedRecords = _showAll ? records : records.take(10).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailedChart(context, records),
                const SizedBox(height: AppTheme.space32),
                Text(
                  "Past Scans (${records.length})",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.space16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedRecords.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppTheme.space12),
                  itemBuilder: (context, index) => _buildRecordCard(context, displayedRecords[index]),
                ),
                if (records.length > 10) ...[
                  const SizedBox(height: AppTheme.space16),
                  Center(
                    child: DSButton(
                      label: _showAll ? "Show Less" : "Show All Scans",
                      variant: DSButtonVariant.outline,
                      onPressed: () => setState(() => _showAll = !_showAll),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, AnalysisRecord record) {
    return DSCard(
      variant: DSCardVariant.base,
      padding: EdgeInsets.zero,
      onTap: () {
        DSToast.showInfo(
          context,
          'Score: ${record.overallScore}% • Diagnostic details preserved',
          title: DateFormat('d MMM yyyy, h:mm a').format(record.date),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.space16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Center(
            child: Text(
              '${record.overallScore}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
        title: const Text(
          "Skin Analysis",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat.yMMMd().format(record.date), style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(
                'Top Concern: ${record.conditions.isNotEmpty ? record.conditions.entries.reduce((a, b) => a.value > b.value ? a : b).key : 'None identified'}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildDetailedChart(BuildContext context, List<AnalysisRecord> records) {
    // Sort chronological for chart (oldest first)
    final chartRecords = List<AnalysisRecord>.from(records)..sort((a, b) => a.date.compareTo(b.date));
    
    // Show more records in the detailed view (up to 14)
    final displayRecords = chartRecords.length > 14 ? chartRecords.sublist(chartRecords.length - 14) : chartRecords;

    List<FlSpot> spots = [];
    for (int i = 0; i < displayRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), displayRecords[i].overallScore.toDouble()));
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Overall Score History",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.space24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.surfaceHighlight,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < displayRecords.length) {
                          // Only show every other label if many records to avoid crowding
                          if (displayRecords.length > 7 && value.toInt() % 2 != 0) {
                            return const Text('');
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MM/dd').format(displayRecords[value.toInt()].date),
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (displayRecords.length - 1).toDouble().clamp(0, double.infinity),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.primary,
                          strokeWidth: 2,
                          strokeColor: AppTheme.surfaceBase,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
