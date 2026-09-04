// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_stats_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyCosmicStatsCollection on Isar {
  IsarCollection<DailyCosmicStats> get dailyCosmicStats => this.collection();
}

const DailyCosmicStatsSchema = CollectionSchema(
  name: r'DailyCosmicStats',
  id: 2315421779543980064,
  properties: {
    r'asrCount': PropertySchema(
      id: 0,
      name: r'asrCount',
      type: IsarType.long,
    ),
    r'awradCount': PropertySchema(
      id: 1,
      name: r'awradCount',
      type: IsarType.long,
    ),
    r'dateString': PropertySchema(
      id: 2,
      name: r'dateString',
      type: IsarType.string,
    ),
    r'dhuhrCount': PropertySchema(
      id: 3,
      name: r'dhuhrCount',
      type: IsarType.long,
    ),
    r'duhaCount': PropertySchema(
      id: 4,
      name: r'duhaCount',
      type: IsarType.long,
    ),
    r'fajrCount': PropertySchema(
      id: 5,
      name: r'fajrCount',
      type: IsarType.long,
    ),
    r'ishaCount': PropertySchema(
      id: 6,
      name: r'ishaCount',
      type: IsarType.long,
    ),
    r'maashCount': PropertySchema(
      id: 7,
      name: r'maashCount',
      type: IsarType.long,
    ),
    r'maghribCount': PropertySchema(
      id: 8,
      name: r'maghribCount',
      type: IsarType.long,
    ),
    r'miadCount': PropertySchema(
      id: 9,
      name: r'miadCount',
      type: IsarType.long,
    ),
    r'qiyamCount': PropertySchema(
      id: 10,
      name: r'qiyamCount',
      type: IsarType.long,
    ),
    r'tarweehCount': PropertySchema(
      id: 11,
      name: r'tarweehCount',
      type: IsarType.long,
    ),
    r'totalCompleted': PropertySchema(
      id: 12,
      name: r'totalCompleted',
      type: IsarType.long,
    ),
    r'totalMigrated': PropertySchema(
      id: 13,
      name: r'totalMigrated',
      type: IsarType.long,
    )
  },
  estimateSize: _dailyCosmicStatsEstimateSize,
  serialize: _dailyCosmicStatsSerialize,
  deserialize: _dailyCosmicStatsDeserialize,
  deserializeProp: _dailyCosmicStatsDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateString': IndexSchema(
      id: 2390766547304188792,
      name: r'dateString',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'dateString',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dailyCosmicStatsGetId,
  getLinks: _dailyCosmicStatsGetLinks,
  attach: _dailyCosmicStatsAttach,
  version: '3.3.2',
);

int _dailyCosmicStatsEstimateSize(
  DailyCosmicStats object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateString.length * 3;
  return bytesCount;
}

void _dailyCosmicStatsSerialize(
  DailyCosmicStats object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.asrCount);
  writer.writeLong(offsets[1], object.awradCount);
  writer.writeString(offsets[2], object.dateString);
  writer.writeLong(offsets[3], object.dhuhrCount);
  writer.writeLong(offsets[4], object.duhaCount);
  writer.writeLong(offsets[5], object.fajrCount);
  writer.writeLong(offsets[6], object.ishaCount);
  writer.writeLong(offsets[7], object.maashCount);
  writer.writeLong(offsets[8], object.maghribCount);
  writer.writeLong(offsets[9], object.miadCount);
  writer.writeLong(offsets[10], object.qiyamCount);
  writer.writeLong(offsets[11], object.tarweehCount);
  writer.writeLong(offsets[12], object.totalCompleted);
  writer.writeLong(offsets[13], object.totalMigrated);
}

DailyCosmicStats _dailyCosmicStatsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyCosmicStats();
  object.asrCount = reader.readLong(offsets[0]);
  object.awradCount = reader.readLong(offsets[1]);
  object.dateString = reader.readString(offsets[2]);
  object.dhuhrCount = reader.readLong(offsets[3]);
  object.duhaCount = reader.readLong(offsets[4]);
  object.fajrCount = reader.readLong(offsets[5]);
  object.id = id;
  object.ishaCount = reader.readLong(offsets[6]);
  object.maashCount = reader.readLong(offsets[7]);
  object.maghribCount = reader.readLong(offsets[8]);
  object.miadCount = reader.readLong(offsets[9]);
  object.qiyamCount = reader.readLong(offsets[10]);
  object.tarweehCount = reader.readLong(offsets[11]);
  object.totalCompleted = reader.readLong(offsets[12]);
  object.totalMigrated = reader.readLong(offsets[13]);
  return object;
}

