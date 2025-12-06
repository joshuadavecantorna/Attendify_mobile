import 'package:flutter_bloc/flutter_bloc.dart';
import 'student_event.dart';
import 'student_state.dart';
import '../data/student_repository.dart';

class StudentBloc extends Bloc<StudentEvent, StudentState> {
  final StudentRepository _repository;

  StudentBloc({required StudentRepository repository})
      : _repository = repository,
        super(const StudentInitial()) {
    on<LoadStudentDashboard>(_onLoadDashboard);
    on<LoadStudentClasses>(_onLoadClasses);
    on<LoadAttendanceRecords>(_onLoadAttendanceRecords);
    on<LoadTodaySchedule>(_onLoadTodaySchedule);
    on<CheckInWithQR>(_onCheckInWithQR);
    on<LoadExcuseRequests>(_onLoadExcuseRequests);
    on<SubmitExcuseRequest>(_onSubmitExcuseRequest);
  }

  Future<void> _onLoadDashboard(
    LoadStudentDashboard event,
    Emitter<StudentState> emit,
  ) async {
    emit(const StudentLoading());
    try {
      final classes = await _repository.getStudentClasses();
      final summary = await _repository.getAttendanceSummary();
      final schedule = await _repository.getTodaySchedule();

      emit(StudentDashboardLoaded(
        classes: classes,
        attendanceSummary: summary,
        todaySchedule: schedule,
      ));
    } catch (e) {
      emit(StudentError(message: e.toString()));
    }
  }

  Future<void> _onLoadClasses(
    LoadStudentClasses event,
    Emitter<StudentState> emit,
  ) async {
    emit(const StudentLoading());
    try {
      final classes = await _repository.getStudentClasses();
      emit(StudentClassesLoaded(classes: classes));
    } catch (e) {
      emit(StudentError(message: e.toString()));
    }
  }

  Future<void> _onLoadAttendanceRecords(
    LoadAttendanceRecords event,
    Emitter<StudentState> emit,
  ) async {
    emit(const StudentLoading());
    try {
      final records = await _repository.getAttendanceRecords(
        classId: event.classId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(AttendanceRecordsLoaded(records: records));
    } catch (e) {
      emit(StudentError(message: e.toString()));
    }
  }

  Future<void> _onLoadTodaySchedule(
    LoadTodaySchedule event,
    Emitter<StudentState> emit,
  ) async {
    emit(const StudentLoading());
    try {
      final schedule = await _repository.getTodaySchedule();
      emit(TodayScheduleLoaded(schedule: schedule));
    } catch (e) {
      emit(StudentError(message: e.toString()));
    }
  }

  Future<void> _onCheckInWithQR(
    CheckInWithQR event,
    Emitter<StudentState> emit,
  ) async {
    emit(const StudentLoading());
    try {
      final result = await _repository.checkInWithQR(event.qrData);
      emit(CheckInSuccess(
        message: result['message'] ?? 'Check-in successful!',
        data: result,
      ));
    } catch (e) {
      emit(StudentError(message: e.toString()));
    }
  }

  Future<void> _onLoadExcuseRequests(
    LoadExcuseRequests event,
    Emitter<StudentState> emit,
  ) async {
    emit(const StudentLoading());
    try {
      final requests = await _repository.getExcuseRequests();
      emit(ExcuseRequestsLoaded(requests: requests));
    } catch (e) {
      emit(StudentError(message: e.toString()));
    }
  }

  Future<void> _onSubmitExcuseRequest(
    SubmitExcuseRequest event,
    Emitter<StudentState> emit,
  ) async {
    emit(const StudentLoading());
    try {
      final request = await _repository.submitExcuseRequest(
        attendanceSessionId: event.attendanceSessionId,
        reason: event.reason,
        attachmentPath: event.attachmentPath,
      );
      emit(ExcuseRequestSubmitted(request: request));
    } catch (e) {
      emit(StudentError(message: e.toString()));
    }
  }
}
