import 'package:equatable/equatable.dart';

import '../../../publication/domain/entities/topic.dart';
import '../../domain/entities/research_dashboard_summary.dart';

abstract class ResearchDashboardState extends Equatable {
  const ResearchDashboardState();

  @override
  List<Object?> get props => [];
}

class ResearchDashboardInitial extends ResearchDashboardState {
  const ResearchDashboardInitial();
}

class ResearchDashboardLoading extends ResearchDashboardState {
  final Topic topic;

  const ResearchDashboardLoading(this.topic);

  @override
  List<Object?> get props => [topic];
}

class ResearchDashboardLoaded extends ResearchDashboardState {
  final ResearchDashboardSummary summary;

  const ResearchDashboardLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class ResearchDashboardEmpty extends ResearchDashboardState {
  final Topic topic;

  const ResearchDashboardEmpty(this.topic);

  @override
  List<Object?> get props => [topic];
}

class ResearchDashboardError extends ResearchDashboardState {
  final String message;
  final Topic topic;

  const ResearchDashboardError(this.message, this.topic);

  @override
  List<Object?> get props => [message, topic];
}
