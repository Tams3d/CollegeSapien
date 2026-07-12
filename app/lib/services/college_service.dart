import '../models/api_models.dart';
import '../providers/reference_data_store.dart';
import '../utils/department_constants.dart';

/// Thin facade over [ReferenceDataStore] — colleges/departments are
/// non-user-specific reference data, cached long-TTL and shared across the
/// whole app (see ReferenceDataStore for the actual fetch/cache logic).
class CollegeService {
  Future<List<College>> listColleges({bool forceRefresh = false}) =>
      ReferenceDataStore.instance.listColleges(forceRefresh: forceRefresh);

  Future<List<Department>> listDepartments({bool forceRefresh = false}) =>
      ReferenceDataStore.instance.listDepartments(forceRefresh: forceRefresh);
}
