import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../tasks/domain/entities/task_entity.dart';

class ReportService {
  static Future<void> shareProductivityPdf(List<TaskEntity> tasks) async {
    final pdf = pw.Document();
    
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
    final canceled = tasks.where((t) => t.status == TaskStatus.canceled).length;
    final total = tasks.length;
    final score = total > 0 ? (completed / total * 100) : 0.0;
    
    // Create the PDF page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Productivity Report', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Date: ${DateFormat('MMMM d, yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 30),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Summary', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 15),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatBox('Score', '${score.toStringAsFixed(1)}%', PdfColors.blue),
                        _buildStatBox('Total', '$total', PdfColors.grey800),
                        _buildStatBox('Done', '$completed', PdfColors.green),
                        _buildStatBox('Pending', '$pending', PdfColors.orange),
                        _buildStatBox('Canceled', '$canceled', PdfColors.red),
                      ]
                    ),
                  ]
                )
              ),
              
              pw.SizedBox(height: 30),
              pw.Text('Task Breakdown', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 15),
              
              if (tasks.isEmpty)
                pw.Text('No tasks recorded.', style: pw.TextStyle(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic))
              else
                pw.ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final t = tasks[index];
                    final statusColor = t.status == TaskStatus.completed 
                        ? PdfColors.green 
                        : (t.status == TaskStatus.pending ? PdfColors.orange : PdfColors.red);
                        
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(t.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Text(t.status.name.toUpperCase(), style: pw.TextStyle(color: statusColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ]
                      )
                    );
                  }
                )
            ],
          );
        },
      ),
    );

    // Save correctly as File and share
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/productivity_report.pdf');
    await file.writeAsBytes(bytes);
    
    await Share.shareXFiles([XFile(file.path)], text: 'Check out my daily productivity report from DLTRS! 🚀');
  }
  
  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
      ]
    );
  }
  
  static Future<void> shareScreenshot(Uint8List imageBytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/productivity_screenshot.png');
    await file.writeAsBytes(imageBytes);
    
    await Share.shareXFiles([XFile(file.path)], text: 'My productivity stats right now! 📊 #DLTRS');
  }
}
