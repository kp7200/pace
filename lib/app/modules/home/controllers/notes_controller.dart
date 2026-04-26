import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/note.dart';
import '../../../data/repositories/session_repository.dart';
import 'home_controller.dart';

class NotesController extends GetxController {
  static NotesController get to => Get.find();

  final _uuid = const Uuid();
  final _sessionRepository = Get.find<SessionRepository>();

  final RxList<Note> notes = <Note>[].obs;
  final TextEditingController noteInputController = TextEditingController();
  final FocusNode noteFocusNode = FocusNode();
  final GlobalKey notesSectionKey = GlobalKey();
  final RxBool isNoteFocused = false.obs;
  final RxBool isNoteNotEmpty = false.obs;

  @override
  void onInit() {
    super.onInit();

    noteFocusNode.addListener(() {
      isNoteFocused.value = noteFocusNode.hasFocus;
      if (noteFocusNode.hasFocus) {
        // Auto-scroll so the 'Daily Notes' header reaches the top of the screen.
        Future.delayed(const Duration(milliseconds: 300), () {
          if (notesSectionKey.currentContext != null) {
            Scrollable.ensureVisible(
              notesSectionKey.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
            );
          }
        });
      }
    });

    noteInputController.addListener(() {
      isNoteNotEmpty.value = noteInputController.text.trim().isNotEmpty;
    });
  }

  @override
  void onClose() {
    noteInputController.dispose();
    noteFocusNode.dispose();
    super.onClose();
  }

  void setNotes(List<Note> newNotes) {
    notes.assignAll(newNotes);
  }

  void clearNotes() {
    notes.clear();
  }

  Future<void> addNote() async {
    final content = noteInputController.text.trim();
    if (content.isEmpty) return;

    final homeCtrl = Get.find<HomeController>();
    if (homeCtrl.session.value == null) return; // Cannot add note without session

    final note = Note(id: _uuid.v4(), timestamp: DateTime.now(), content: content);
    notes.insert(0, note);
    noteInputController.clear();

    final updated = homeCtrl.session.value?.copyWith(notes: notes.toList());
    if (updated != null) {
      homeCtrl.session.value = updated;
      await _sessionRepository.saveSession(updated);
    }
  }

  Future<void> deleteNote(String id) async {
    final homeCtrl = Get.find<HomeController>();
    if (homeCtrl.session.value == null) return;

    notes.removeWhere((n) => n.id == id);
    final updated = homeCtrl.session.value?.copyWith(notes: notes.toList());
    if (updated != null) {
      homeCtrl.session.value = updated;
      await _sessionRepository.saveSession(updated);
    }
  }
}
