import 'package:equatable/equatable.dart';
import 'package:refsure/core/models/message.dart';

sealed class MessagingState extends Equatable {
  const MessagingState();

  @override
  List<Object?> get props => [];
}

class MessagingInitial extends MessagingState {
  const MessagingInitial();
}

class MessagingLoaded extends MessagingState {
  const MessagingLoaded({required this.messages});

  final List<Message> messages;

  @override
  List<Object?> get props => [messages];
}

class MessagingSending extends MessagingState {
  const MessagingSending({required this.messages});

  final List<Message> messages;

  @override
  List<Object?> get props => [messages];
}

class MessagingError extends MessagingState {
  const MessagingError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
