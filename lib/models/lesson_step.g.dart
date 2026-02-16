// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonStep _$LessonStepFromJson(Map<String, dynamic> json) => LessonStep(
      title: json['title'] as String,
      description: json['description'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
    );

Map<String, dynamic> _$LessonStepToJson(LessonStep instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'durationMinutes': instance.durationMinutes,
    };
