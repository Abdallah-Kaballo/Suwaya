// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRoutineModelCollection on Isar {
  IsarCollection<RoutineModel> get routineModels => this.collection();
}

const RoutineModelSchema = CollectionSchema(
  name: r'RoutineModel',
  id: -1626869750065799181,
  properties: {
    r'alarmTone': PropertySchema(
      id: 0,
      name: r'alarmTone',
      type: IsarType.string,
    ),
    r'alarmVolume': PropertySchema(
      id: 1,
      name: r'alarmVolume',
      type: IsarType.double,
    ),
    r'alertLevel': PropertySchema(
      id: 2,
      name: r'alertLevel',
      type: IsarType.long,
    ),
    r'colorValue': PropertySchema(
      id: 3,
      name: r'colorValue',
      type: IsarType.long,
    ),
    r'endPeriodId': PropertySchema(
      id: 4,
      name: r'endPeriodId',
      type: IsarType.long,
    ),
    r'endSuwaya': PropertySchema(
      id: 5,
      name: r'endSuwaya',
      type: IsarType.long,
    ),
    r'endTimeMinutes': PropertySchema(
      id: 6,
      name: r'endTimeMinutes',
      type: IsarType.long,
    ),
    r'endVirtualMinute': PropertySchema(
      id: 7,
      name: r'endVirtualMinute',
      type: IsarType.long,
    ),
    r'isActive': PropertySchema(
      id: 8,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'isAstroTime': PropertySchema(
      id: 9,
      name: r'isAstroTime',
      type: IsarType.bool,
    ),
    r'isDeleted': PropertySchema(
      id: 10,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 11,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'pattern': PropertySchema(
      id: 12,
      name: r'pattern',
      type: IsarType.string,
    ),
    r'recurrenceDays': PropertySchema(
      id: 13,
      name: r'recurrenceDays',
      type: IsarType.longList,
    ),
    r'startPeriodId': PropertySchema(
      id: 14,
      name: r'startPeriodId',
      type: IsarType.long,
    ),
    r'startSuwaya': PropertySchema(
      id: 15,
      name: r'startSuwaya',
      type: IsarType.long,
    ),
    r'startTimeMinutes': PropertySchema(
      id: 16,
      name: r'startTimeMinutes',
      type: IsarType.long,
    ),
    r'startVirtualMinute': PropertySchema(
      id: 17,
      name: r'startVirtualMinute',
      type: IsarType.long,
    ),
    r'syncId': PropertySchema(
      id: 18,
      name: r'syncId',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 19,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 20,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _routineModelEstimateSize,
  serialize: _routineModelSerialize,
  deserialize: _routineModelDeserialize,
  deserializeProp: _routineModelDeserializeProp,
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
    r'isActive': IndexSchema(
      id: 8092228061260947457,
      name: r'isActive',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isActive',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _routineModelGetId,
  getLinks: _routineModelGetLinks,
  attach: _routineModelAttach,
  version: '3.3.2',
);

int _routineModelEstimateSize(
  RoutineModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.alarmTone.length * 3;
  bytesCount += 3 + object.pattern.length * 3;
  {
    final value = object.recurrenceDays;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  bytesCount += 3 + object.syncId.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _routineModelSerialize(
  RoutineModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.alarmTone);
  writer.writeDouble(offsets[1], object.alarmVolume);
  writer.writeLong(offsets[2], object.alertLevel);
  writer.writeLong(offsets[3], object.colorValue);
  writer.writeLong(offsets[4], object.endPeriodId);
  writer.writeLong(offsets[5], object.endSuwaya);
  writer.writeLong(offsets[6], object.endTimeMinutes);
  writer.writeLong(offsets[7], object.endVirtualMinute);
  writer.writeBool(offsets[8], object.isActive);
  writer.writeBool(offsets[9], object.isAstroTime);
  writer.writeBool(offsets[10], object.isDeleted);
  writer.writeBool(offsets[11], object.isSynced);
  writer.writeString(offsets[12], object.pattern);
  writer.writeLongList(offsets[13], object.recurrenceDays);
  writer.writeLong(offsets[14], object.startPeriodId);
  writer.writeLong(offsets[15], object.startSuwaya);
  writer.writeLong(offsets[16], object.startTimeMinutes);
  writer.writeLong(offsets[17], object.startVirtualMinute);
  writer.writeString(offsets[18], object.syncId);
  writer.writeString(offsets[19], object.title);
  writer.writeDateTime(offsets[20], object.updatedAt);
}

RoutineModel _routineModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RoutineModel();
  object.alarmTone = reader.readString(offsets[0]);
  object.alarmVolume = reader.readDouble(offsets[1]);
  object.alertLevel = reader.readLong(offsets[2]);
  object.colorValue = reader.readLong(offsets[3]);
  object.endPeriodId = reader.readLongOrNull(offsets[4]);
  object.endSuwaya = reader.readLongOrNull(offsets[5]);
  object.endTimeMinutes = reader.readLongOrNull(offsets[6]);
  object.endVirtualMinute = reader.readLongOrNull(offsets[7]);
  object.id = id;
  object.isActive = reader.readBool(offsets[8]);
  object.isAstroTime = reader.readBool(offsets[9]);
  object.isDeleted = reader.readBool(offsets[10]);
  object.isSynced = reader.readBool(offsets[11]);
  object.pattern = reader.readString(offsets[12]);
  object.recurrenceDays = reader.readLongList(offsets[13]);
  object.startPeriodId = reader.readLongOrNull(offsets[14]);
  object.startSuwaya = reader.readLongOrNull(offsets[15]);
  object.startTimeMinutes = reader.readLongOrNull(offsets[16]);
  object.startVirtualMinute = reader.readLongOrNull(offsets[17]);
  object.syncId = reader.readString(offsets[18]);
  object.title = reader.readString(offsets[19]);
  object.updatedAt = reader.readDateTime(offsets[20]);
  return object;
}

P _routineModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readLongList(offset)) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    case 15:
      return (reader.readLongOrNull(offset)) as P;
    case 16:
      return (reader.readLongOrNull(offset)) as P;
    case 17:
      return (reader.readLongOrNull(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    case 20:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _routineModelGetId(RoutineModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _routineModelGetLinks(RoutineModel object) {
  return [];
}

void _routineModelAttach(
    IsarCollection<dynamic> col, Id id, RoutineModel object) {
  object.id = id;
}

extension RoutineModelByIndex on IsarCollection<RoutineModel> {
  Future<RoutineModel?> getBySyncId(String syncId) {
    return getByIndex(r'syncId', [syncId]);
  }

  RoutineModel? getBySyncIdSync(String syncId) {
    return getByIndexSync(r'syncId', [syncId]);
  }

  Future<bool> deleteBySyncId(String syncId) {
    return deleteByIndex(r'syncId', [syncId]);
  }

  bool deleteBySyncIdSync(String syncId) {
    return deleteByIndexSync(r'syncId', [syncId]);
  }

  Future<List<RoutineModel?>> getAllBySyncId(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'syncId', values);
  }

  List<RoutineModel?> getAllBySyncIdSync(List<String> syncIdValues) {
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

  Future<Id> putBySyncId(RoutineModel object) {
    return putByIndex(r'syncId', object);
  }

  Id putBySyncIdSync(RoutineModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'syncId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySyncId(List<RoutineModel> objects) {
    return putAllByIndex(r'syncId', objects);
  }

  List<Id> putAllBySyncIdSync(List<RoutineModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'syncId', objects, saveLinks: saveLinks);
  }
}

extension RoutineModelQueryWhereSort
    on QueryBuilder<RoutineModel, RoutineModel, QWhere> {
  QueryBuilder<RoutineModel, RoutineModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterWhere> anyIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isActive'),
      );
    });
  }
}

extension RoutineModelQueryWhere
    on QueryBuilder<RoutineModel, RoutineModel, QWhereClause> {
  QueryBuilder<RoutineModel, RoutineModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterWhereClause> syncIdEqualTo(
      String syncId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'syncId',
        value: [syncId],
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterWhereClause> syncIdNotEqualTo(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterWhereClause> isActiveEqualTo(
      bool isActive) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isActive',
        value: [isActive],
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterWhereClause>
      isActiveNotEqualTo(bool isActive) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [],
              upper: [isActive],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [isActive],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [isActive],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [],
              upper: [isActive],
              includeUpper: false,
            ));
      }
    });
  }
}