P _dailyCosmicStatsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyCosmicStatsGetId(DailyCosmicStats object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyCosmicStatsGetLinks(DailyCosmicStats object) {
  return [];
}

void _dailyCosmicStatsAttach(
    IsarCollection<dynamic> col, Id id, DailyCosmicStats object) {
  object.id = id;
}

extension DailyCosmicStatsByIndex on IsarCollection<DailyCosmicStats> {
  Future<DailyCosmicStats?> getByDateString(String dateString) {
    return getByIndex(r'dateString', [dateString]);
  }

  DailyCosmicStats? getByDateStringSync(String dateString) {
    return getByIndexSync(r'dateString', [dateString]);
  }

  Future<bool> deleteByDateString(String dateString) {
    return deleteByIndex(r'dateString', [dateString]);
  }

  bool deleteByDateStringSync(String dateString) {
    return deleteByIndexSync(r'dateString', [dateString]);
  }

  Future<List<DailyCosmicStats?>> getAllByDateString(
      List<String> dateStringValues) {
    final values = dateStringValues.map((e) => [e]).toList();
    return getAllByIndex(r'dateString', values);
  }

  List<DailyCosmicStats?> getAllByDateStringSync(
      List<String> dateStringValues) {
    final values = dateStringValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'dateString', values);
  }

  Future<int> deleteAllByDateString(List<String> dateStringValues) {
    final values = dateStringValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'dateString', values);
  }

  int deleteAllByDateStringSync(List<String> dateStringValues) {
    final values = dateStringValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'dateString', values);
  }

  Future<Id> putByDateString(DailyCosmicStats object) {
    return putByIndex(r'dateString', object);
  }

  Id putByDateStringSync(DailyCosmicStats object, {bool saveLinks = true}) {
    return putByIndexSync(r'dateString', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateString(List<DailyCosmicStats> objects) {
    return putAllByIndex(r'dateString', objects);
  }

  List<Id> putAllByDateStringSync(List<DailyCosmicStats> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'dateString', objects, saveLinks: saveLinks);
  }
}

extension DailyCosmicStatsQueryWhereSort
    on QueryBuilder<DailyCosmicStats, DailyCosmicStats, QWhere> {
  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DailyCosmicStatsQueryWhere
    on QueryBuilder<DailyCosmicStats, DailyCosmicStats, QWhereClause> {
  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterWhereClause> idBetween(
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

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterWhereClause>
      dateStringEqualTo(String dateString) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateString',
        value: [dateString],
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterWhereClause>
      dateStringNotEqualTo(String dateString) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateString',
              lower: [],
              upper: [dateString],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateString',
              lower: [dateString],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateString',
              lower: [dateString],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateString',
              lower: [],
              upper: [dateString],
              includeUpper: false,
            ));
      }
    });
  }
}

extension DailyCosmicStatsQueryFilter
    on QueryBuilder<DailyCosmicStats, DailyCosmicStats, QFilterCondition> {
  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      asrCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'asrCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      asrCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'asrCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      asrCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'asrCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      asrCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'asrCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      awradCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'awradCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      awradCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'awradCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      awradCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'awradCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      awradCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'awradCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dateStringEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dateStringGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dateStringLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dateStringBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateString',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dateStringStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dateStringEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dateStringContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dateStringMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateString',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dateStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateString',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dateStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateString',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dhuhrCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dhuhrCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dhuhrCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dhuhrCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dhuhrCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dhuhrCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      dhuhrCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dhuhrCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      duhaCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'duhaCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      duhaCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'duhaCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      duhaCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'duhaCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      duhaCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'duhaCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      fajrCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fajrCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      fajrCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fajrCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      fajrCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fajrCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      fajrCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fajrCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      ishaCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ishaCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      ishaCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ishaCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      ishaCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ishaCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      ishaCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ishaCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      maashCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maashCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      maashCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maashCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      maashCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maashCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      maashCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maashCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      maghribCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maghribCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      maghribCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maghribCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      maghribCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maghribCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      maghribCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maghribCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      miadCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'miadCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      miadCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'miadCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      miadCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'miadCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      miadCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'miadCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      qiyamCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'qiyamCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      qiyamCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'qiyamCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      qiyamCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'qiyamCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      qiyamCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'qiyamCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      tarweehCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tarweehCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      tarweehCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tarweehCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      tarweehCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tarweehCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      tarweehCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tarweehCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      totalCompletedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      totalCompletedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      totalCompletedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      totalCompletedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCompleted',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      totalMigratedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalMigrated',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      totalMigratedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalMigrated',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      totalMigratedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalMigrated',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterFilterCondition>
      totalMigratedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalMigrated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyCosmicStatsQueryObject
    on QueryBuilder<DailyCosmicStats, DailyCosmicStats, QFilterCondition> {}

extension DailyCosmicStatsQueryLinks
    on QueryBuilder<DailyCosmicStats, DailyCosmicStats, QFilterCondition> {}

extension DailyCosmicStatsQuerySortBy
    on QueryBuilder<DailyCosmicStats, DailyCosmicStats, QSortBy> {
  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByAsrCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'asrCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByAsrCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'asrCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByAwradCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'awradCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByAwradCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'awradCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByDateString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByDateStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByDhuhrCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dhuhrCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByDhuhrCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dhuhrCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByDuhaCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duhaCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByDuhaCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duhaCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByFajrCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fajrCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByFajrCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fajrCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByIshaCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ishaCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByIshaCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ishaCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByMaashCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maashCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByMaashCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maashCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByMaghribCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maghribCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByMaghribCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maghribCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByMiadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'miadCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByMiadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'miadCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByQiyamCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qiyamCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByQiyamCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qiyamCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByTarweehCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tarweehCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByTarweehCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tarweehCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByTotalCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCompleted', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByTotalCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCompleted', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByTotalMigrated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMigrated', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      sortByTotalMigratedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMigrated', Sort.desc);
    });
  }
}

