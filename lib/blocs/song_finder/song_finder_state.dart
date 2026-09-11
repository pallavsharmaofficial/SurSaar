import 'package:equatable/equatable.dart';
import '../../models/song.dart';

enum SongFinderStatus { initial, loading, ready, error }

class SongFinderState extends Equatable {
  const SongFinderState({
    required this.status,
    required this.selectedChord,
    required this.capoFret,
    required this.allSongs,
    required this.filteredSongs,
    this.errorMessage,
  });

  factory SongFinderState.initial() => const SongFinderState(
    status: SongFinderStatus.initial,
    selectedChord: 'G',
    capoFret: 0,
    allSongs: <Song>[],
    filteredSongs: <Song>[],
  );

  final SongFinderStatus status;
  final String selectedChord;
  final int capoFret;
  final List<Song> allSongs;
  final List<Song> filteredSongs;
  final String? errorMessage;

  SongFinderState copyWith({
    SongFinderStatus? status,
    String? selectedChord,
    int? capoFret,
    List<Song>? allSongs,
    List<Song>? filteredSongs,
    String? errorMessage,
  }) {
    return SongFinderState(
      status: status ?? this.status,
      selectedChord: selectedChord ?? this.selectedChord,
      capoFret: capoFret ?? this.capoFret,
      allSongs: allSongs ?? this.allSongs,
      filteredSongs: filteredSongs ?? this.filteredSongs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    selectedChord,
    capoFret,
    allSongs,
    filteredSongs,
    errorMessage,
  ];
}
