import '../models/job.dart';

abstract final class ProviderJobPolicy {
  static List<Job> ownedJobs(Iterable<Job> jobs, String providerId) =>
      jobs.where((job) => job.providerId == providerId).toList()
        ..sort((a, b) => b.postedAt.compareTo(a.postedAt));

  static bool canManage(Job job, String providerId) =>
      job.providerId == providerId;
}
