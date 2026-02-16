import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/song_repository.dart';
import 'song_finder_event.dart';
import 'song_finder_state.dart';

class SongFinderBloc extends Bloc<SongFinderEvent, SongFinderState> {
  SongFinderBloc({
    required SongRepository repository,
  })  : _repository = repository,
        super(SongFinderState.initial()) {
    on<SongFinderStarted>(_onStarted);
    on<SongFinderChordSelected>(_onChordSelected);
    on<SongFinderCapoUpdated>(_onCapoUpdated);
    on<SongFinderFavoriteToggled>(_onFavoriteToggled);
  }

  final SongRepository _repository;

  Future<void> _onStarted(
    SongFinderStarted event,
    Emitter<SongFinderState> emit,
  ) async {
    emit(state.copyWith(status: SongFinderStatus.loading));
    try {
      final songs = await _repository.getSongs();
      final filtered = await _repository.filterSongs(
        rootChord: state.selectedChord,
        capoFret: state.capoFret,
      );
      emit(
        state.copyWith(
          status: SongFinderStatus.ready,
          allSongs: songs,
          filteredSongs: filtered,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: SongFinderStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onChordSelected(
    SongFinderChordSelected event,
    Emitter<SongFinderState> emit,
  ) async {
    final filtered = await _repository.filterSongs(
      rootChord: event.chord,
      capoFret: state.capoFret,
    );
    emit(
      state.copyWith(
        selectedChord: event.chord,
        filteredSongs: filtered,
      ),
    );
  }

  Future<void> _onCapoUpdated(
    SongFinderCapoUpdated event,
    Emitter<SongFinderState> emit,
  ) async {
    final filtered = await _repository.filterSongs(
      rootChord: state.selectedChord,
      capoFret: event.capoFret,
    );
    emit(
      state.copyWith(
        capoFret: event.capoFret,
        filteredSongs: filtered,
      ),
    );
  }

  Future<void> _onFavoriteToggled(
    SongFinderFavoriteToggled event,
    Emitter<SongFinderState> emit,
  ) async {
    await _repository.toggleFavorite(event.songId, event.isFavorite);
    final songs = await _repository.getSongs();
    final filtered = await _repository.filterSongs(
      rootChord: state.selectedChord,
      capoFret: state.capoFret,
    );
    emit(
      state.copyWith(
        allSongs: songs,
        filteredSongs: filtered,
      ),
    );
  }
}
