import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:screenshot/screenshot.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../tasks/presentation/cubit/tasks_cubit.dart';
import '../../../tasks/presentation/cubit/tasks_state.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../services/report_service.dart';

class ProductivityScreen extends StatefulWidget {
  const ProductivityScreen({super.key});

  @override
  State<ProductivityScreen> createState() => _ProductivityScreenState();
}

class _ProductivityScreenState extends State<ProductivityScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
        actions: [
          if (_isExporting)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.ios_share_rounded),
              onSelected: (v) async {
                setState(() => _isExporting = true);
                final state = context.read<TasksCubit>().state;
                if (v == 'pdf') {
                  await ReportService.shareProductivityPdf(state.tasks);
                } else if (v == 'img') {
                  final img = await _screenshotController.capture(delay: const Duration(milliseconds: 100)); // allow rebuild
                  if (img != null) await ReportService.shareScreenshot(img);
                }
                setState(() => _isExporting = false);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'img', child: Row(children: [Icon(Icons.image, size: 20), SizedBox(width: 10), Text('Share Image')])),
                const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf, size: 20), SizedBox(width: 10), Text('Share PDF')])),
              ],
            ),
        ]),
      body: BlocBuilder<TasksCubit, TasksState>(builder: (context, state) {
        final completed = state.tasks.where((t) => t.status == TaskStatus.completed).length;
        final pending = state.tasks.where((t) => t.status == TaskStatus.pending).length;
        final canceled = state.tasks.where((t) => t.status == TaskStatus.canceled).length;
        final total = state.tasks.length;
        final score = total > 0 ? (completed / total * 100) : 0.0;

        return Screenshot(
          controller: _screenshotController,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListView(padding: const EdgeInsets.all(16), children: [
          // Score card
          StaggeredItem(index: 0, child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Row(children: [
              ProgressRing(progress: score / 100, size: 100, strokeWidth: 10,
                color: Colors.white, backgroundColor: Colors.white.withOpacity(0.2),
                child: Text('${score.toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Overall Score', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text('${score.toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$completed of $total tasks done', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ])),
            ]),
          )),
          const SizedBox(height: 16),

          // Stats cards
          StaggeredItem(index: 1, child: Row(children: [
            _MiniStat(label: 'Completed', value: '$completed', color: AppColors.success, icon: Icons.check_circle),
            const SizedBox(width: 10),
            _MiniStat(label: 'Pending', value: '$pending', color: AppColors.warning, icon: Icons.pending),
            const SizedBox(width: 10),
            _MiniStat(label: 'Canceled', value: '$canceled', color: AppColors.error, icon: Icons.cancel),
          ])),
          const SizedBox(height: 20),

          // Pie chart
          StaggeredItem(index: 2, child: GlassCard(margin: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Task Distribution', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              SizedBox(height: 200, child: total == 0
                ? Center(child: Text('No data yet', style: Theme.of(context).textTheme.bodySmall))
                : PieChart(PieChartData(
                    sectionsSpace: 3, centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(color: AppColors.success, value: completed.toDouble(),
                        title: '$completed', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      PieChartSectionData(color: AppColors.warning, value: pending.toDouble(),
                        title: '$pending', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      PieChartSectionData(color: AppColors.error, value: canceled.toDouble(),
                        title: '$canceled', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ))),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _Legend(color: AppColors.success, label: 'Completed'),
                const SizedBox(width: 16),
                _Legend(color: AppColors.warning, label: 'Pending'),
                const SizedBox(width: 16),
                _Legend(color: AppColors.error, label: 'Canceled'),
              ]),
            ]))),
        ]),
      ),
    );
      }),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GlassCard(margin: EdgeInsets.zero, padding: const EdgeInsets.all(14),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ])));
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ]);
  }
}
