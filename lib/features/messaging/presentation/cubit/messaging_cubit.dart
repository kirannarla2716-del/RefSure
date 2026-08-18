import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:refsure/core/models/message.dart';
import 'package:refsure/features/messaging/data/messaging_repository.dart';
import 'package:refsure/features/messaging/presentation/cubit/messaging_state.dart';

class MessagingCubit extends Cubit<MessagingState> {
  MessagingCubit({required MessagingRepository messagingRepository})
      : _repository = messagingRepository,
        super(const MessagingInitial());

  final MessagingRepository _repository;
  StreamSubscription<List<Message>>? _msgsSub;

  void loadConversation(String myId, String otherId) {
    _msgsSub?.cancel();
    _msgsSub = _repository.watchConversation(myId, otherId).listen(
      (messages) {
        emit(MessagingLoaded(messages: messages));
      },
      onError: (Object error) {
        emit(MessagingError(error.toString()));
      },
    );
  }

  Future<void> sendMessage(Message message) async {
    final current = state;
    if (current is MessagingLoaded) {
      emit(MessagingSending(messages: current.messages));
    }
    try {
      await _repository.sendMessage(message);
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _msgsSub?.cancel();
    return super.close();
  }
}