extension DailyCosmicStatsQuerySortThenBy
    on QueryBuilder<DailyCosmicStats, DailyCosmicStats, QSortThenBy> {
  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByAsrCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'asrCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByAsrCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'asrCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByAwradCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'awradCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByAwradCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'awradCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByDateString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByDateStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByDhuhrCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dhuhrCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByDhuhrCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dhuhrCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByDuhaCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duhaCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByDuhaCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duhaCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByFajrCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fajrCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByFajrCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fajrCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByIshaCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ishaCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByIshaCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ishaCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByMaashCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maashCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByMaashCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maashCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByMaghribCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maghribCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByMaghribCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maghribCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByMiadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'miadCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByMiadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'miadCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByQiyamCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qiyamCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByQiyamCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qiyamCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByTarweehCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tarweehCount', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByTarweehCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tarweehCount', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByTotalCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCompleted', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByTotalCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCompleted', Sort.desc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByTotalMigrated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMigrated', Sort.asc);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QAfterSortBy>
      thenByTotalMigratedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMigrated', Sort.desc);
    });
  }
}

extension DailyCosmicStatsQueryWhereDistinct
    on QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct> {
  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByAsrCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'asrCount');
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByAwradCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'awradCount');
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByDateString({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateString', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByDhuhrCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dhuhrCount');
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByDuhaCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'duhaCount');
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByFajrCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fajrCount');
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByIshaCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ishaCount');
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByMaashCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maashCount');
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByMaghribCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maghribCount');
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByMiadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'miadCount');
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByQiyamCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'qiyamCount');
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByTarweehCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tarweehCount');
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByTotalCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCompleted');
    });
  }

  QueryBuilder<DailyCosmicStats, DailyCosmicStats, QDistinct>
      distinctByTotalMigrated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalMigrated');
    });
  }
}

extension DailyCosmicStatsQueryProperty
    on QueryBuilder<DailyCosmicStats, DailyCosmicStats, QQueryProperty> {
  QueryBuilder<DailyCosmicStats, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyCosmicStats, int, QQueryOperations> asrCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'asrCount');
    });
  }

  QueryBuilder<DailyCosmicStats, int, QQueryOperations> awradCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'awradCount');
    });
  }

  QueryBuilder<DailyCosmicStats, String, QQueryOperations>
      dateStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateString');
    });
  }

  QueryBuilder<DailyCosmicStats, int, QQueryOperations> dhuhrCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dhuhrCount');
    });
  }

  QueryBuilder<DailyCosmicStats, int, QQueryOperations> duhaCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'duhaCount');
    });
  }

  QueryBuilder<DailyCosmicStats, int, QQueryOperations> fajrCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fajrCount');
    });
  }

  QueryBuilder<DailyCosmicStats, int, QQueryOperations> ishaCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ishaCount');
    });
  }

  QueryBuilder<DailyCosmicStats, int, QQueryOperations> maashCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maashCount');
    });
  }

  QueryBuilder<DailyCosmicStats, int, QQueryOperations> maghribCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maghribCount');
    });
  }

  QueryBuilder<DailyCosmicStats, int, QQueryOperations> miadCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'miadCount');
    });
  }

  QueryBuilder<DailyCosmicStats, int, QQueryOperations> qiyamCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'qiyamCount');
    });
  }

  QueryBuilder<DailyCosmicStats, int, QQueryOperations> tarweehCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tarweehCount');
    });
  }

  QueryBuilder<DailyCosmicStats, int, QQueryOperations>
      totalCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCompleted');
    });
  }

  QueryBuilder<DailyCosmicStats, int, QQueryOperations>
      totalMigratedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalMigrated');
    });
  }
}
