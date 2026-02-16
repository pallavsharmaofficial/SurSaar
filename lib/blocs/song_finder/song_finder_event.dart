import 'package:equatable/equatable.dart';

abstract class SongFinderEvent extends Equatable {
  const SongFinderEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class SongFinderStarted extends SongFinderEvent {
  const SongFinderStarted();
}

class SongFinderChordSelected extends SongFinderEvent {
  const SongFinderChordSelected(this.chord);

  final String chord;

  @override
  List<Object?> get props => <Object?>[chord];
}

class SongFinderCapoUpdated extends SongFinderEvent {
  const SongFinderCapoUpdated(this.capoFret);

  final int capoFret;

  @override
  List<Object?> get props => <Object?>[capoFret];
}
