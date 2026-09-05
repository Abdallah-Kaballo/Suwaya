// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetActivityLogCollection on Isar {
  IsarCollection<ActivityLog> get activityLogs => this.collection();
}

const ActivityLogSchema = CollectionSchema(
  name: r'ActivityLog',
  id: -3240605868618876905,
  properties: {
    r'activeDayDate': PropertySchema(
      id: 0,
      name: r'activeDayDate',
      type: IsarType.string,
    ),
    r'category': PropertySchema(
      id: 1,
      name: r'category',
      type: IsarType.string,
    ),
    r'completedAtUtc': PropertySchema(
      id: 2,
      name: r'completedAtUtc',
      type: IsarType.dateTime,
    ),
    r'isDeleted': PropertySchema(
      id: 3,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 4,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'periodId': PropertySchema(
      id: 5,
      name: r'periodId',
      type: IsarType.long,
    ),
    r'routineSyncId': PropertySchema(
      id: 6,
      name: r'routineSyncId',
      type: IsarType.string,
    ),
    r'suwayasCount': PropertySchema(
      id: 7,
      name: r'suwayasCount',
      type: IsarType.long,
    ),
    r'syncId': PropertySchema(
      id: 8,
      name: r'syncId',
      type: IsarType.string,
    ),
    r'taskSyncId': PropertySchema(
      id: 9,
      name: r'taskSyncId',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 10,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _activityLogEstimateSize,
  serialize: _activityLogSerialize,
  deserialize: _activityLogDeserialize,
  deserializeProp: _activityLogDeserializeProp,
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
    r'activeDayDate': IndexSchema(
      id: 2643599721888116222,
      name: r'activeDayDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'activeDayDate',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _activityLogGetId,
  getLinks: _activityLogGetLinks,
  attach: _activityLogAttach,
  version: '3.3.2',
);

int _activityLogEstimateSize(
  ActivityLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.activeDayDate.length * 3;
  bytesCount += 3 + object.category.length * 3;
  {
    final value = object.routineSyncId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.syncId.length * 3;
  {
    final value = object.taskSyncId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _activityLogSerialize(
  ActivityLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.activeDayDate);
  writer.writeString(offsets[1], object.category);
  writer.writeDateTime(offsets[2], object.completedAtUtc);
  writer.writeBool(offsets[3], object.isDeleted);
  writer.writeBool(offsets[4], object.isSynced);
  writer.writeLong(offsets[5], object.periodId);
  writer.writeString(offsets[6], object.routineSyncId);
  writer.writeLong(offsets[7], object.suwayasCount);
  writer.writeString(offsets[8], object.syncId);
  writer.writeString(offsets[9], object.taskSyncId);
  writer.writeDateTime(offsets[10], object.updatedAt);
}

ActivityLog _activityLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ActivityLog();
  object.activeDayDate = reader.readString(offsets[0]);
  object.category = reader.readString(offsets[1]);
  object.completedAtUtc = reader.readDateTime(offsets[2]);
  object.id = id;
  object.isDeleted = reader.readBool(offsets[3]);
  object.isSynced = reader.readBool(offsets[4]);
  object.periodId = reader.readLongOrNull(offsets[5]);
  object.routineSyncId = reader.readStringOrNull(offsets[6]);
  object.suwayasCount = reader.readLong(offsets[7]);
  object.syncId = reader.readString(offsets[8]);
  object.taskSyncId = reader.readStringOrNull(offsets[9]);
  object.updatedAt = reader.readDateTime(offsets[10]);
  return object;
}

P _activityLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _activityLogGetId(ActivityLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _activityLogGetLinks(ActivityLog object) {
  return [];
}

void _activityLogAttach(
    IsarCollection<dynamic> col, Id id, ActivityLog object) {
  object.id = id;
}

extension ActivityLogByIndex on IsarCollection<ActivityLog> {
  Future<ActivityLog?> getBySyncId(String syncId) {
    return getByIndex(r'syncId', [syncId]);
  }

  ActivityLog? getBySyncIdSync(String syncId) {
    return getByIndexSync(r'syncId', [syncId]);
  }

  Future<bool> deleteBySyncId(String syncId) {
    return deleteByIndex(r'syncId', [syncId]);
  }

  bool deleteBySyncIdSync(String syncId) {
    return deleteByIndexSync(r'syncId', [syncId]);
  }

  Future<List<ActivityLog?>> getAllBySyncId(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'syncId', values);
  }

  List<ActivityLog?> getAllBySyncIdSync(List<String> syncIdValues) {
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

  Future<Id> putBySyncId(ActivityLog object) {
    return putByIndex(r'syncId', object);
  }

  Id putBySyncIdSync(ActivityLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'syncId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySyncId(List<ActivityLog> objects) {
    return putAllByIndex(r'syncId', objects);
  }

  List<Id> putAllBySyncIdSync(List<ActivityLog> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'syncId', objects, saveLinks: saveLinks);
  }
}

extension ActivityLogQueryWhereSort
    on QueryBuilder<ActivityLog, ActivityLog, QWhere> {
  QueryBuilder<ActivityLog, ActivityLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ActivityLogQueryWhere
    on QueryBuilder<ActivityLog, ActivityLog, QWhereClause> {
  QueryBuilder<ActivityLog, ActivityLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterWhereClause> idBetween(
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterWhereClause> syncIdEqualTo(
      String syncId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'syncId',
        value: [syncId],
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterWhereClause> syncIdNotEqualTo(
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterWhereClause>
      activeDayDateEqualTo(String activeDayDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'activeDayDate',
        value: [activeDayDate],
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterWhereClause>
      activeDayDateNotEqualTo(String activeDayDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'activeDayDate',
              lower: [],
              upper: [activeDayDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'activeDayDate',
              lower: [activeDayDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'activeDayDate',
              lower: [activeDayDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'activeDayDate',
              lower: [],
              upper: [activeDayDate],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ActivityLogQueryFilter
    on QueryBuilder<ActivityLog, ActivityLog, QFilterCondition> {
  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      activeDayDateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activeDayDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      activeDayDateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activeDayDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      activeDayDateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activeDayDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      activeDayDateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activeDayDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      activeDayDateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'activeDayDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      activeDayDateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'activeDayDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      activeDayDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'activeDayDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      activeDayDateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'activeDayDate',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      activeDayDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activeDayDate',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      activeDayDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'activeDayDate',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> categoryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      categoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      categoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> categoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> categoryMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      completedAtUtcEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedAtUtc',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      completedAtUtcGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedAtUtc',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      completedAtUtcLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedAtUtc',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      completedAtUtcBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedAtUtc',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> isSyncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      periodIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'periodId',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      periodIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'periodId',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> periodIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodId',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      periodIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodId',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      periodIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodId',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> periodIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      routineSyncIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'routineSyncId',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      routineSyncIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'routineSyncId',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      routineSyncIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'routineSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      routineSyncIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'routineSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      routineSyncIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'routineSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      routineSyncIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'routineSyncId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      routineSyncIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'routineSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      routineSyncIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'routineSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      routineSyncIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'routineSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      routineSyncIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'routineSyncId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      routineSyncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'routineSyncId',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      routineSyncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'routineSyncId',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      suwayasCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'suwayasCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      suwayasCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'suwayasCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      suwayasCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'suwayasCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      suwayasCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'suwayasCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> syncIdEqualTo(
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> syncIdLessThan(
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> syncIdBetween(
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> syncIdEndsWith(
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> syncIdContains(
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition> syncIdMatches(
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      syncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncId',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      syncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncId',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      taskSyncIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'taskSyncId',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      taskSyncIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'taskSyncId',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      taskSyncIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taskSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      taskSyncIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taskSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      taskSyncIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taskSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      taskSyncIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taskSyncId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      taskSyncIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'taskSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      taskSyncIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'taskSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      taskSyncIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'taskSyncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      taskSyncIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'taskSyncId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      taskSyncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taskSyncId',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      taskSyncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'taskSyncId',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
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

  QueryBuilder<ActivityLog, ActivityLog, QAfterFilterCondition>
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

extension ActivityLogQueryObject
    on QueryBuilder<ActivityLog, ActivityLog, QFilterCondition> {}

extension ActivityLogQueryLinks
    on QueryBuilder<ActivityLog, ActivityLog, QFilterCondition> {}

extension ActivityLogQuerySortBy
    on QueryBuilder<ActivityLog, ActivityLog, QSortBy> {
  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByActiveDayDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeDayDate', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy>
      sortByActiveDayDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeDayDate', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByCompletedAtUtc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAtUtc', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy>
      sortByCompletedAtUtcDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAtUtc', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByPeriodId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodId', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByPeriodIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodId', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByRoutineSyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routineSyncId', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy>
      sortByRoutineSyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routineSyncId', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortBySuwayasCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suwayasCount', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy>
      sortBySuwayasCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suwayasCount', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByTaskSyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskSyncId', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByTaskSyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskSyncId', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ActivityLogQuerySortThenBy
    on QueryBuilder<ActivityLog, ActivityLog, QSortThenBy> {
  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByActiveDayDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeDayDate', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy>
      thenByActiveDayDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeDayDate', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByCompletedAtUtc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAtUtc', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy>
      thenByCompletedAtUtcDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAtUtc', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByPeriodId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodId', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByPeriodIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodId', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByRoutineSyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routineSyncId', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy>
      thenByRoutineSyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routineSyncId', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenBySuwayasCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suwayasCount', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy>
      thenBySuwayasCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suwayasCount', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByTaskSyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskSyncId', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByTaskSyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskSyncId', Sort.desc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ActivityLogQueryWhereDistinct
    on QueryBuilder<ActivityLog, ActivityLog, QDistinct> {
  QueryBuilder<ActivityLog, ActivityLog, QDistinct> distinctByActiveDayDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activeDayDate',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QDistinct> distinctByCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QDistinct> distinctByCompletedAtUtc() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAtUtc');
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QDistinct> distinctByPeriodId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodId');
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QDistinct> distinctByRoutineSyncId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'routineSyncId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QDistinct> distinctBySuwayasCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'suwayasCount');
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QDistinct> distinctBySyncId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QDistinct> distinctByTaskSyncId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taskSyncId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActivityLog, ActivityLog, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension ActivityLogQueryProperty
    on QueryBuilder<ActivityLog, ActivityLog, QQueryProperty> {
  QueryBuilder<ActivityLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ActivityLog, String, QQueryOperations> activeDayDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activeDayDate');
    });
  }

  QueryBuilder<ActivityLog, String, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<ActivityLog, DateTime, QQueryOperations>
      completedAtUtcProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAtUtc');
    });
  }

  QueryBuilder<ActivityLog, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<ActivityLog, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<ActivityLog, int?, QQueryOperations> periodIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodId');
    });
  }

  QueryBuilder<ActivityLog, String?, QQueryOperations> routineSyncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'routineSyncId');
    });
  }

  QueryBuilder<ActivityLog, int, QQueryOperations> suwayasCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'suwayasCount');
    });
  }

  QueryBuilder<ActivityLog, String, QQueryOperations> syncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncId');
    });
  }

  QueryBuilder<ActivityLog, String?, QQueryOperations> taskSyncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taskSyncId');
    });
  }

  QueryBuilder<ActivityLog, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
