import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/job_model.dart';

class JobCard extends StatelessWidget {
  final JobModel job;

  const JobCard({super.key, required this.job});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background icon
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.work_history_rounded,
              size: 120,
              color: Colors.grey.withOpacity(0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.business_center_outlined,
                        color: Color(0xFF2D955F),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: GoogleFonts.kanit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.type,
                            style: GoogleFonts.kanit(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (job.isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars, size: 12, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Text(
                              'แนะนำ',
                              style: GoogleFonts.kanit(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC5E1A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: Color(0xFF558B2F),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          job.estimatedIncome,
                          style: GoogleFonts.kanit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF33691E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'รายละเอียด',
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  job.description,
                  style: GoogleFonts.kanit(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.requirement,
                        style: GoogleFonts.kanit(
                          fontSize: 13,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Branded Action Buttons (Multi-platform)
                Column(
                  children: job.platformLinks.entries.map((entry) {
                    final platform = entry.key;
                    final url = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _launchUrl(url),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _getPlatformColors(platform),
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _getPlatformColors(platform)[0].withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _getPlatformIcon(platform),
                              const SizedBox(width: 10),
                              Text(
                                'ดูงานนี้ที่ $platform',
                                style: GoogleFonts.kanit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.open_in_new_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '* แพลตฟอร์มแนะนำที่มีความน่าเชื่อถือและยอดนิยมสูงสุดในขณะนี้',
                    style: GoogleFonts.kanit(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getPlatformColors(String platform) {
    switch (platform.toLowerCase()) {
      case 'fastwork':
        return [const Color(0xFF0066FF), const Color(0xFF00A3FF)];
      case 'jobsdb':
        return [const Color(0xFF003366), const Color(0xFF0055AA)];
      case 'temp':
        return [const Color(0xFFFF8C00), const Color(0xFFFFA500)];
      default:
        return [const Color(0xFF2D955F), const Color(0xFF43A047)];
    }
  }

  Widget _getPlatformIcon(String platform) {
    IconData iconData;
    switch (platform.toLowerCase()) {
      case 'fastwork':
        iconData = Icons.bolt_rounded;
        break;
      case 'jobsdb':
        iconData = Icons.search_rounded;
        break;
      case 'temp':
        iconData = Icons.access_time_rounded;
        break;
      default:
        iconData = Icons.rocket_launch_rounded;
    }
    return Icon(iconData, color: Colors.white, size: 22);
  }
}
