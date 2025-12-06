import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _adminRepository;

  AdminBloc({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(const AdminInitial()) {
    on<LoadSystemStats>(_onLoadSystemStats);
    on<LoadAttendanceReport>(_onLoadAttendanceReport);
    on<LoadAllUsers>(_onLoadAllUsers);
    on<LoadUserById>(_onLoadUserById);
    on<CreateUser>(_onCreateUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
    on<LoadAllClasses>(_onLoadAllClasses);
    on<LoadClassById>(_onLoadClassById);
    on<CreateClass>(_onCreateClass);
    on<UpdateClass>(_onUpdateClass);
    on<DeleteClass>(_onDeleteClass);
    on<LoadClassEnrollments>(_onLoadClassEnrollments);
    on<EnrollStudent>(_onEnrollStudent);
    on<UnenrollStudent>(_onUnenrollStudent);
  }

  Future<void> _onLoadSystemStats(
    LoadSystemStats event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      final stats = await _adminRepository.getSystemStats();
      emit(SystemStatsLoaded(stats: stats));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onLoadAttendanceReport(
    LoadAttendanceReport event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      final report = await _adminRepository.getAttendanceReport(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(AttendanceReportLoaded(report: report));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onLoadAllUsers(
    LoadAllUsers event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      final users = await _adminRepository.getAllUsers(role: event.role);
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onLoadUserById(
    LoadUserById event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      final user = await _adminRepository.getUserById(event.userId);
      emit(UserLoaded(user: user));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onCreateUser(
    CreateUser event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      final user = await _adminRepository.createUser(
        name: event.name,
        email: event.email,
        password: event.password,
        role: event.role,
        studentId: event.studentId,
        teacherId: event.teacherId,
      );
      emit(UserCreated(user: user));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      final user = await _adminRepository.updateUser(
        userId: event.userId,
        name: event.name,
        email: event.email,
        role: event.role,
        password: event.password,
      );
      emit(UserUpdated(user: user));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUser event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      await _adminRepository.deleteUser(event.userId);
      emit(const UserDeleted(message: 'User deleted successfully'));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onLoadAllClasses(
    LoadAllClasses event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      final classes = await _adminRepository.getAllClasses();
      emit(ClassesLoaded(classes: classes));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onLoadClassById(
    LoadClassById event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      final classData = await _adminRepository.getClassById(event.classId);
      emit(ClassLoaded(classData: classData));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onCreateClass(
    CreateClass event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      final classData = await _adminRepository.createClass(
        name: event.name,
        code: event.code,
        description: event.description,
        schedule: event.schedule,
        teacherId: event.teacherId,
      );
      emit(ClassCreated(classData: classData));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onUpdateClass(
    UpdateClass event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      final classData = await _adminRepository.updateClass(
        classId: event.classId,
        name: event.name,
        code: event.code,
        description: event.description,
        schedule: event.schedule,
        teacherId: event.teacherId,
      );
      emit(ClassUpdated(classData: classData));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onDeleteClass(
    DeleteClass event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      await _adminRepository.deleteClass(event.classId);
      emit(const ClassDeleted(message: 'Class deleted successfully'));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onLoadClassEnrollments(
    LoadClassEnrollments event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      final enrollments = await _adminRepository.getClassEnrollments(event.classId);
      emit(EnrollmentsLoaded(enrollments: enrollments));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onEnrollStudent(
    EnrollStudent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      await _adminRepository.enrollStudent(
        classId: event.classId,
        studentId: event.studentId,
      );
      emit(const StudentEnrolled(message: 'Student enrolled successfully'));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onUnenrollStudent(
    UnenrollStudent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      emit(const AdminLoading());
      await _adminRepository.unenrollStudent(
        classId: event.classId,
        studentId: event.studentId,
      );
      emit(const StudentUnenrolled(message: 'Student unenrolled successfully'));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }
}
