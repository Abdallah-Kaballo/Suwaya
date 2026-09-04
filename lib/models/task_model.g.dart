// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTaskModelCollection on Isar {
  IsarCollection<TaskModel> get taskModels => this.collection();
}

const TaskModelSchema = CollectionSchema(
  name: r'TaskModel',
  id: -1192054402460482572,
  properties: {
    r'alarmMode': PropertySchema(
      id: 0,
      name: r'alarmMode',
      type: IsarType.bool,
    ),
    r'alarmTone': PropertySchema(
      id: 1,
      name: r'alarmTone',
      type: IsarType.string,
    ),
    r'alarmVolume': PropertySchema(
      id: 2,
      name: r'alarmVolume',
      type: IsarType.double,
    ),
    r'category': PropertySchema(
      id: 3,
      name: r'category',
      type: IsarType.byte,
      enumMap: _TaskModelcategoryEnumValueMap,
    ),
    r'completedAt': PropertySchema(
      id: 4,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'completionHistory': PropertySchema(
      id: 5,
      name: r'completionHistory',
      type: IsarType.dateTimeList,
    ),
    r'createdAt': PropertySchema(
      id: 6,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'currentStreak': PropertySchema(
      id: 7,
      name: r'currentStreak',
      type: IsarType.long,
    ),
    r'dialShortName': PropertySchema(
      id: 8,
      name: r'dialShortName',
      type: IsarType.string,
    ),
    r'isAstroTime': PropertySchema(
      id: 9,
      name: r'isAstroTime',
      type: IsarType.bool,
    ),
    r'isCompleted': PropertySchema(
      id: 10,
      name: r'isCompleted',
      type: IsarType.bool,
    ),
    r'isDeleted': PropertySchema(
      id: 11,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 12,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastCompletedDate': PropertySchema(
      id: 13,
      name: r'lastCompletedDate',
      type: IsarType.dateTime,
    ),
    r'longestStreak': PropertySchema(
      id: 14,
      name: r'longestStreak',
      type: IsarType.long,
    ),
    r'migrationCount': PropertySchema(
      id: 15,
      name: r'migrationCount',
      type: IsarType.long,
    ),
    r'notifyMode': PropertySchema(
      id: 16,
      name: r'notifyMode',
      type: IsarType.bool,
    ),
    r'recurrenceDays': PropertySchema(
      id: 17,
      name: r'recurrenceDays',
      type: IsarType.longList,
    ),
    r'showOnDial': PropertySchema(
      id: 18,
      name: r'showOnDial',
      type: IsarType.bool,
    ),
    r'syncId': PropertySchema(
      id: 19,
      name: r'syncId',
      type: IsarType.string,
    ),
    r'targetCivilTimeMinutes': PropertySchema(
      id: 20,
      name: r'targetCivilTimeMinutes',
      type: IsarType.long,
    ),
    r'targetDate': PropertySchema(
      id: 21,
      name: r'targetDate',
      type: IsarType.dateTime,
    ),
    r'targetPeriodId': PropertySchema(
      id: 22,
      name: r'targetPeriodId',
      type: IsarType.long,
    ),
    r'targetSuwayas': PropertySchema(
      id: 23,
      name: r'targetSuwayas',
      type: IsarType.longList,
    ),
    r'targetVirtualMinute': PropertySchema(
      id: 24,
      name: r'targetVirtualMinute',
      type: IsarType.long,
    ),
    r'title': PropertySchema(
      id: 25,
      name: r'title',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 26,
      name: r'type',
      type: IsarType.byte,
      enumMap: _TaskModeltypeEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 27,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'vibrateMode': PropertySchema(
      id: 28,
      name: r'vibrateMode',
      type: IsarType.bool,
    )
  },
  estimateSize: _taskModelEstimateSize,
  serialize: _taskModelSerialize,
  deserialize: _taskModelDeserialize,
  deserializeProp: _taskModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'syncId': IndexSchema(
      id: 7538593479801827566,
      name: r'syncId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'syncId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'targetDate': IndexSchema(
      id: 5284734288444860006,
      name: r'targetDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'targetDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'targetPeriodId': IndexSchema(
      id: 9019153179978968532,
      name: r'targetPeriodId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'targetPeriodId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'lastCompletedDate': IndexSchema(
      id: -1833952703705479070,
      name: r'lastCompletedDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastCompletedDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _taskModelGetId,
  getLinks: _taskModelGetLinks,
  attach: _taskModelAttach,
  version: '3.3.2',
);

int _taskModelEstimateSize(
  TaskModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.alarmTone.length * 3;
  bytesCount += 3 + object.completionHistory.length * 8;
  {
    final value = object.dialShortName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.recurrenceDays;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  bytesCount += 3 + object.syncId.length * 3;
  bytesCount += 3 + object.targetSuwayas.length * 8;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _taskModelSerialize(
  TaskModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.alarmMode);
  writer.writeString(offsets[1], object.alarmTone);
  writer.writeDouble(offsets[2], object.alarmVolume);
  writer.writeByte(offsets[3], object.category.index);
  writer.writeDateTime(offsets[4], object.completedAt);
  writer.writeDateTimeList(offsets[5], object.completionHistory);
  writer.writeDateTime(offsets[6], object.createdAt);
  writer.writeLong(offsets[7], object.currentStreak);
  writer.writeString(offsets[8], object.dialShortName);
  writer.writeBool(offsets[9], object.isAstroTime);
  writer.writeBool(offsets[10], object.isCompleted);
  writer.writeBool(offsets[11], object.isDeleted);
  writer.writeBool(offsets[12], object.isSynced);
  writer.writeDateTime(offsets[13], object.lastCompletedDate);
  writer.writeLong(offsets[14], object.longestStreak);
  writer.writeLong(offsets[15], object.migrationCount);
  writer.writeBool(offsets[16], object.notifyMode);
  writer.writeLongList(offsets[17], object.recurrenceDays);
  writer.writeBool(offsets[18], object.showOnDial);
  writer.writeString(offsets[19], object.syncId);
  writer.writeLong(offsets[20], object.targetCivilTimeMinutes);
  writer.writeDateTime(offsets[21], object.targetDate);
  writer.writeLong(offsets[22], object.targetPeriodId);
  writer.writeLongList(offsets[23], object.targetSuwayas);
  writer.writeLong(offsets[24], object.targetVirtualMinute);
  writer.writeString(offsets[25], object.title);
  writer.writeByte(offsets[26], object.type.index);
  writer.writeDateTime(offsets[27], object.updatedAt);
  writer.writeBool(offsets[28], object.vibrateMode);
}

TaskModel _taskModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TaskModel();
  object.alarmMode = reader.readBool(offsets[0]);
  object.alarmTone = reader.readString(offsets[1]);
  object.alarmVolume = reader.readDouble(offsets[2]);
  object.category =
      _TaskModelcategoryValueEnumMap[reader.readByteOrNull(offsets[3])] ??
          TaskCategory.unspecified;
  object.completedAt = reader.readDateTimeOrNull(offsets[4]);
  object.completionHistory = reader.readDateTimeList(offsets[5]) ?? [];
  object.createdAt = reader.readDateTime(offsets[6]);
  object.currentStreak = reader.readLong(offsets[7]);
  object.dialShortName = reader.readStringOrNull(offsets[8]);
  object.id = id;
  object.isAstroTime = reader.readBool(offsets[9]);
  object.isCompleted = reader.readBool(offsets[10]);
  object.isDeleted = reader.readBool(offsets[11]);
  object.isSynced = reader.readBool(offsets[12]);
  object.lastCompletedDate = reader.readDateTimeOrNull(offsets[13]);
  object.longestStreak = reader.readLong(offsets[14]);
  object.migrationCount = reader.readLong(offsets[15]);
  object.notifyMode = reader.readBool(offsets[16]);
  object.recurrenceDays = reader.readLongList(offsets[17]);
  object.showOnDial = reader.readBool(offsets[18]);
  object.syncId = reader.readString(offsets[19]);
  object.targetCivilTimeMinutes = reader.readLongOrNull(offsets[20]);
  object.targetDate = reader.readDateTimeOrNull(offsets[21]);
  object.targetPeriodId = reader.readLongOrNull(offsets[22]);
  object.targetSuwayas = reader.readLongList(offsets[23]) ?? [];
  object.targetVirtualMinute = reader.readLong(offsets[24]);
  object.title = reader.readString(offsets[25]);
  object.type =
      _TaskModeltypeValueEnumMap[reader.readByteOrNull(offsets[26])] ??
          TaskType.casual;
  object.updatedAt = reader.readDateTime(offsets[27]);
  object.vibrateMode = reader.readBool(offsets[28]);
  return object;
}

P _taskModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (_TaskModelcategoryValueEnumMap[reader.readByteOrNull(offset)] ??
          TaskCategory.unspecified) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeList(offset) ?? []) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readBool(offset)) as P;
    case 17:
      return (reader.readLongList(offset)) as P;
    case 18:
      return (reader.readBool(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    case 20:
      return (reader.readLongOrNull(offset)) as P;
    case 21:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 22:
      return (reader.readLongOrNull(offset)) as P;
    case 23:
      return (reader.readLongList(offset) ?? []) as P;
    case 24:
      return (reader.readLong(offset)) as P;
    case 25:
      return (reader.readString(offset)) as P;
    case 26:
      return (_TaskModeltypeValueEnumMap[reader.readByteOrNull(offset)] ??
          TaskType.casual) as P;
    case 27:
      return (reader.readDateTime(offset)) as P;
    case 28:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TaskModelcategoryEnumValueMap = {
  'unspecified': 0,
  'work': 1,
  'study': 2,
  'sport': 3,
  'entertainment': 4,
  'worship': 5,
  'personal': 6,
  'social': 7,
};
const _TaskModelcategoryValueEnumMap = {
  0: TaskCategory.unspecified,
  1: TaskCategory.work,
  2: TaskCategory.study,
  3: TaskCategory.sport,
  4: TaskCategory.entertainment,
  5: TaskCategory.worship,
  6: TaskCategory.personal,
  7: TaskCategory.social,
};
const _TaskModeltypeEnumValueMap = {
  'casual': 0,
  'permanent': 1,
};
const _TaskModeltypeValueEnumMap = {
  0: TaskType.casual,
  1: TaskType.permanent,
};

Id _taskModelGetId(TaskModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _taskModelGetLinks(TaskModel object) {
  return [];
}

void _taskModelAttach(IsarCollection<dynamic> col, Id id, TaskModel object) {
  object.id = id;
}

extension TaskModelByIndex on IsarCollection<TaskModel> {
  Future<TaskModel?> getBySyncId(String syncId) {
    return getByIndex(r'syncId', [syncId]);
  }

  TaskModel? getBySyncIdSync(String syncId) {
    return getByIndexSync(r'syncId', [syncId]);
  }

  Future<bool> deleteBySyncId(String syncId) {
    return deleteByIndex(r'syncId', [syncId]);
  }

  bool deleteBySyncIdSync(String syncId) {
    return deleteByIndexSync(r'syncId', [syncId]);
  }

  Future<List<TaskModel?>> getAllBySyncId(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'syncId', values);
  }

  List<TaskModel?> getAllBySyncIdSync(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'syncId', values);
  }

  Future<int> deleteAllBySyncId(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'syncId', values);
  }

  int deleteAllBySyncIdSync(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'syncId', values);
  }

  Future<Id> putBySyncId(TaskModel object) {
    return putByIndex(r'syncId', object);
  }

  Id putBySyncIdSync(TaskModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'syncId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySyncId(List<TaskModel> objects) {
    return putAllByIndex(r'syncId', objects);
  }

  List<Id> putAllBySyncIdSync(List<TaskModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'syncId', objects, saveLinks: saveLinks);
  }
}

extension TaskModelQueryWhereSort
    on QueryBuilder<TaskModel, TaskModel, QWhere> {
  QueryBuilder<TaskModel, TaskModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhere> anyTargetDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'targetDate'),
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhere> anyTargetPeriodId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'targetPeriodId'),
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhere> anyLastCompletedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastCompletedDate'),
      );
    });
  }
}

