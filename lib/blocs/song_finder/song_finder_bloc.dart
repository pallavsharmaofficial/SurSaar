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
  }

  final SongRepository _repository;

  void _onStarted(
    SongFinderStarted event,
    Emitter<SongFinderState> emit,
  ) {
    final songs = _repository.getSongs();
    final filtered = _repository.filterSongs(
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
  }

  void _onChordSelected(
    SongFinderChordSelected event,
    Emitter<SongFinderState> emit,
  ) {
    final filtered = _repository.filterSongs(
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

  void _onCapoUpdated(
    SongFinderCapoUpdated event,
    Emitter<SongFinderState> emit,
  ) {
    final filtered = _repository.filterSongs(
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
}