extension RoutineModelQueryFilter
    on QueryBuilder<RoutineModel, RoutineModel, QFilterCondition> {
  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alarmToneEqualTo(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alarmToneLessThan(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alarmToneBetween(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alarmToneStartsWith(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alarmToneEndsWith(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alarmToneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'alarmTone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alarmToneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'alarmTone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alarmToneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'alarmTone',
        value: '',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alarmToneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'alarmTone',
        value: '',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alarmVolumeEqualTo(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alarmVolumeLessThan(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alarmVolumeBetween(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alertLevelEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'alertLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alertLevelGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'alertLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alertLevelLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'alertLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      alertLevelBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'alertLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      colorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      colorValueGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      colorValueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      colorValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endPeriodIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endPeriodId',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endPeriodIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endPeriodId',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endPeriodIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endPeriodId',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endPeriodIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endPeriodId',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endPeriodIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endPeriodId',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endPeriodIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endPeriodId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endSuwayaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endSuwaya',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endSuwayaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endSuwaya',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endSuwayaEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endSuwaya',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endSuwayaGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endSuwaya',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endSuwayaLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endSuwaya',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endSuwayaBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endSuwaya',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endTimeMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endTimeMinutes',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endTimeMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endTimeMinutes',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endTimeMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endTimeMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endTimeMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endTimeMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTimeMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endVirtualMinuteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endVirtualMinute',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endVirtualMinuteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endVirtualMinute',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endVirtualMinuteEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endVirtualMinute',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endVirtualMinuteGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endVirtualMinute',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endVirtualMinuteLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endVirtualMinute',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      endVirtualMinuteBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endVirtualMinute',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      isAstroTimeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isAstroTime',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      patternEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      patternGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      patternLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      patternBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pattern',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      patternStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      patternEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      patternContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      patternMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pattern',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      patternIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pattern',
        value: '',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      patternIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pattern',
        value: '',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      recurrenceDaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recurrenceDays',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      recurrenceDaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recurrenceDays',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      recurrenceDaysElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recurrenceDays',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startPeriodIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startPeriodId',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startPeriodIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startPeriodId',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startPeriodIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startPeriodId',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startPeriodIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startPeriodId',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startPeriodIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startPeriodId',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startPeriodIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startPeriodId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startSuwayaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startSuwaya',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startSuwayaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startSuwaya',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startSuwayaEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startSuwaya',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startSuwayaGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startSuwaya',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startSuwayaLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startSuwaya',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startSuwayaBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startSuwaya',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startTimeMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startTimeMinutes',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startTimeMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startTimeMinutes',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startTimeMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startTimeMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startTimeMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startTimeMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTimeMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startVirtualMinuteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startVirtualMinute',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startVirtualMinuteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startVirtualMinute',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startVirtualMinuteEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startVirtualMinute',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startVirtualMinuteGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startVirtualMinute',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startVirtualMinuteLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startVirtualMinute',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      startVirtualMinuteBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startVirtualMinute',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition> syncIdEqualTo(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      syncIdGreaterThan(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      syncIdLessThan(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition> syncIdBetween(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      syncIdStartsWith(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      syncIdEndsWith(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      syncIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition> syncIdMatches(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      syncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncId',
        value: '',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      syncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncId',
        value: '',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition> titleEqualTo(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      titleGreaterThan(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition> titleLessThan(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition> titleBetween(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      titleStartsWith(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition> titleEndsWith(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition> titleContains(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition> titleMatches(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      updatedAtLessThan(
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

  QueryBuilder<RoutineModel, RoutineModel, QAfterFilterCondition>
      updatedAtBetween(
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
}

extension RoutineModelQueryObject
    on QueryBuilder<RoutineModel, RoutineModel, QFilterCondition> {}

extension RoutineModelQueryLinks
    on QueryBuilder<RoutineModel, RoutineModel, QFilterCondition> {}

extension RoutineModelQuerySortBy
    on QueryBuilder<RoutineModel, RoutineModel, QSortBy> {
  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByAlarmTone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmTone', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByAlarmToneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmTone', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByAlarmVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmVolume', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByAlarmVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmVolume', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByAlertLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alertLevel', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByAlertLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alertLevel', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByEndPeriodId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endPeriodId', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByEndPeriodIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endPeriodId', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByEndSuwaya() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSuwaya', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByEndSuwayaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSuwaya', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByEndTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByEndTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByEndVirtualMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endVirtualMinute', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByEndVirtualMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endVirtualMinute', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByIsAstroTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAstroTime', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByIsAstroTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAstroTime', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByPattern() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pattern', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByPatternDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pattern', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByStartPeriodId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startPeriodId', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByStartPeriodIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startPeriodId', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByStartSuwaya() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSuwaya', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByStartSuwayaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSuwaya', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByStartTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByStartTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByStartVirtualMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startVirtualMinute', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      sortByStartVirtualMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startVirtualMinute', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension RoutineModelQuerySortThenBy
    on QueryBuilder<RoutineModel, RoutineModel, QSortThenBy> {
  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByAlarmTone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmTone', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByAlarmToneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmTone', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByAlarmVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmVolume', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByAlarmVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmVolume', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByAlertLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alertLevel', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByAlertLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alertLevel', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByEndPeriodId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endPeriodId', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByEndPeriodIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endPeriodId', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByEndSuwaya() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSuwaya', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByEndSuwayaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSuwaya', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByEndTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByEndTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByEndVirtualMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endVirtualMinute', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByEndVirtualMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endVirtualMinute', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByIsAstroTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAstroTime', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByIsAstroTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAstroTime', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByPattern() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pattern', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByPatternDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pattern', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByStartPeriodId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startPeriodId', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByStartPeriodIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startPeriodId', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByStartSuwaya() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSuwaya', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByStartSuwayaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSuwaya', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByStartTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByStartTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByStartVirtualMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startVirtualMinute', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy>
      thenByStartVirtualMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startVirtualMinute', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension RoutineModelQueryWhereDistinct
    on QueryBuilder<RoutineModel, RoutineModel, QDistinct> {
  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByAlarmTone(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'alarmTone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByAlarmVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'alarmVolume');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByAlertLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'alertLevel');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorValue');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByEndPeriodId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endPeriodId');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByEndSuwaya() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endSuwaya');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct>
      distinctByEndTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endTimeMinutes');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct>
      distinctByEndVirtualMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endVirtualMinute');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByIsAstroTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAstroTime');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByPattern(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pattern', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct>
      distinctByRecurrenceDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recurrenceDays');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct>
      distinctByStartPeriodId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startPeriodId');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByStartSuwaya() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startSuwaya');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct>
      distinctByStartTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startTimeMinutes');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct>
      distinctByStartVirtualMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startVirtualMinute');
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctBySyncId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RoutineModel, RoutineModel, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension RoutineModelQueryProperty
    on QueryBuilder<RoutineModel, RoutineModel, QQueryProperty> {
  QueryBuilder<RoutineModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RoutineModel, String, QQueryOperations> alarmToneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'alarmTone');
    });
  }

  QueryBuilder<RoutineModel, double, QQueryOperations> alarmVolumeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'alarmVolume');
    });
  }

  QueryBuilder<RoutineModel, int, QQueryOperations> alertLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'alertLevel');
    });
  }

  QueryBuilder<RoutineModel, int, QQueryOperations> colorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorValue');
    });
  }

  QueryBuilder<RoutineModel, int?, QQueryOperations> endPeriodIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endPeriodId');
    });
  }

  QueryBuilder<RoutineModel, int?, QQueryOperations> endSuwayaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endSuwaya');
    });
  }

  QueryBuilder<RoutineModel, int?, QQueryOperations> endTimeMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endTimeMinutes');
    });
  }

  QueryBuilder<RoutineModel, int?, QQueryOperations>
      endVirtualMinuteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endVirtualMinute');
    });
  }

  QueryBuilder<RoutineModel, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<RoutineModel, bool, QQueryOperations> isAstroTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAstroTime');
    });
  }

  QueryBuilder<RoutineModel, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<RoutineModel, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<RoutineModel, String, QQueryOperations> patternProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pattern');
    });
  }

  QueryBuilder<RoutineModel, List<int>?, QQueryOperations>
      recurrenceDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recurrenceDays');
    });
  }

  QueryBuilder<RoutineModel, int?, QQueryOperations> startPeriodIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startPeriodId');
    });
  }

  QueryBuilder<RoutineModel, int?, QQueryOperations> startSuwayaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startSuwaya');
    });
  }

  QueryBuilder<RoutineModel, int?, QQueryOperations>
      startTimeMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startTimeMinutes');
    });
  }

  QueryBuilder<RoutineModel, int?, QQueryOperations>
      startVirtualMinuteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startVirtualMinute');
    });
  }

  QueryBuilder<RoutineModel, String, QQueryOperations> syncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncId');
    });
  }

  QueryBuilder<RoutineModel, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<RoutineModel, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
