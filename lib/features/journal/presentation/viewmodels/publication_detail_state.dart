import 'package:equatable/equatable.dart';

import '../../../publication/domain/entities/work.dart';

sealed class PublicationDetailState extends Equatable {
  const PublicationDetailState();

  @override
  List<Object?> get props => [];
}

class PublicationDetailInitial extends PublicationDetailState {
  const PublicationDetailInitial();
}

class PublicationDetailLoading extends PublicationDetailState {
  final Work? preview;

  const PublicationDetailLoading({this.preview});

  @override
  List<Object?> get props => [preview?.id];
}

class PublicationDetailLoaded extends PublicationDetailState {
  final Work work;

  const PublicationDetailLoaded(this.work);

  @override
  List<Object?> get props => [work.id];
}

class PublicationDetailError extends PublicationDetailState {
  final String message;
  final Work? preview;

  const PublicationDetailError({required this.message, this.preview});

  @override
  List<Object?> get props => [message, preview?.id];
}
