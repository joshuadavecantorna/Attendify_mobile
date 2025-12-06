import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/teacher_repository.dart';
import 'teacher_event.dart';
import 'teacher_state.dart';

class TeacherBloc extends Bloc<TeacherEvent, TeacherState> {
  final TeacherRepository _teacherRepository;

  TeacherBloc({required TeacherRepository teacherRepository})
      : _teacherRepository = teacherRepository,
        super(const TeacherInitial()) {
    on<LoadTeacherDashboard>(_onLoadTeacherDashboard);
    on<LoadTeacherClasses>(_onLoadTeacherClasses);
    on<LoadClassStudents>(_onLoadClassStudents);
    on<CreateAttendanceSession>(_onCreateAttendanceSession);
    on<LoadAttendanceSessions>(_onLoadAttendanceSessions);
    on<MarkStudentAttendance>(_onMarkStudentAttendance);
    on<EndAttendanceSession>(_onEndAttendanceSession);
    on<LoadPendingExcuses>(_onLoadPendingExcuses);
    on<LoadAllExcuses>(_onLoadAllExcuses);
    on<ReviewExcuseRequest>(_onReviewExcuseRequest);
    on<LoadClassAttendanceReport>(_onLoadClassAttendanceReport);
  }

  Future<void> _onLoadTeacherDashboard(
    LoadTeacherDashboard event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      emit(const TeacherLoading());
      final dashboardData = await _teacherRepository.getDashboardSummary();
      emit(TeacherDashboardLoaded(dashboardData: dashboardData));
    } catch (e) {
      emit(TeacherError(message: e.toString()));
    }
  }

  Future<void> _onLoadTeacherClasses(
    LoadTeacherClasses event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      emit(const TeacherLoading());
      final classes = await _teacherRepository.getTeacherClasses();
      emit(TeacherClassesLoaded(classes: classes));
    } catch (e) {
      emit(TeacherError(message: e.toString()));
    }
  }

  Future<void> _onLoadClassStudents(
    LoadClassStudents event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      emit(const TeacherLoading());
      final students = await _teacherRepository.getClassStudents(event.classId);
      emit(ClassStudentsLoaded(students: students, classId: event.classId));
    } catch (e) {
      emit(TeacherError(message: e.toString()));
    }
  }

  Future<void> _onCreateAttendanceSession(
    CreateAttendanceSession event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      emit(const TeacherLoading());
      final session = await _teacherRepository.createAttendanceSession(
        classId: event.classId,
        startTime: event.startTime,
        endTime: event.endTime,
        generateQR: event.generateQR,
      );
      emit(AttendanceSessionCreated(session: session));
    } catch (e) {
      emit(TeacherError(message: e.toString()));
    }
  }

  Future<void> _onLoadAttendanceSessions(
    LoadAttendanceSessions event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      emit(const TeacherLoading());
      final sessions = await _teacherRepository.getAttendanceSessions(
        classId: event.classId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(AttendanceSessionsLoaded(sessions: sessions));
    } catch (e) {
      emit(TeacherError(message: e.toString()));
    }
  }

  Future<void> _onMarkStudentAttendance(
    MarkStudentAttendance event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      emit(const TeacherLoading());
      await _teacherRepository.markAttendance(
        sessionId: event.sessionId,
        studentId: event.studentId,
        status: event.status,
      );
      emit(const AttendanceMarked(
        message: 'Attendance marked successfully',
      ));
    } catch (e) {
      emit(TeacherError(message: e.toString()));
    }
  }

  Future<void> _onEndAttendanceSession(
    EndAttendanceSession event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      emit(const TeacherLoading());
      await _teacherRepository.endAttendanceSession(event.sessionId);
      emit(const AttendanceSessionEnded(
        message: 'Attendance session ended successfully',
      ));
    } catch (e) {
      emit(TeacherError(message: e.toString()));
    }
  }

  Future<void> _onLoadPendingExcuses(
    LoadPendingExcuses event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      emit(const TeacherLoading());
      final excuses = await _teacherRepository.getPendingExcuses();
      emit(PendingExcusesLoaded(excuses: excuses));
    } catch (e) {
      emit(TeacherError(message: e.toString()));
    }
  }

  Future<void> _onLoadAllExcuses(
    LoadAllExcuses event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      emit(const TeacherLoading());
      final excuses = await _teacherRepository.getAllExcuses();
      emit(AllExcusesLoaded(excuses: excuses));
    } catch (e) {
      emit(TeacherError(message: e.toString()));
    }
  }

  Future<void> _onReviewExcuseRequest(
    ReviewExcuseRequest event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      emit(const TeacherLoading());
      await _teacherRepository.reviewExcuseRequest(
        excuseId: event.excuseId,
        status: event.status,
        response: event.response,
      );
      emit(const ExcuseRequestReviewed(
        message: 'Excuse request reviewed successfully',
      ));
    } catch (e) {
      emit(TeacherError(message: e.toString()));
    }
  }

  Future<void> _onLoadClassAttendanceReport(
    LoadClassAttendanceReport event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      emit(const TeacherLoading());
      final reportData =
          await _teacherRepository.getClassAttendanceReport(event.classId);
      emit(ClassAttendanceReportLoaded(reportData: reportData));
    } catch (e) {
      emit(TeacherError(message: e.toString()));
    }
  }
}
