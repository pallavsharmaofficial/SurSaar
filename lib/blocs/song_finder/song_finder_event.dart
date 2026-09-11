import 'package:equatable/equatable.dart';

abstract class SongFinderEvent extends Equatable {
  const SongFinderEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class SongFinderStarted extends SongFinderEvent {
  const SongFinderStarted();
}

/// Reloads songs (after returning from a detail screen or pull-to-refresh).
class SongFinderRefreshed extends SongFinderEvent {
  const SongFinderRefreshed();
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

class SongFinderFavoriteToggled extends SongFinderEvent {
  const SongFinderFavoriteToggled({
    required this.songId,
    required this.isFavorite,
  });

  final String songId;
  final bool isFavorite;

  @override
  List<Object?> get props => <Object?>[songId, isFavorite];
}