extension TaskModelQueryWhere
    on QueryBuilder<TaskModel, TaskModel, QWhereClause> {
  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> syncIdEqualTo(
      String syncId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'syncId',
        value: [syncId],
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> syncIdNotEqualTo(
      String syncId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncId',
              lower: [],
              upper: [syncId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncId',
              lower: [syncId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncId',
              lower: [syncId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncId',
              lower: [],
              upper: [syncId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> targetDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'targetDate',
        value: [null],
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> targetDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'targetDate',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> targetDateEqualTo(
      DateTime? targetDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'targetDate',
        value: [targetDate],
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> targetDateNotEqualTo(
      DateTime? targetDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'targetDate',
              lower: [],
              upper: [targetDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'targetDate',
              lower: [targetDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'targetDate',
              lower: [targetDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'targetDate',
              lower: [],
              upper: [targetDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> targetDateGreaterThan(
    DateTime? targetDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'targetDate',
        lower: [targetDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> targetDateLessThan(
    DateTime? targetDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'targetDate',
        lower: [],
        upper: [targetDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> targetDateBetween(
    DateTime? lowerTargetDate,
    DateTime? upperTargetDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'targetDate',
        lower: [lowerTargetDate],
        includeLower: includeLower,
        upper: [upperTargetDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> targetPeriodIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'targetPeriodId',
        value: [null],
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause>
      targetPeriodIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'targetPeriodId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> targetPeriodIdEqualTo(
      int? targetPeriodId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'targetPeriodId',
        value: [targetPeriodId],
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause>
      targetPeriodIdNotEqualTo(int? targetPeriodId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'targetPeriodId',
              lower: [],
              upper: [targetPeriodId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'targetPeriodId',
              lower: [targetPeriodId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'targetPeriodId',
              lower: [targetPeriodId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'targetPeriodId',
              lower: [],
              upper: [targetPeriodId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause>
      targetPeriodIdGreaterThan(
    int? targetPeriodId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'targetPeriodId',
        lower: [targetPeriodId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> targetPeriodIdLessThan(
    int? targetPeriodId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'targetPeriodId',
        lower: [],
        upper: [targetPeriodId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause> targetPeriodIdBetween(
    int? lowerTargetPeriodId,
    int? upperTargetPeriodId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'targetPeriodId',
        lower: [lowerTargetPeriodId],
        includeLower: includeLower,
        upper: [upperTargetPeriodId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause>
      lastCompletedDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastCompletedDate',
        value: [null],
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause>
      lastCompletedDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastCompletedDate',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause>
      lastCompletedDateEqualTo(DateTime? lastCompletedDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastCompletedDate',
        value: [lastCompletedDate],
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause>
      lastCompletedDateNotEqualTo(DateTime? lastCompletedDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastCompletedDate',
              lower: [],
              upper: [lastCompletedDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastCompletedDate',
              lower: [lastCompletedDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastCompletedDate',
              lower: [lastCompletedDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastCompletedDate',
              lower: [],
              upper: [lastCompletedDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause>
      lastCompletedDateGreaterThan(
    DateTime? lastCompletedDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastCompletedDate',
        lower: [lastCompletedDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause>
      lastCompletedDateLessThan(
    DateTime? lastCompletedDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastCompletedDate',
        lower: [],
        upper: [lastCompletedDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterWhereClause>
      lastCompletedDateBetween(
    DateTime? lowerLastCompletedDate,
    DateTime? upperLastCompletedDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastCompletedDate',
        lower: [lowerLastCompletedDate],
        includeLower: includeLower,
        upper: [upperLastCompletedDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TaskModelQueryFilter
    on QueryBuilder<TaskModel, TaskModel, QFilterCondition> {
  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> alarmModeEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'alarmMode',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> alarmToneEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'alarmTone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      alarmToneGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'alarmTone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> alarmToneLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'alarmTone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> alarmToneBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'alarmTone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> alarmToneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'alarmTone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> alarmToneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'alarmTone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> alarmToneContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'alarmTone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> alarmToneMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'alarmTone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> alarmToneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'alarmTone',
        value: '',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      alarmToneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'alarmTone',
        value: '',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> alarmVolumeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'alarmVolume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      alarmVolumeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'alarmVolume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> alarmVolumeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'alarmVolume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> alarmVolumeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'alarmVolume',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> categoryEqualTo(
      TaskCategory value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> categoryGreaterThan(
    TaskCategory value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> categoryLessThan(
    TaskCategory value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> categoryBetween(
    TaskCategory lower,
    TaskCategory upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      completedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      completedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> completedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      completedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> completedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> completedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      completionHistoryElementEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completionHistory',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      completionHistoryElementGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completionHistory',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      completionHistoryElementLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completionHistory',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      completionHistoryElementBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completionHistory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      completionHistoryLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completionHistory',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      completionHistoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completionHistory',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      completionHistoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completionHistory',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      completionHistoryLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completionHistory',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      completionHistoryLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completionHistory',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      completionHistoryLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completionHistory',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      currentStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      currentStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      currentStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      currentStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      dialShortNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dialShortName',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      dialShortNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dialShortName',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      dialShortNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dialShortName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      dialShortNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dialShortName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      dialShortNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dialShortName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      dialShortNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dialShortName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      dialShortNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dialShortName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      dialShortNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dialShortName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      dialShortNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dialShortName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      dialShortNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dialShortName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      dialShortNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dialShortName',
        value: '',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      dialShortNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dialShortName',
        value: '',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> isAstroTimeEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isAstroTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> isCompletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> isDeletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> isSyncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      lastCompletedDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastCompletedDate',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      lastCompletedDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastCompletedDate',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      lastCompletedDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastCompletedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      lastCompletedDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastCompletedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      lastCompletedDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastCompletedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      lastCompletedDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastCompletedDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      longestStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      longestStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      longestStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      longestStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longestStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      migrationCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'migrationCount',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      migrationCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'migrationCount',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      migrationCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'migrationCount',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      migrationCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'migrationCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> notifyModeEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notifyMode',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      recurrenceDaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recurrenceDays',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      recurrenceDaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recurrenceDays',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      recurrenceDaysElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recurrenceDays',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      recurrenceDaysElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recurrenceDays',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      recurrenceDaysElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recurrenceDays',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      recurrenceDaysElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recurrenceDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      recurrenceDaysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'recurrenceDays',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      recurrenceDaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'recurrenceDays',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      recurrenceDaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'recurrenceDays',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      recurrenceDaysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'recurrenceDays',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      recurrenceDaysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'recurrenceDays',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      recurrenceDaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'recurrenceDays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> showOnDialEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'showOnDial',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> syncIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> syncIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> syncIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> syncIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> syncIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> syncIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> syncIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> syncIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> syncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncId',
        value: '',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> syncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncId',
        value: '',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetCivilTimeMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'targetCivilTimeMinutes',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetCivilTimeMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'targetCivilTimeMinutes',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetCivilTimeMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetCivilTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetCivilTimeMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetCivilTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetCivilTimeMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetCivilTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetCivilTimeMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetCivilTimeMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> targetDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'targetDate',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'targetDate',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> targetDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetDate',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetDate',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> targetDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetDate',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> targetDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetPeriodIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'targetPeriodId',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetPeriodIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'targetPeriodId',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetPeriodIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetPeriodId',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetPeriodIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetPeriodId',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetPeriodIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetPeriodId',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetPeriodIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetPeriodId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetSuwayasElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetSuwayas',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetSuwayasElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetSuwayas',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetSuwayasElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetSuwayas',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetSuwayasElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetSuwayas',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetSuwayasLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetSuwayas',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetSuwayasIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetSuwayas',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetSuwayasIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetSuwayas',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetSuwayasLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetSuwayas',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetSuwayasLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetSuwayas',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetSuwayasLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetSuwayas',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetVirtualMinuteEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetVirtualMinute',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetVirtualMinuteGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetVirtualMinute',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetVirtualMinuteLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetVirtualMinute',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      targetVirtualMinuteBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetVirtualMinute',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> typeEqualTo(
      TaskType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> typeGreaterThan(
    TaskType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> typeLessThan(
    TaskType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> typeBetween(
    TaskType lower,
    TaskType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterFilterCondition> vibrateModeEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vibrateMode',
        value: value,
      ));
    });
  }
}

extension TaskModelQueryObject
    on QueryBuilder<TaskModel, TaskModel, QFilterCondition> {}

extension TaskModelQueryLinks
    on QueryBuilder<TaskModel, TaskModel, QFilterCondition> {}

extension TaskModelQuerySortBy on QueryBuilder<TaskModel, TaskModel, QSortBy> {
  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByAlarmMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmMode', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByAlarmModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmMode', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByAlarmTone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmTone', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByAlarmToneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmTone', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByAlarmVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmVolume', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByAlarmVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmVolume', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByDialShortName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dialShortName', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByDialShortNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dialShortName', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByIsAstroTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAstroTime', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByIsAstroTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAstroTime', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByLastCompletedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCompletedDate', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy>
      sortByLastCompletedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCompletedDate', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByMigrationCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'migrationCount', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByMigrationCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'migrationCount', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByNotifyMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifyMode', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByNotifyModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifyMode', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByShowOnDial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnDial', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByShowOnDialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnDial', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy>
      sortByTargetCivilTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetCivilTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy>
      sortByTargetCivilTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetCivilTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByTargetDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetDate', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByTargetDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetDate', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByTargetPeriodId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetPeriodId', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByTargetPeriodIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetPeriodId', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByTargetVirtualMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetVirtualMinute', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy>
      sortByTargetVirtualMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetVirtualMinute', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByVibrateMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vibrateMode', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> sortByVibrateModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vibrateMode', Sort.desc);
    });
  }
}

extension TaskModelQuerySortThenBy
    on QueryBuilder<TaskModel, TaskModel, QSortThenBy> {
  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByAlarmMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmMode', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByAlarmModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmMode', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByAlarmTone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmTone', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByAlarmToneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmTone', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByAlarmVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmVolume', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByAlarmVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmVolume', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByDialShortName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dialShortName', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByDialShortNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dialShortName', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByIsAstroTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAstroTime', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByIsAstroTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAstroTime', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByLastCompletedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCompletedDate', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy>
      thenByLastCompletedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCompletedDate', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByMigrationCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'migrationCount', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByMigrationCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'migrationCount', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByNotifyMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifyMode', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByNotifyModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifyMode', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByShowOnDial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnDial', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByShowOnDialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnDial', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy>
      thenByTargetCivilTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetCivilTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy>
      thenByTargetCivilTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetCivilTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByTargetDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetDate', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByTargetDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetDate', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByTargetPeriodId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetPeriodId', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByTargetPeriodIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetPeriodId', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByTargetVirtualMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetVirtualMinute', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy>
      thenByTargetVirtualMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetVirtualMinute', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByVibrateMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vibrateMode', Sort.asc);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QAfterSortBy> thenByVibrateModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vibrateMode', Sort.desc);
    });
  }
}

extension TaskModelQueryWhereDistinct
    on QueryBuilder<TaskModel, TaskModel, QDistinct> {
  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByAlarmMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'alarmMode');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByAlarmTone(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'alarmTone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByAlarmVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'alarmVolume');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByCompletionHistory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completionHistory');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentStreak');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByDialShortName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dialShortName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByIsAstroTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAstroTime');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCompleted');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByLastCompletedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastCompletedDate');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longestStreak');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByMigrationCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'migrationCount');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByNotifyMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notifyMode');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByRecurrenceDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recurrenceDays');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByShowOnDial() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'showOnDial');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctBySyncId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct>
      distinctByTargetCivilTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetCivilTimeMinutes');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByTargetDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetDate');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByTargetPeriodId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetPeriodId');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByTargetSuwayas() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetSuwayas');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct>
      distinctByTargetVirtualMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetVirtualMinute');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<TaskModel, TaskModel, QDistinct> distinctByVibrateMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vibrateMode');
    });
  }
}

extension TaskModelQueryProperty
    on QueryBuilder<TaskModel, TaskModel, QQueryProperty> {
  QueryBuilder<TaskModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TaskModel, bool, QQueryOperations> alarmModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'alarmMode');
    });
  }

  QueryBuilder<TaskModel, String, QQueryOperations> alarmToneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'alarmTone');
    });
  }

  QueryBuilder<TaskModel, double, QQueryOperations> alarmVolumeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'alarmVolume');
    });
  }

  QueryBuilder<TaskModel, TaskCategory, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<TaskModel, DateTime?, QQueryOperations> completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<TaskModel, List<DateTime>, QQueryOperations>
      completionHistoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completionHistory');
    });
  }

  QueryBuilder<TaskModel, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<TaskModel, int, QQueryOperations> currentStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentStreak');
    });
  }

  QueryBuilder<TaskModel, String?, QQueryOperations> dialShortNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dialShortName');
    });
  }

  QueryBuilder<TaskModel, bool, QQueryOperations> isAstroTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAstroTime');
    });
  }

  QueryBuilder<TaskModel, bool, QQueryOperations> isCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCompleted');
    });
  }

  QueryBuilder<TaskModel, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<TaskModel, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<TaskModel, DateTime?, QQueryOperations>
      lastCompletedDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastCompletedDate');
    });
  }

  QueryBuilder<TaskModel, int, QQueryOperations> longestStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longestStreak');
    });
  }

  QueryBuilder<TaskModel, int, QQueryOperations> migrationCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'migrationCount');
    });
  }

  QueryBuilder<TaskModel, bool, QQueryOperations> notifyModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notifyMode');
    });
  }

  QueryBuilder<TaskModel, List<int>?, QQueryOperations>
      recurrenceDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recurrenceDays');
    });
  }

  QueryBuilder<TaskModel, bool, QQueryOperations> showOnDialProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'showOnDial');
    });
  }

  QueryBuilder<TaskModel, String, QQueryOperations> syncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncId');
    });
  }

  QueryBuilder<TaskModel, int?, QQueryOperations>
      targetCivilTimeMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetCivilTimeMinutes');
    });
  }

  QueryBuilder<TaskModel, DateTime?, QQueryOperations> targetDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetDate');
    });
  }

  QueryBuilder<TaskModel, int?, QQueryOperations> targetPeriodIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetPeriodId');
    });
  }

  QueryBuilder<TaskModel, List<int>, QQueryOperations> targetSuwayasProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetSuwayas');
    });
  }

  QueryBuilder<TaskModel, int, QQueryOperations> targetVirtualMinuteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetVirtualMinute');
    });
  }

  QueryBuilder<TaskModel, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<TaskModel, TaskType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<TaskModel, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<TaskModel, bool, QQueryOperations> vibrateModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vibrateMode');
    });
  }
}
