// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ImportsTable extends Imports with TableInfo<$ImportsTable, Import> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceImageMeta = const VerificationMeta(
    'sourceImage',
  );
  @override
  late final GeneratedColumn<String> sourceImage = GeneratedColumn<String>(
    'source_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawDraftJsonMeta = const VerificationMeta(
    'rawDraftJson',
  );
  @override
  late final GeneratedColumn<String> rawDraftJson = GeneratedColumn<String>(
    'raw_draft_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceImage,
    model,
    rawDraftJson,
    importedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'imports';
  @override
  VerificationContext validateIntegrity(
    Insertable<Import> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_image')) {
      context.handle(
        _sourceImageMeta,
        sourceImage.isAcceptableOrUnknown(
          data['source_image']!,
          _sourceImageMeta,
        ),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('raw_draft_json')) {
      context.handle(
        _rawDraftJsonMeta,
        rawDraftJson.isAcceptableOrUnknown(
          data['raw_draft_json']!,
          _rawDraftJsonMeta,
        ),
      );
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Import map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Import(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_image'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      rawDraftJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_draft_json'],
      ),
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
    );
  }

  @override
  $ImportsTable createAlias(String alias) {
    return $ImportsTable(attachedDatabase, alias);
  }
}

class Import extends DataClass implements Insertable<Import> {
  final int id;

  /// Path or content-hash of the source photo.
  final String? sourceImage;

  /// Model id that produced the draft (e.g. `claude-opus-4-8`).
  final String? model;

  /// The extractor's structured-output draft, verbatim.
  final String? rawDraftJson;
  final DateTime importedAt;
  const Import({
    required this.id,
    this.sourceImage,
    this.model,
    this.rawDraftJson,
    required this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sourceImage != null) {
      map['source_image'] = Variable<String>(sourceImage);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || rawDraftJson != null) {
      map['raw_draft_json'] = Variable<String>(rawDraftJson);
    }
    map['imported_at'] = Variable<DateTime>(importedAt);
    return map;
  }

  ImportsCompanion toCompanion(bool nullToAbsent) {
    return ImportsCompanion(
      id: Value(id),
      sourceImage: sourceImage == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceImage),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      rawDraftJson: rawDraftJson == null && nullToAbsent
          ? const Value.absent()
          : Value(rawDraftJson),
      importedAt: Value(importedAt),
    );
  }

  factory Import.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Import(
      id: serializer.fromJson<int>(json['id']),
      sourceImage: serializer.fromJson<String?>(json['sourceImage']),
      model: serializer.fromJson<String?>(json['model']),
      rawDraftJson: serializer.fromJson<String?>(json['rawDraftJson']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceImage': serializer.toJson<String?>(sourceImage),
      'model': serializer.toJson<String?>(model),
      'rawDraftJson': serializer.toJson<String?>(rawDraftJson),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  Import copyWith({
    int? id,
    Value<String?> sourceImage = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<String?> rawDraftJson = const Value.absent(),
    DateTime? importedAt,
  }) => Import(
    id: id ?? this.id,
    sourceImage: sourceImage.present ? sourceImage.value : this.sourceImage,
    model: model.present ? model.value : this.model,
    rawDraftJson: rawDraftJson.present ? rawDraftJson.value : this.rawDraftJson,
    importedAt: importedAt ?? this.importedAt,
  );
  Import copyWithCompanion(ImportsCompanion data) {
    return Import(
      id: data.id.present ? data.id.value : this.id,
      sourceImage: data.sourceImage.present
          ? data.sourceImage.value
          : this.sourceImage,
      model: data.model.present ? data.model.value : this.model,
      rawDraftJson: data.rawDraftJson.present
          ? data.rawDraftJson.value
          : this.rawDraftJson,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Import(')
          ..write('id: $id, ')
          ..write('sourceImage: $sourceImage, ')
          ..write('model: $model, ')
          ..write('rawDraftJson: $rawDraftJson, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sourceImage, model, rawDraftJson, importedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Import &&
          other.id == this.id &&
          other.sourceImage == this.sourceImage &&
          other.model == this.model &&
          other.rawDraftJson == this.rawDraftJson &&
          other.importedAt == this.importedAt);
}

class ImportsCompanion extends UpdateCompanion<Import> {
  final Value<int> id;
  final Value<String?> sourceImage;
  final Value<String?> model;
  final Value<String?> rawDraftJson;
  final Value<DateTime> importedAt;
  const ImportsCompanion({
    this.id = const Value.absent(),
    this.sourceImage = const Value.absent(),
    this.model = const Value.absent(),
    this.rawDraftJson = const Value.absent(),
    this.importedAt = const Value.absent(),
  });
  ImportsCompanion.insert({
    this.id = const Value.absent(),
    this.sourceImage = const Value.absent(),
    this.model = const Value.absent(),
    this.rawDraftJson = const Value.absent(),
    this.importedAt = const Value.absent(),
  });
  static Insertable<Import> custom({
    Expression<int>? id,
    Expression<String>? sourceImage,
    Expression<String>? model,
    Expression<String>? rawDraftJson,
    Expression<DateTime>? importedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceImage != null) 'source_image': sourceImage,
      if (model != null) 'model': model,
      if (rawDraftJson != null) 'raw_draft_json': rawDraftJson,
      if (importedAt != null) 'imported_at': importedAt,
    });
  }

  ImportsCompanion copyWith({
    Value<int>? id,
    Value<String?>? sourceImage,
    Value<String?>? model,
    Value<String?>? rawDraftJson,
    Value<DateTime>? importedAt,
  }) {
    return ImportsCompanion(
      id: id ?? this.id,
      sourceImage: sourceImage ?? this.sourceImage,
      model: model ?? this.model,
      rawDraftJson: rawDraftJson ?? this.rawDraftJson,
      importedAt: importedAt ?? this.importedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceImage.present) {
      map['source_image'] = Variable<String>(sourceImage.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (rawDraftJson.present) {
      map['raw_draft_json'] = Variable<String>(rawDraftJson.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportsCompanion(')
          ..write('id: $id, ')
          ..write('sourceImage: $sourceImage, ')
          ..write('model: $model, ')
          ..write('rawDraftJson: $rawDraftJson, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }
}

class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kanaMeta = const VerificationMeta('kana');
  @override
  late final GeneratedColumn<String> kana = GeneratedColumn<String>(
    'kana',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kanjiMeta = const VerificationMeta('kanji');
  @override
  late final GeneratedColumn<String> kanji = GeneratedColumn<String>(
    'kanji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WordRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WordRole>($WordsTable.$converterrole);
  static const VerificationMeta _kanaOnlyMeta = const VerificationMeta(
    'kanaOnly',
  );
  @override
  late final GeneratedColumn<bool> kanaOnly = GeneratedColumn<bool>(
    'kana_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("kana_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MeaningSource, String>
  meaningSource = GeneratedColumn<String>(
    'meaning_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => MeaningSource.inferred.name,
  ).withConverter<MeaningSource>($WordsTable.$convertermeaningSource);
  @override
  late final GeneratedColumnWithTypeConverter<ItemStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () => ItemStatus.draft.name,
      ).withConverter<ItemStatus>($WordsTable.$converterstatus);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importIdMeta = const VerificationMeta(
    'importId',
  );
  @override
  late final GeneratedColumn<int> importId = GeneratedColumn<int>(
    'import_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES imports (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kana,
    kanji,
    meaning,
    role,
    kanaOnly,
    meaningSource,
    status,
    notes,
    importId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<Word> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kana')) {
      context.handle(
        _kanaMeta,
        kana.isAcceptableOrUnknown(data['kana']!, _kanaMeta),
      );
    } else if (isInserting) {
      context.missing(_kanaMeta);
    }
    if (data.containsKey('kanji')) {
      context.handle(
        _kanjiMeta,
        kanji.isAcceptableOrUnknown(data['kanji']!, _kanjiMeta),
      );
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    }
    if (data.containsKey('kana_only')) {
      context.handle(
        _kanaOnlyMeta,
        kanaOnly.isAcceptableOrUnknown(data['kana_only']!, _kanaOnlyMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('import_id')) {
      context.handle(
        _importIdMeta,
        importId.isAcceptableOrUnknown(data['import_id']!, _importIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {kana, kanji, role},
  ];
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kana: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kana'],
      )!,
      kanji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kanji'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      ),
      role: $WordsTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      kanaOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}kana_only'],
      )!,
      meaningSource: $WordsTable.$convertermeaningSource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meaning_source'],
        )!,
      ),
      status: $WordsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      importId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}import_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WordRole, String, String> $converterrole =
      const EnumNameConverter<WordRole>(WordRole.values);
  static JsonTypeConverter2<MeaningSource, String, String>
  $convertermeaningSource = const EnumNameConverter<MeaningSource>(
    MeaningSource.values,
  );
  static JsonTypeConverter2<ItemStatus, String, String> $converterstatus =
      const EnumNameConverter<ItemStatus>(ItemStatus.values);
}

class Word extends DataClass implements Insertable<Word> {
  final int id;

  /// Reading in hiragana/katakana, base form. Always present; feeds furigana
  /// and TTS (§4).
  final String kana;

  /// Kanji form, only if the worksheet printed it; '' otherwise (§3).
  final String kanji;

  /// English meaning; null when genuinely undeterminable at import.
  final String? meaning;
  final WordRole role;

  /// True for words with no kanji form (やる, ある, particles).
  final bool kanaOnly;
  final MeaningSource meaningSource;
  final ItemStatus status;

  /// Free-text extraction notes (e.g. "negative stem おもしろく also printed").
  final String? notes;
  final int? importId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Word({
    required this.id,
    required this.kana,
    required this.kanji,
    this.meaning,
    required this.role,
    required this.kanaOnly,
    required this.meaningSource,
    required this.status,
    this.notes,
    this.importId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kana'] = Variable<String>(kana);
    map['kanji'] = Variable<String>(kanji);
    if (!nullToAbsent || meaning != null) {
      map['meaning'] = Variable<String>(meaning);
    }
    {
      map['role'] = Variable<String>($WordsTable.$converterrole.toSql(role));
    }
    map['kana_only'] = Variable<bool>(kanaOnly);
    {
      map['meaning_source'] = Variable<String>(
        $WordsTable.$convertermeaningSource.toSql(meaningSource),
      );
    }
    {
      map['status'] = Variable<String>(
        $WordsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || importId != null) {
      map['import_id'] = Variable<int>(importId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      kana: Value(kana),
      kanji: Value(kanji),
      meaning: meaning == null && nullToAbsent
          ? const Value.absent()
          : Value(meaning),
      role: Value(role),
      kanaOnly: Value(kanaOnly),
      meaningSource: Value(meaningSource),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      importId: importId == null && nullToAbsent
          ? const Value.absent()
          : Value(importId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<int>(json['id']),
      kana: serializer.fromJson<String>(json['kana']),
      kanji: serializer.fromJson<String>(json['kanji']),
      meaning: serializer.fromJson<String?>(json['meaning']),
      role: $WordsTable.$converterrole.fromJson(
        serializer.fromJson<String>(json['role']),
      ),
      kanaOnly: serializer.fromJson<bool>(json['kanaOnly']),
      meaningSource: $WordsTable.$convertermeaningSource.fromJson(
        serializer.fromJson<String>(json['meaningSource']),
      ),
      status: $WordsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      importId: serializer.fromJson<int?>(json['importId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kana': serializer.toJson<String>(kana),
      'kanji': serializer.toJson<String>(kanji),
      'meaning': serializer.toJson<String?>(meaning),
      'role': serializer.toJson<String>(
        $WordsTable.$converterrole.toJson(role),
      ),
      'kanaOnly': serializer.toJson<bool>(kanaOnly),
      'meaningSource': serializer.toJson<String>(
        $WordsTable.$convertermeaningSource.toJson(meaningSource),
      ),
      'status': serializer.toJson<String>(
        $WordsTable.$converterstatus.toJson(status),
      ),
      'notes': serializer.toJson<String?>(notes),
      'importId': serializer.toJson<int?>(importId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Word copyWith({
    int? id,
    String? kana,
    String? kanji,
    Value<String?> meaning = const Value.absent(),
    WordRole? role,
    bool? kanaOnly,
    MeaningSource? meaningSource,
    ItemStatus? status,
    Value<String?> notes = const Value.absent(),
    Value<int?> importId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Word(
    id: id ?? this.id,
    kana: kana ?? this.kana,
    kanji: kanji ?? this.kanji,
    meaning: meaning.present ? meaning.value : this.meaning,
    role: role ?? this.role,
    kanaOnly: kanaOnly ?? this.kanaOnly,
    meaningSource: meaningSource ?? this.meaningSource,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
    importId: importId.present ? importId.value : this.importId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      kana: data.kana.present ? data.kana.value : this.kana,
      kanji: data.kanji.present ? data.kanji.value : this.kanji,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      role: data.role.present ? data.role.value : this.role,
      kanaOnly: data.kanaOnly.present ? data.kanaOnly.value : this.kanaOnly,
      meaningSource: data.meaningSource.present
          ? data.meaningSource.value
          : this.meaningSource,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      importId: data.importId.present ? data.importId.value : this.importId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('kana: $kana, ')
          ..write('kanji: $kanji, ')
          ..write('meaning: $meaning, ')
          ..write('role: $role, ')
          ..write('kanaOnly: $kanaOnly, ')
          ..write('meaningSource: $meaningSource, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('importId: $importId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kana,
    kanji,
    meaning,
    role,
    kanaOnly,
    meaningSource,
    status,
    notes,
    importId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.kana == this.kana &&
          other.kanji == this.kanji &&
          other.meaning == this.meaning &&
          other.role == this.role &&
          other.kanaOnly == this.kanaOnly &&
          other.meaningSource == this.meaningSource &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.importId == this.importId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<int> id;
  final Value<String> kana;
  final Value<String> kanji;
  final Value<String?> meaning;
  final Value<WordRole> role;
  final Value<bool> kanaOnly;
  final Value<MeaningSource> meaningSource;
  final Value<ItemStatus> status;
  final Value<String?> notes;
  final Value<int?> importId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.kana = const Value.absent(),
    this.kanji = const Value.absent(),
    this.meaning = const Value.absent(),
    this.role = const Value.absent(),
    this.kanaOnly = const Value.absent(),
    this.meaningSource = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.importId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required String kana,
    this.kanji = const Value.absent(),
    this.meaning = const Value.absent(),
    required WordRole role,
    this.kanaOnly = const Value.absent(),
    this.meaningSource = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.importId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : kana = Value(kana),
       role = Value(role);
  static Insertable<Word> custom({
    Expression<int>? id,
    Expression<String>? kana,
    Expression<String>? kanji,
    Expression<String>? meaning,
    Expression<String>? role,
    Expression<bool>? kanaOnly,
    Expression<String>? meaningSource,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<int>? importId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kana != null) 'kana': kana,
      if (kanji != null) 'kanji': kanji,
      if (meaning != null) 'meaning': meaning,
      if (role != null) 'role': role,
      if (kanaOnly != null) 'kana_only': kanaOnly,
      if (meaningSource != null) 'meaning_source': meaningSource,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (importId != null) 'import_id': importId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WordsCompanion copyWith({
    Value<int>? id,
    Value<String>? kana,
    Value<String>? kanji,
    Value<String?>? meaning,
    Value<WordRole>? role,
    Value<bool>? kanaOnly,
    Value<MeaningSource>? meaningSource,
    Value<ItemStatus>? status,
    Value<String?>? notes,
    Value<int?>? importId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      kana: kana ?? this.kana,
      kanji: kanji ?? this.kanji,
      meaning: meaning ?? this.meaning,
      role: role ?? this.role,
      kanaOnly: kanaOnly ?? this.kanaOnly,
      meaningSource: meaningSource ?? this.meaningSource,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      importId: importId ?? this.importId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kana.present) {
      map['kana'] = Variable<String>(kana.value);
    }
    if (kanji.present) {
      map['kanji'] = Variable<String>(kanji.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(
        $WordsTable.$converterrole.toSql(role.value),
      );
    }
    if (kanaOnly.present) {
      map['kana_only'] = Variable<bool>(kanaOnly.value);
    }
    if (meaningSource.present) {
      map['meaning_source'] = Variable<String>(
        $WordsTable.$convertermeaningSource.toSql(meaningSource.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $WordsTable.$converterstatus.toSql(status.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (importId.present) {
      map['import_id'] = Variable<int>(importId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('kana: $kana, ')
          ..write('kanji: $kanji, ')
          ..write('meaning: $meaning, ')
          ..write('role: $role, ')
          ..write('kanaOnly: $kanaOnly, ')
          ..write('meaningSource: $meaningSource, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('importId: $importId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StructuresTable extends Structures
    with TableInfo<$StructuresTable, Structure> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StructuresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _templateMeta = const VerificationMeta(
    'template',
  );
  @override
  late final GeneratedColumn<String> template = GeneratedColumn<String>(
    'template',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () => ItemStatus.draft.name,
      ).withConverter<ItemStatus>($StructuresTable.$converterstatus);
  static const VerificationMeta _importIdMeta = const VerificationMeta(
    'importId',
  );
  @override
  late final GeneratedColumn<int> importId = GeneratedColumn<int>(
    'import_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES imports (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    template,
    notes,
    status,
    importId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'structures';
  @override
  VerificationContext validateIntegrity(
    Insertable<Structure> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template')) {
      context.handle(
        _templateMeta,
        template.isAcceptableOrUnknown(data['template']!, _templateMeta),
      );
    } else if (isInserting) {
      context.missing(_templateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('import_id')) {
      context.handle(
        _importIdMeta,
        importId.isAcceptableOrUnknown(data['import_id']!, _importIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Structure map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Structure(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      template: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: $StructuresTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      importId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}import_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StructuresTable createAlias(String alias) {
    return $StructuresTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ItemStatus, String, String> $converterstatus =
      const EnumNameConverter<ItemStatus>(ItemStatus.values);
}

class Structure extends DataClass implements Insertable<Structure> {
  final int id;

  /// Template text with `{slot_name}` placeholders. Unique — a re-import of the
  /// same pattern is deduped.
  final String template;
  final String? notes;
  final ItemStatus status;
  final int? importId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Structure({
    required this.id,
    required this.template,
    this.notes,
    required this.status,
    this.importId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template'] = Variable<String>(template);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['status'] = Variable<String>(
        $StructuresTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || importId != null) {
      map['import_id'] = Variable<int>(importId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StructuresCompanion toCompanion(bool nullToAbsent) {
    return StructuresCompanion(
      id: Value(id),
      template: Value(template),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      importId: importId == null && nullToAbsent
          ? const Value.absent()
          : Value(importId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Structure.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Structure(
      id: serializer.fromJson<int>(json['id']),
      template: serializer.fromJson<String>(json['template']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: $StructuresTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      importId: serializer.fromJson<int?>(json['importId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'template': serializer.toJson<String>(template),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(
        $StructuresTable.$converterstatus.toJson(status),
      ),
      'importId': serializer.toJson<int?>(importId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Structure copyWith({
    int? id,
    String? template,
    Value<String?> notes = const Value.absent(),
    ItemStatus? status,
    Value<int?> importId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Structure(
    id: id ?? this.id,
    template: template ?? this.template,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    importId: importId.present ? importId.value : this.importId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Structure copyWithCompanion(StructuresCompanion data) {
    return Structure(
      id: data.id.present ? data.id.value : this.id,
      template: data.template.present ? data.template.value : this.template,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      importId: data.importId.present ? data.importId.value : this.importId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Structure(')
          ..write('id: $id, ')
          ..write('template: $template, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('importId: $importId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, template, notes, status, importId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Structure &&
          other.id == this.id &&
          other.template == this.template &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.importId == this.importId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StructuresCompanion extends UpdateCompanion<Structure> {
  final Value<int> id;
  final Value<String> template;
  final Value<String?> notes;
  final Value<ItemStatus> status;
  final Value<int?> importId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const StructuresCompanion({
    this.id = const Value.absent(),
    this.template = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.importId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StructuresCompanion.insert({
    this.id = const Value.absent(),
    required String template,
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.importId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : template = Value(template);
  static Insertable<Structure> custom({
    Expression<int>? id,
    Expression<String>? template,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<int>? importId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (template != null) 'template': template,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (importId != null) 'import_id': importId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StructuresCompanion copyWith({
    Value<int>? id,
    Value<String>? template,
    Value<String?>? notes,
    Value<ItemStatus>? status,
    Value<int?>? importId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return StructuresCompanion(
      id: id ?? this.id,
      template: template ?? this.template,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      importId: importId ?? this.importId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (template.present) {
      map['template'] = Variable<String>(template.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $StructuresTable.$converterstatus.toSql(status.value),
      );
    }
    if (importId.present) {
      map['import_id'] = Variable<int>(importId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StructuresCompanion(')
          ..write('id: $id, ')
          ..write('template: $template, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('importId: $importId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SlotsTable extends Slots with TableInfo<$SlotsTable, Slot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _structureIdMeta = const VerificationMeta(
    'structureId',
  );
  @override
  late final GeneratedColumn<int> structureId = GeneratedColumn<int>(
    'structure_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES structures (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WordRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WordRole>($SlotsTable.$converterrole);
  @override
  late final GeneratedColumnWithTypeConverter<SlotForm, String> form =
      GeneratedColumn<String>(
        'form',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () => SlotForm.dictionary.name,
      ).withConverter<SlotForm>($SlotsTable.$converterform);
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    structureId,
    name,
    role,
    form,
    ordinal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<Slot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('structure_id')) {
      context.handle(
        _structureIdMeta,
        structureId.isAcceptableOrUnknown(
          data['structure_id']!,
          _structureIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_structureIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {structureId, name},
  ];
  @override
  Slot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Slot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      structureId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}structure_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: $SlotsTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      form: $SlotsTable.$converterform.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}form'],
        )!,
      ),
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
    );
  }

  @override
  $SlotsTable createAlias(String alias) {
    return $SlotsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WordRole, String, String> $converterrole =
      const EnumNameConverter<WordRole>(WordRole.values);
  static JsonTypeConverter2<SlotForm, String, String> $converterform =
      const EnumNameConverter<SlotForm>(SlotForm.values);
}

class Slot extends DataClass implements Insertable<Slot> {
  final int id;
  final int structureId;

  /// Placeholder name without braces, e.g. `noun_1`. Matches the template text.
  final String name;
  final WordRole role;
  final SlotForm form;

  /// Left-to-right order of the slot in the template.
  final int ordinal;
  const Slot({
    required this.id,
    required this.structureId,
    required this.name,
    required this.role,
    required this.form,
    required this.ordinal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['structure_id'] = Variable<int>(structureId);
    map['name'] = Variable<String>(name);
    {
      map['role'] = Variable<String>($SlotsTable.$converterrole.toSql(role));
    }
    {
      map['form'] = Variable<String>($SlotsTable.$converterform.toSql(form));
    }
    map['ordinal'] = Variable<int>(ordinal);
    return map;
  }

  SlotsCompanion toCompanion(bool nullToAbsent) {
    return SlotsCompanion(
      id: Value(id),
      structureId: Value(structureId),
      name: Value(name),
      role: Value(role),
      form: Value(form),
      ordinal: Value(ordinal),
    );
  }

  factory Slot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Slot(
      id: serializer.fromJson<int>(json['id']),
      structureId: serializer.fromJson<int>(json['structureId']),
      name: serializer.fromJson<String>(json['name']),
      role: $SlotsTable.$converterrole.fromJson(
        serializer.fromJson<String>(json['role']),
      ),
      form: $SlotsTable.$converterform.fromJson(
        serializer.fromJson<String>(json['form']),
      ),
      ordinal: serializer.fromJson<int>(json['ordinal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'structureId': serializer.toJson<int>(structureId),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(
        $SlotsTable.$converterrole.toJson(role),
      ),
      'form': serializer.toJson<String>(
        $SlotsTable.$converterform.toJson(form),
      ),
      'ordinal': serializer.toJson<int>(ordinal),
    };
  }

  Slot copyWith({
    int? id,
    int? structureId,
    String? name,
    WordRole? role,
    SlotForm? form,
    int? ordinal,
  }) => Slot(
    id: id ?? this.id,
    structureId: structureId ?? this.structureId,
    name: name ?? this.name,
    role: role ?? this.role,
    form: form ?? this.form,
    ordinal: ordinal ?? this.ordinal,
  );
  Slot copyWithCompanion(SlotsCompanion data) {
    return Slot(
      id: data.id.present ? data.id.value : this.id,
      structureId: data.structureId.present
          ? data.structureId.value
          : this.structureId,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      form: data.form.present ? data.form.value : this.form,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Slot(')
          ..write('id: $id, ')
          ..write('structureId: $structureId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('form: $form, ')
          ..write('ordinal: $ordinal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, structureId, name, role, form, ordinal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Slot &&
          other.id == this.id &&
          other.structureId == this.structureId &&
          other.name == this.name &&
          other.role == this.role &&
          other.form == this.form &&
          other.ordinal == this.ordinal);
}

class SlotsCompanion extends UpdateCompanion<Slot> {
  final Value<int> id;
  final Value<int> structureId;
  final Value<String> name;
  final Value<WordRole> role;
  final Value<SlotForm> form;
  final Value<int> ordinal;
  const SlotsCompanion({
    this.id = const Value.absent(),
    this.structureId = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.form = const Value.absent(),
    this.ordinal = const Value.absent(),
  });
  SlotsCompanion.insert({
    this.id = const Value.absent(),
    required int structureId,
    required String name,
    required WordRole role,
    this.form = const Value.absent(),
    this.ordinal = const Value.absent(),
  }) : structureId = Value(structureId),
       name = Value(name),
       role = Value(role);
  static Insertable<Slot> custom({
    Expression<int>? id,
    Expression<int>? structureId,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? form,
    Expression<int>? ordinal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (structureId != null) 'structure_id': structureId,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (form != null) 'form': form,
      if (ordinal != null) 'ordinal': ordinal,
    });
  }

  SlotsCompanion copyWith({
    Value<int>? id,
    Value<int>? structureId,
    Value<String>? name,
    Value<WordRole>? role,
    Value<SlotForm>? form,
    Value<int>? ordinal,
  }) {
    return SlotsCompanion(
      id: id ?? this.id,
      structureId: structureId ?? this.structureId,
      name: name ?? this.name,
      role: role ?? this.role,
      form: form ?? this.form,
      ordinal: ordinal ?? this.ordinal,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (structureId.present) {
      map['structure_id'] = Variable<int>(structureId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(
        $SlotsTable.$converterrole.toSql(role.value),
      );
    }
    if (form.present) {
      map['form'] = Variable<String>(
        $SlotsTable.$converterform.toSql(form.value),
      );
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SlotsCompanion(')
          ..write('id: $id, ')
          ..write('structureId: $structureId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('form: $form, ')
          ..write('ordinal: $ordinal')
          ..write(')'))
        .toString();
  }
}

class $ExampleSentencesTable extends ExampleSentences
    with TableInfo<$ExampleSentencesTable, ExampleSentence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExampleSentencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sentenceMeta = const VerificationMeta(
    'sentence',
  );
  @override
  late final GeneratedColumn<String> sentence = GeneratedColumn<String>(
    'sentence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _structureIdMeta = const VerificationMeta(
    'structureId',
  );
  @override
  late final GeneratedColumn<int> structureId = GeneratedColumn<int>(
    'structure_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES structures (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _importIdMeta = const VerificationMeta(
    'importId',
  );
  @override
  late final GeneratedColumn<int> importId = GeneratedColumn<int>(
    'import_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES imports (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sentence,
    wordId,
    structureId,
    importId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'example_sentences';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExampleSentence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sentence')) {
      context.handle(
        _sentenceMeta,
        sentence.isAcceptableOrUnknown(data['sentence']!, _sentenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sentenceMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    }
    if (data.containsKey('structure_id')) {
      context.handle(
        _structureIdMeta,
        structureId.isAcceptableOrUnknown(
          data['structure_id']!,
          _structureIdMeta,
        ),
      );
    }
    if (data.containsKey('import_id')) {
      context.handle(
        _importIdMeta,
        importId.isAcceptableOrUnknown(data['import_id']!, _importIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExampleSentence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExampleSentence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sentence'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      ),
      structureId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}structure_id'],
      ),
      importId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}import_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExampleSentencesTable createAlias(String alias) {
    return $ExampleSentencesTable(attachedDatabase, alias);
  }
}

class ExampleSentence extends DataClass implements Insertable<ExampleSentence> {
  final int id;

  /// The sentence as printed. (Named `sentence`, not `text`, because `text` is
  /// drift's column-builder method on [Table].)
  final String sentence;
  final int? wordId;
  final int? structureId;
  final int? importId;
  final DateTime createdAt;
  const ExampleSentence({
    required this.id,
    required this.sentence,
    this.wordId,
    this.structureId,
    this.importId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sentence'] = Variable<String>(sentence);
    if (!nullToAbsent || wordId != null) {
      map['word_id'] = Variable<int>(wordId);
    }
    if (!nullToAbsent || structureId != null) {
      map['structure_id'] = Variable<int>(structureId);
    }
    if (!nullToAbsent || importId != null) {
      map['import_id'] = Variable<int>(importId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExampleSentencesCompanion toCompanion(bool nullToAbsent) {
    return ExampleSentencesCompanion(
      id: Value(id),
      sentence: Value(sentence),
      wordId: wordId == null && nullToAbsent
          ? const Value.absent()
          : Value(wordId),
      structureId: structureId == null && nullToAbsent
          ? const Value.absent()
          : Value(structureId),
      importId: importId == null && nullToAbsent
          ? const Value.absent()
          : Value(importId),
      createdAt: Value(createdAt),
    );
  }

  factory ExampleSentence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExampleSentence(
      id: serializer.fromJson<int>(json['id']),
      sentence: serializer.fromJson<String>(json['sentence']),
      wordId: serializer.fromJson<int?>(json['wordId']),
      structureId: serializer.fromJson<int?>(json['structureId']),
      importId: serializer.fromJson<int?>(json['importId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sentence': serializer.toJson<String>(sentence),
      'wordId': serializer.toJson<int?>(wordId),
      'structureId': serializer.toJson<int?>(structureId),
      'importId': serializer.toJson<int?>(importId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExampleSentence copyWith({
    int? id,
    String? sentence,
    Value<int?> wordId = const Value.absent(),
    Value<int?> structureId = const Value.absent(),
    Value<int?> importId = const Value.absent(),
    DateTime? createdAt,
  }) => ExampleSentence(
    id: id ?? this.id,
    sentence: sentence ?? this.sentence,
    wordId: wordId.present ? wordId.value : this.wordId,
    structureId: structureId.present ? structureId.value : this.structureId,
    importId: importId.present ? importId.value : this.importId,
    createdAt: createdAt ?? this.createdAt,
  );
  ExampleSentence copyWithCompanion(ExampleSentencesCompanion data) {
    return ExampleSentence(
      id: data.id.present ? data.id.value : this.id,
      sentence: data.sentence.present ? data.sentence.value : this.sentence,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      structureId: data.structureId.present
          ? data.structureId.value
          : this.structureId,
      importId: data.importId.present ? data.importId.value : this.importId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExampleSentence(')
          ..write('id: $id, ')
          ..write('sentence: $sentence, ')
          ..write('wordId: $wordId, ')
          ..write('structureId: $structureId, ')
          ..write('importId: $importId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sentence, wordId, structureId, importId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExampleSentence &&
          other.id == this.id &&
          other.sentence == this.sentence &&
          other.wordId == this.wordId &&
          other.structureId == this.structureId &&
          other.importId == this.importId &&
          other.createdAt == this.createdAt);
}

class ExampleSentencesCompanion extends UpdateCompanion<ExampleSentence> {
  final Value<int> id;
  final Value<String> sentence;
  final Value<int?> wordId;
  final Value<int?> structureId;
  final Value<int?> importId;
  final Value<DateTime> createdAt;
  const ExampleSentencesCompanion({
    this.id = const Value.absent(),
    this.sentence = const Value.absent(),
    this.wordId = const Value.absent(),
    this.structureId = const Value.absent(),
    this.importId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExampleSentencesCompanion.insert({
    this.id = const Value.absent(),
    required String sentence,
    this.wordId = const Value.absent(),
    this.structureId = const Value.absent(),
    this.importId = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : sentence = Value(sentence);
  static Insertable<ExampleSentence> custom({
    Expression<int>? id,
    Expression<String>? sentence,
    Expression<int>? wordId,
    Expression<int>? structureId,
    Expression<int>? importId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sentence != null) 'sentence': sentence,
      if (wordId != null) 'word_id': wordId,
      if (structureId != null) 'structure_id': structureId,
      if (importId != null) 'import_id': importId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExampleSentencesCompanion copyWith({
    Value<int>? id,
    Value<String>? sentence,
    Value<int?>? wordId,
    Value<int?>? structureId,
    Value<int?>? importId,
    Value<DateTime>? createdAt,
  }) {
    return ExampleSentencesCompanion(
      id: id ?? this.id,
      sentence: sentence ?? this.sentence,
      wordId: wordId ?? this.wordId,
      structureId: structureId ?? this.structureId,
      importId: importId ?? this.importId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sentence.present) {
      map['sentence'] = Variable<String>(sentence.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (structureId.present) {
      map['structure_id'] = Variable<int>(structureId.value);
    }
    if (importId.present) {
      map['import_id'] = Variable<int>(importId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExampleSentencesCompanion(')
          ..write('id: $id, ')
          ..write('sentence: $sentence, ')
          ..write('wordId: $wordId, ')
          ..write('structureId: $structureId, ')
          ..write('importId: $importId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GeneratedConversationsTable extends GeneratedConversations
    with TableInfo<$GeneratedConversationsTable, GeneratedConversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeneratedConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lineCountMeta = const VerificationMeta(
    'lineCount',
  );
  @override
  late final GeneratedColumn<int> lineCount = GeneratedColumn<int>(
    'line_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastPracticedAtMeta = const VerificationMeta(
    'lastPracticedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPracticedAt =
      GeneratedColumn<DateTime>(
        'last_practiced_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    payloadJson,
    title,
    lineCount,
    audioPath,
    createdAt,
    lastPracticedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'generated_conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<GeneratedConversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('line_count')) {
      context.handle(
        _lineCountMeta,
        lineCount.isAcceptableOrUnknown(data['line_count']!, _lineCountMeta),
      );
    } else if (isInserting) {
      context.missing(_lineCountMeta);
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_practiced_at')) {
      context.handle(
        _lastPracticedAtMeta,
        lastPracticedAt.isAcceptableOrUnknown(
          data['last_practiced_at']!,
          _lastPracticedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GeneratedConversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeneratedConversation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      lineCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_count'],
      )!,
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastPracticedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_practiced_at'],
      ),
    );
  }

  @override
  $GeneratedConversationsTable createAlias(String alias) {
    return $GeneratedConversationsTable(attachedDatabase, alias);
  }
}

class GeneratedConversation extends DataClass
    implements Insertable<GeneratedConversation> {
  final int id;
  final String payloadJson;

  /// Short English noun-phrase describing the scene, produced by the model at
  /// generation time — the conversation-list row title
  /// (features/conversation-list.md). Defaulted to '' so a payload-only insert
  /// (older tests, edge cases) still writes; real generations always set it.
  final String title;
  final int lineCount;

  /// Cached TTS audio for the listening exercise; null until synthesised.
  final String? audioPath;
  final DateTime createdAt;
  final DateTime? lastPracticedAt;
  const GeneratedConversation({
    required this.id,
    required this.payloadJson,
    required this.title,
    required this.lineCount,
    this.audioPath,
    required this.createdAt,
    this.lastPracticedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload_json'] = Variable<String>(payloadJson);
    map['title'] = Variable<String>(title);
    map['line_count'] = Variable<int>(lineCount);
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastPracticedAt != null) {
      map['last_practiced_at'] = Variable<DateTime>(lastPracticedAt);
    }
    return map;
  }

  GeneratedConversationsCompanion toCompanion(bool nullToAbsent) {
    return GeneratedConversationsCompanion(
      id: Value(id),
      payloadJson: Value(payloadJson),
      title: Value(title),
      lineCount: Value(lineCount),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      createdAt: Value(createdAt),
      lastPracticedAt: lastPracticedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPracticedAt),
    );
  }

  factory GeneratedConversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeneratedConversation(
      id: serializer.fromJson<int>(json['id']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      title: serializer.fromJson<String>(json['title']),
      lineCount: serializer.fromJson<int>(json['lineCount']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastPracticedAt: serializer.fromJson<DateTime?>(json['lastPracticedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'title': serializer.toJson<String>(title),
      'lineCount': serializer.toJson<int>(lineCount),
      'audioPath': serializer.toJson<String?>(audioPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastPracticedAt': serializer.toJson<DateTime?>(lastPracticedAt),
    };
  }

  GeneratedConversation copyWith({
    int? id,
    String? payloadJson,
    String? title,
    int? lineCount,
    Value<String?> audioPath = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> lastPracticedAt = const Value.absent(),
  }) => GeneratedConversation(
    id: id ?? this.id,
    payloadJson: payloadJson ?? this.payloadJson,
    title: title ?? this.title,
    lineCount: lineCount ?? this.lineCount,
    audioPath: audioPath.present ? audioPath.value : this.audioPath,
    createdAt: createdAt ?? this.createdAt,
    lastPracticedAt: lastPracticedAt.present
        ? lastPracticedAt.value
        : this.lastPracticedAt,
  );
  GeneratedConversation copyWithCompanion(
    GeneratedConversationsCompanion data,
  ) {
    return GeneratedConversation(
      id: data.id.present ? data.id.value : this.id,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      title: data.title.present ? data.title.value : this.title,
      lineCount: data.lineCount.present ? data.lineCount.value : this.lineCount,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastPracticedAt: data.lastPracticedAt.present
          ? data.lastPracticedAt.value
          : this.lastPracticedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeneratedConversation(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('title: $title, ')
          ..write('lineCount: $lineCount, ')
          ..write('audioPath: $audioPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastPracticedAt: $lastPracticedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    payloadJson,
    title,
    lineCount,
    audioPath,
    createdAt,
    lastPracticedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeneratedConversation &&
          other.id == this.id &&
          other.payloadJson == this.payloadJson &&
          other.title == this.title &&
          other.lineCount == this.lineCount &&
          other.audioPath == this.audioPath &&
          other.createdAt == this.createdAt &&
          other.lastPracticedAt == this.lastPracticedAt);
}

class GeneratedConversationsCompanion
    extends UpdateCompanion<GeneratedConversation> {
  final Value<int> id;
  final Value<String> payloadJson;
  final Value<String> title;
  final Value<int> lineCount;
  final Value<String?> audioPath;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastPracticedAt;
  const GeneratedConversationsCompanion({
    this.id = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.title = const Value.absent(),
    this.lineCount = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastPracticedAt = const Value.absent(),
  });
  GeneratedConversationsCompanion.insert({
    this.id = const Value.absent(),
    required String payloadJson,
    this.title = const Value.absent(),
    required int lineCount,
    this.audioPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastPracticedAt = const Value.absent(),
  }) : payloadJson = Value(payloadJson),
       lineCount = Value(lineCount);
  static Insertable<GeneratedConversation> custom({
    Expression<int>? id,
    Expression<String>? payloadJson,
    Expression<String>? title,
    Expression<int>? lineCount,
    Expression<String>? audioPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastPracticedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (title != null) 'title': title,
      if (lineCount != null) 'line_count': lineCount,
      if (audioPath != null) 'audio_path': audioPath,
      if (createdAt != null) 'created_at': createdAt,
      if (lastPracticedAt != null) 'last_practiced_at': lastPracticedAt,
    });
  }

  GeneratedConversationsCompanion copyWith({
    Value<int>? id,
    Value<String>? payloadJson,
    Value<String>? title,
    Value<int>? lineCount,
    Value<String?>? audioPath,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastPracticedAt,
  }) {
    return GeneratedConversationsCompanion(
      id: id ?? this.id,
      payloadJson: payloadJson ?? this.payloadJson,
      title: title ?? this.title,
      lineCount: lineCount ?? this.lineCount,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt ?? this.createdAt,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (lineCount.present) {
      map['line_count'] = Variable<int>(lineCount.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastPracticedAt.present) {
      map['last_practiced_at'] = Variable<DateTime>(lastPracticedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeneratedConversationsCompanion(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('title: $title, ')
          ..write('lineCount: $lineCount, ')
          ..write('audioPath: $audioPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastPracticedAt: $lastPracticedAt')
          ..write(')'))
        .toString();
  }
}

class $ConversationWordsTable extends ConversationWords
    with TableInfo<$ConversationWordsTable, ConversationWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<int> conversationId = GeneratedColumn<int>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES generated_conversations (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [conversationId, wordId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversation_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId, wordId};
  @override
  ConversationWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationWord(
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}conversation_id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
    );
  }

  @override
  $ConversationWordsTable createAlias(String alias) {
    return $ConversationWordsTable(attachedDatabase, alias);
  }
}

class ConversationWord extends DataClass
    implements Insertable<ConversationWord> {
  final int conversationId;
  final int wordId;
  const ConversationWord({required this.conversationId, required this.wordId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<int>(conversationId);
    map['word_id'] = Variable<int>(wordId);
    return map;
  }

  ConversationWordsCompanion toCompanion(bool nullToAbsent) {
    return ConversationWordsCompanion(
      conversationId: Value(conversationId),
      wordId: Value(wordId),
    );
  }

  factory ConversationWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationWord(
      conversationId: serializer.fromJson<int>(json['conversationId']),
      wordId: serializer.fromJson<int>(json['wordId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversationId': serializer.toJson<int>(conversationId),
      'wordId': serializer.toJson<int>(wordId),
    };
  }

  ConversationWord copyWith({int? conversationId, int? wordId}) =>
      ConversationWord(
        conversationId: conversationId ?? this.conversationId,
        wordId: wordId ?? this.wordId,
      );
  ConversationWord copyWithCompanion(ConversationWordsCompanion data) {
    return ConversationWord(
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationWord(')
          ..write('conversationId: $conversationId, ')
          ..write('wordId: $wordId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(conversationId, wordId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationWord &&
          other.conversationId == this.conversationId &&
          other.wordId == this.wordId);
}

class ConversationWordsCompanion extends UpdateCompanion<ConversationWord> {
  final Value<int> conversationId;
  final Value<int> wordId;
  final Value<int> rowid;
  const ConversationWordsCompanion({
    this.conversationId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationWordsCompanion.insert({
    required int conversationId,
    required int wordId,
    this.rowid = const Value.absent(),
  }) : conversationId = Value(conversationId),
       wordId = Value(wordId);
  static Insertable<ConversationWord> custom({
    Expression<int>? conversationId,
    Expression<int>? wordId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (wordId != null) 'word_id': wordId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationWordsCompanion copyWith({
    Value<int>? conversationId,
    Value<int>? wordId,
    Value<int>? rowid,
  }) {
    return ConversationWordsCompanion(
      conversationId: conversationId ?? this.conversationId,
      wordId: wordId ?? this.wordId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<int>(conversationId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationWordsCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('wordId: $wordId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationStructuresTable extends ConversationStructures
    with TableInfo<$ConversationStructuresTable, ConversationStructure> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationStructuresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<int> conversationId = GeneratedColumn<int>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES generated_conversations (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _structureIdMeta = const VerificationMeta(
    'structureId',
  );
  @override
  late final GeneratedColumn<int> structureId = GeneratedColumn<int>(
    'structure_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES structures (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [conversationId, structureId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversation_structures';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationStructure> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('structure_id')) {
      context.handle(
        _structureIdMeta,
        structureId.isAcceptableOrUnknown(
          data['structure_id']!,
          _structureIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_structureIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId, structureId};
  @override
  ConversationStructure map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationStructure(
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}conversation_id'],
      )!,
      structureId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}structure_id'],
      )!,
    );
  }

  @override
  $ConversationStructuresTable createAlias(String alias) {
    return $ConversationStructuresTable(attachedDatabase, alias);
  }
}

class ConversationStructure extends DataClass
    implements Insertable<ConversationStructure> {
  final int conversationId;
  final int structureId;
  const ConversationStructure({
    required this.conversationId,
    required this.structureId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<int>(conversationId);
    map['structure_id'] = Variable<int>(structureId);
    return map;
  }

  ConversationStructuresCompanion toCompanion(bool nullToAbsent) {
    return ConversationStructuresCompanion(
      conversationId: Value(conversationId),
      structureId: Value(structureId),
    );
  }

  factory ConversationStructure.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationStructure(
      conversationId: serializer.fromJson<int>(json['conversationId']),
      structureId: serializer.fromJson<int>(json['structureId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversationId': serializer.toJson<int>(conversationId),
      'structureId': serializer.toJson<int>(structureId),
    };
  }

  ConversationStructure copyWith({int? conversationId, int? structureId}) =>
      ConversationStructure(
        conversationId: conversationId ?? this.conversationId,
        structureId: structureId ?? this.structureId,
      );
  ConversationStructure copyWithCompanion(
    ConversationStructuresCompanion data,
  ) {
    return ConversationStructure(
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      structureId: data.structureId.present
          ? data.structureId.value
          : this.structureId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationStructure(')
          ..write('conversationId: $conversationId, ')
          ..write('structureId: $structureId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(conversationId, structureId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationStructure &&
          other.conversationId == this.conversationId &&
          other.structureId == this.structureId);
}

class ConversationStructuresCompanion
    extends UpdateCompanion<ConversationStructure> {
  final Value<int> conversationId;
  final Value<int> structureId;
  final Value<int> rowid;
  const ConversationStructuresCompanion({
    this.conversationId = const Value.absent(),
    this.structureId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationStructuresCompanion.insert({
    required int conversationId,
    required int structureId,
    this.rowid = const Value.absent(),
  }) : conversationId = Value(conversationId),
       structureId = Value(structureId);
  static Insertable<ConversationStructure> custom({
    Expression<int>? conversationId,
    Expression<int>? structureId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (structureId != null) 'structure_id': structureId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationStructuresCompanion copyWith({
    Value<int>? conversationId,
    Value<int>? structureId,
    Value<int>? rowid,
  }) {
    return ConversationStructuresCompanion(
      conversationId: conversationId ?? this.conversationId,
      structureId: structureId ?? this.structureId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<int>(conversationId.value);
    }
    if (structureId.present) {
      map['structure_id'] = Variable<int>(structureId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationStructuresCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('structureId: $structureId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SrsCardsTable extends SrsCards with TableInfo<$SrsCardsTable, SrsCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SrsCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SrsItemType, String> itemType =
      GeneratedColumn<String>(
        'item_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SrsItemType>($SrsCardsTable.$converteritemType);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _easeMeta = const VerificationMeta('ease');
  @override
  late final GeneratedColumn<double> ease = GeneratedColumn<double>(
    'ease',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemType,
    itemId,
    ease,
    intervalDays,
    repetitions,
    lapses,
    dueAt,
    lastReviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'srs_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<SrsCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('ease')) {
      context.handle(
        _easeMeta,
        ease.isAcceptableOrUnknown(data['ease']!, _easeMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {itemType, itemId},
  ];
  @override
  SrsCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SrsCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemType: $SrsCardsTable.$converteritemType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}item_type'],
        )!,
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      ease: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
    );
  }

  @override
  $SrsCardsTable createAlias(String alias) {
    return $SrsCardsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SrsItemType, String, String> $converteritemType =
      const EnumNameConverter<SrsItemType>(SrsItemType.values);
}

class SrsCard extends DataClass implements Insertable<SrsCard> {
  final int id;
  final SrsItemType itemType;
  final int itemId;

  /// SM-2-style ease factor.
  final double ease;
  final int intervalDays;
  final int repetitions;
  final int lapses;
  final DateTime dueAt;
  final DateTime? lastReviewedAt;
  const SrsCard({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.ease,
    required this.intervalDays,
    required this.repetitions,
    required this.lapses,
    required this.dueAt,
    this.lastReviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['item_type'] = Variable<String>(
        $SrsCardsTable.$converteritemType.toSql(itemType),
      );
    }
    map['item_id'] = Variable<int>(itemId);
    map['ease'] = Variable<double>(ease);
    map['interval_days'] = Variable<int>(intervalDays);
    map['repetitions'] = Variable<int>(repetitions);
    map['lapses'] = Variable<int>(lapses);
    map['due_at'] = Variable<DateTime>(dueAt);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    return map;
  }

  SrsCardsCompanion toCompanion(bool nullToAbsent) {
    return SrsCardsCompanion(
      id: Value(id),
      itemType: Value(itemType),
      itemId: Value(itemId),
      ease: Value(ease),
      intervalDays: Value(intervalDays),
      repetitions: Value(repetitions),
      lapses: Value(lapses),
      dueAt: Value(dueAt),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
    );
  }

  factory SrsCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SrsCard(
      id: serializer.fromJson<int>(json['id']),
      itemType: $SrsCardsTable.$converteritemType.fromJson(
        serializer.fromJson<String>(json['itemType']),
      ),
      itemId: serializer.fromJson<int>(json['itemId']),
      ease: serializer.fromJson<double>(json['ease']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      lapses: serializer.fromJson<int>(json['lapses']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemType': serializer.toJson<String>(
        $SrsCardsTable.$converteritemType.toJson(itemType),
      ),
      'itemId': serializer.toJson<int>(itemId),
      'ease': serializer.toJson<double>(ease),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'repetitions': serializer.toJson<int>(repetitions),
      'lapses': serializer.toJson<int>(lapses),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
    };
  }

  SrsCard copyWith({
    int? id,
    SrsItemType? itemType,
    int? itemId,
    double? ease,
    int? intervalDays,
    int? repetitions,
    int? lapses,
    DateTime? dueAt,
    Value<DateTime?> lastReviewedAt = const Value.absent(),
  }) => SrsCard(
    id: id ?? this.id,
    itemType: itemType ?? this.itemType,
    itemId: itemId ?? this.itemId,
    ease: ease ?? this.ease,
    intervalDays: intervalDays ?? this.intervalDays,
    repetitions: repetitions ?? this.repetitions,
    lapses: lapses ?? this.lapses,
    dueAt: dueAt ?? this.dueAt,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
  );
  SrsCard copyWithCompanion(SrsCardsCompanion data) {
    return SrsCard(
      id: data.id.present ? data.id.value : this.id,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      ease: data.ease.present ? data.ease.value : this.ease,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SrsCard(')
          ..write('id: $id, ')
          ..write('itemType: $itemType, ')
          ..write('itemId: $itemId, ')
          ..write('ease: $ease, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemType,
    itemId,
    ease,
    intervalDays,
    repetitions,
    lapses,
    dueAt,
    lastReviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SrsCard &&
          other.id == this.id &&
          other.itemType == this.itemType &&
          other.itemId == this.itemId &&
          other.ease == this.ease &&
          other.intervalDays == this.intervalDays &&
          other.repetitions == this.repetitions &&
          other.lapses == this.lapses &&
          other.dueAt == this.dueAt &&
          other.lastReviewedAt == this.lastReviewedAt);
}

class SrsCardsCompanion extends UpdateCompanion<SrsCard> {
  final Value<int> id;
  final Value<SrsItemType> itemType;
  final Value<int> itemId;
  final Value<double> ease;
  final Value<int> intervalDays;
  final Value<int> repetitions;
  final Value<int> lapses;
  final Value<DateTime> dueAt;
  final Value<DateTime?> lastReviewedAt;
  const SrsCardsCompanion({
    this.id = const Value.absent(),
    this.itemType = const Value.absent(),
    this.itemId = const Value.absent(),
    this.ease = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.lapses = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
  });
  SrsCardsCompanion.insert({
    this.id = const Value.absent(),
    required SrsItemType itemType,
    required int itemId,
    this.ease = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.lapses = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
  }) : itemType = Value(itemType),
       itemId = Value(itemId);
  static Insertable<SrsCard> custom({
    Expression<int>? id,
    Expression<String>? itemType,
    Expression<int>? itemId,
    Expression<double>? ease,
    Expression<int>? intervalDays,
    Expression<int>? repetitions,
    Expression<int>? lapses,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? lastReviewedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemType != null) 'item_type': itemType,
      if (itemId != null) 'item_id': itemId,
      if (ease != null) 'ease': ease,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (lapses != null) 'lapses': lapses,
      if (dueAt != null) 'due_at': dueAt,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
    });
  }

  SrsCardsCompanion copyWith({
    Value<int>? id,
    Value<SrsItemType>? itemType,
    Value<int>? itemId,
    Value<double>? ease,
    Value<int>? intervalDays,
    Value<int>? repetitions,
    Value<int>? lapses,
    Value<DateTime>? dueAt,
    Value<DateTime?>? lastReviewedAt,
  }) {
    return SrsCardsCompanion(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      ease: ease ?? this.ease,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(
        $SrsCardsTable.$converteritemType.toSql(itemType.value),
      );
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (ease.present) {
      map['ease'] = Variable<double>(ease.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SrsCardsCompanion(')
          ..write('id: $id, ')
          ..write('itemType: $itemType, ')
          ..write('itemId: $itemId, ')
          ..write('ease: $ease, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }
}

class $GrammarGlueTable extends GrammarGlue
    with TableInfo<$GrammarGlueTable, GrammarGlueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrammarGlueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _surfaceMeta = const VerificationMeta(
    'surface',
  );
  @override
  late final GeneratedColumn<String> surface = GeneratedColumn<String>(
    'surface',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<GlueKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<GlueKind>($GrammarGlueTable.$converterkind);
  static const VerificationMeta _importIdMeta = const VerificationMeta(
    'importId',
  );
  @override
  late final GeneratedColumn<int> importId = GeneratedColumn<int>(
    'import_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES imports (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, surface, kind, importId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grammar_glue';
  @override
  VerificationContext validateIntegrity(
    Insertable<GrammarGlueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surface')) {
      context.handle(
        _surfaceMeta,
        surface.isAcceptableOrUnknown(data['surface']!, _surfaceMeta),
      );
    } else if (isInserting) {
      context.missing(_surfaceMeta);
    }
    if (data.containsKey('import_id')) {
      context.handle(
        _importIdMeta,
        importId.isAcceptableOrUnknown(data['import_id']!, _importIdMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GrammarGlueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrammarGlueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surface: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}surface'],
      )!,
      kind: $GrammarGlueTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      importId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}import_id'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $GrammarGlueTable createAlias(String alias) {
    return $GrammarGlueTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GlueKind, String, String> $converterkind =
      const EnumNameConverter<GlueKind>(GlueKind.values);
}

class GrammarGlueData extends DataClass implements Insertable<GrammarGlueData> {
  final int id;

  /// The glue text exactly as it appears in generated lines (は, です, ...).
  final String surface;
  final GlueKind kind;
  final int? importId;
  final DateTime addedAt;
  const GrammarGlueData({
    required this.id,
    required this.surface,
    required this.kind,
    this.importId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surface'] = Variable<String>(surface);
    {
      map['kind'] = Variable<String>(
        $GrammarGlueTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || importId != null) {
      map['import_id'] = Variable<int>(importId);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  GrammarGlueCompanion toCompanion(bool nullToAbsent) {
    return GrammarGlueCompanion(
      id: Value(id),
      surface: Value(surface),
      kind: Value(kind),
      importId: importId == null && nullToAbsent
          ? const Value.absent()
          : Value(importId),
      addedAt: Value(addedAt),
    );
  }

  factory GrammarGlueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrammarGlueData(
      id: serializer.fromJson<int>(json['id']),
      surface: serializer.fromJson<String>(json['surface']),
      kind: $GrammarGlueTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      importId: serializer.fromJson<int?>(json['importId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surface': serializer.toJson<String>(surface),
      'kind': serializer.toJson<String>(
        $GrammarGlueTable.$converterkind.toJson(kind),
      ),
      'importId': serializer.toJson<int?>(importId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  GrammarGlueData copyWith({
    int? id,
    String? surface,
    GlueKind? kind,
    Value<int?> importId = const Value.absent(),
    DateTime? addedAt,
  }) => GrammarGlueData(
    id: id ?? this.id,
    surface: surface ?? this.surface,
    kind: kind ?? this.kind,
    importId: importId.present ? importId.value : this.importId,
    addedAt: addedAt ?? this.addedAt,
  );
  GrammarGlueData copyWithCompanion(GrammarGlueCompanion data) {
    return GrammarGlueData(
      id: data.id.present ? data.id.value : this.id,
      surface: data.surface.present ? data.surface.value : this.surface,
      kind: data.kind.present ? data.kind.value : this.kind,
      importId: data.importId.present ? data.importId.value : this.importId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrammarGlueData(')
          ..write('id: $id, ')
          ..write('surface: $surface, ')
          ..write('kind: $kind, ')
          ..write('importId: $importId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, surface, kind, importId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrammarGlueData &&
          other.id == this.id &&
          other.surface == this.surface &&
          other.kind == this.kind &&
          other.importId == this.importId &&
          other.addedAt == this.addedAt);
}

class GrammarGlueCompanion extends UpdateCompanion<GrammarGlueData> {
  final Value<int> id;
  final Value<String> surface;
  final Value<GlueKind> kind;
  final Value<int?> importId;
  final Value<DateTime> addedAt;
  const GrammarGlueCompanion({
    this.id = const Value.absent(),
    this.surface = const Value.absent(),
    this.kind = const Value.absent(),
    this.importId = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  GrammarGlueCompanion.insert({
    this.id = const Value.absent(),
    required String surface,
    required GlueKind kind,
    this.importId = const Value.absent(),
    this.addedAt = const Value.absent(),
  }) : surface = Value(surface),
       kind = Value(kind);
  static Insertable<GrammarGlueData> custom({
    Expression<int>? id,
    Expression<String>? surface,
    Expression<String>? kind,
    Expression<int>? importId,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surface != null) 'surface': surface,
      if (kind != null) 'kind': kind,
      if (importId != null) 'import_id': importId,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  GrammarGlueCompanion copyWith({
    Value<int>? id,
    Value<String>? surface,
    Value<GlueKind>? kind,
    Value<int?>? importId,
    Value<DateTime>? addedAt,
  }) {
    return GrammarGlueCompanion(
      id: id ?? this.id,
      surface: surface ?? this.surface,
      kind: kind ?? this.kind,
      importId: importId ?? this.importId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surface.present) {
      map['surface'] = Variable<String>(surface.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $GrammarGlueTable.$converterkind.toSql(kind.value),
      );
    }
    if (importId.present) {
      map['import_id'] = Variable<int>(importId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrammarGlueCompanion(')
          ..write('id: $id, ')
          ..write('surface: $surface, ')
          ..write('kind: $kind, ')
          ..write('importId: $importId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ImportsTable imports = $ImportsTable(this);
  late final $WordsTable words = $WordsTable(this);
  late final $StructuresTable structures = $StructuresTable(this);
  late final $SlotsTable slots = $SlotsTable(this);
  late final $ExampleSentencesTable exampleSentences = $ExampleSentencesTable(
    this,
  );
  late final $GeneratedConversationsTable generatedConversations =
      $GeneratedConversationsTable(this);
  late final $ConversationWordsTable conversationWords =
      $ConversationWordsTable(this);
  late final $ConversationStructuresTable conversationStructures =
      $ConversationStructuresTable(this);
  late final $SrsCardsTable srsCards = $SrsCardsTable(this);
  late final $GrammarGlueTable grammarGlue = $GrammarGlueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    imports,
    words,
    structures,
    slots,
    exampleSentences,
    generatedConversations,
    conversationWords,
    conversationStructures,
    srsCards,
    grammarGlue,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'imports',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('words', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'imports',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('structures', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'structures',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('slots', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'words',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('example_sentences', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'structures',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('example_sentences', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'imports',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('example_sentences', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'generated_conversations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('conversation_words', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'words',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('conversation_words', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'generated_conversations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('conversation_structures', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'structures',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('conversation_structures', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'imports',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('grammar_glue', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$ImportsTableCreateCompanionBuilder =
    ImportsCompanion Function({
      Value<int> id,
      Value<String?> sourceImage,
      Value<String?> model,
      Value<String?> rawDraftJson,
      Value<DateTime> importedAt,
    });
typedef $$ImportsTableUpdateCompanionBuilder =
    ImportsCompanion Function({
      Value<int> id,
      Value<String?> sourceImage,
      Value<String?> model,
      Value<String?> rawDraftJson,
      Value<DateTime> importedAt,
    });

final class $$ImportsTableReferences
    extends BaseReferences<_$AppDatabase, $ImportsTable, Import> {
  $$ImportsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WordsTable, List<Word>> _wordsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.words,
    aliasName: 'imports__id__words__import_id',
  );

  $$WordsTableProcessedTableManager get wordsRefs {
    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.importId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StructuresTable, List<Structure>>
  _structuresRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.structures,
    aliasName: 'imports__id__structures__import_id',
  );

  $$StructuresTableProcessedTableManager get structuresRefs {
    final manager = $$StructuresTableTableManager(
      $_db,
      $_db.structures,
    ).filter((f) => f.importId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_structuresRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExampleSentencesTable, List<ExampleSentence>>
  _exampleSentencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exampleSentences,
    aliasName: 'imports__id__example_sentences__import_id',
  );

  $$ExampleSentencesTableProcessedTableManager get exampleSentencesRefs {
    final manager = $$ExampleSentencesTableTableManager(
      $_db,
      $_db.exampleSentences,
    ).filter((f) => f.importId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exampleSentencesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GrammarGlueTable, List<GrammarGlueData>>
  _grammarGlueRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.grammarGlue,
    aliasName: 'imports__id__grammar_glue__import_id',
  );

  $$GrammarGlueTableProcessedTableManager get grammarGlueRefs {
    final manager = $$GrammarGlueTableTableManager(
      $_db,
      $_db.grammarGlue,
    ).filter((f) => f.importId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_grammarGlueRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ImportsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportsTable> {
  $$ImportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceImage => $composableBuilder(
    column: $table.sourceImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawDraftJson => $composableBuilder(
    column: $table.rawDraftJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> wordsRefs(
    Expression<bool> Function($$WordsTableFilterComposer f) f,
  ) {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.importId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> structuresRefs(
    Expression<bool> Function($$StructuresTableFilterComposer f) f,
  ) {
    final $$StructuresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.structures,
      getReferencedColumn: (t) => t.importId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StructuresTableFilterComposer(
            $db: $db,
            $table: $db.structures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exampleSentencesRefs(
    Expression<bool> Function($$ExampleSentencesTableFilterComposer f) f,
  ) {
    final $$ExampleSentencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exampleSentences,
      getReferencedColumn: (t) => t.importId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExampleSentencesTableFilterComposer(
            $db: $db,
            $table: $db.exampleSentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> grammarGlueRefs(
    Expression<bool> Function($$GrammarGlueTableFilterComposer f) f,
  ) {
    final $$GrammarGlueTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.grammarGlue,
      getReferencedColumn: (t) => t.importId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrammarGlueTableFilterComposer(
            $db: $db,
            $table: $db.grammarGlue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ImportsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportsTable> {
  $$ImportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceImage => $composableBuilder(
    column: $table.sourceImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawDraftJson => $composableBuilder(
    column: $table.rawDraftJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportsTable> {
  $$ImportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceImage => $composableBuilder(
    column: $table.sourceImage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get rawDraftJson => $composableBuilder(
    column: $table.rawDraftJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  Expression<T> wordsRefs<T extends Object>(
    Expression<T> Function($$WordsTableAnnotationComposer a) f,
  ) {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.importId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> structuresRefs<T extends Object>(
    Expression<T> Function($$StructuresTableAnnotationComposer a) f,
  ) {
    final $$StructuresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.structures,
      getReferencedColumn: (t) => t.importId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StructuresTableAnnotationComposer(
            $db: $db,
            $table: $db.structures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exampleSentencesRefs<T extends Object>(
    Expression<T> Function($$ExampleSentencesTableAnnotationComposer a) f,
  ) {
    final $$ExampleSentencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exampleSentences,
      getReferencedColumn: (t) => t.importId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExampleSentencesTableAnnotationComposer(
            $db: $db,
            $table: $db.exampleSentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> grammarGlueRefs<T extends Object>(
    Expression<T> Function($$GrammarGlueTableAnnotationComposer a) f,
  ) {
    final $$GrammarGlueTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.grammarGlue,
      getReferencedColumn: (t) => t.importId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrammarGlueTableAnnotationComposer(
            $db: $db,
            $table: $db.grammarGlue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ImportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportsTable,
          Import,
          $$ImportsTableFilterComposer,
          $$ImportsTableOrderingComposer,
          $$ImportsTableAnnotationComposer,
          $$ImportsTableCreateCompanionBuilder,
          $$ImportsTableUpdateCompanionBuilder,
          (Import, $$ImportsTableReferences),
          Import,
          PrefetchHooks Function({
            bool wordsRefs,
            bool structuresRefs,
            bool exampleSentencesRefs,
            bool grammarGlueRefs,
          })
        > {
  $$ImportsTableTableManager(_$AppDatabase db, $ImportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sourceImage = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> rawDraftJson = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
              }) => ImportsCompanion(
                id: id,
                sourceImage: sourceImage,
                model: model,
                rawDraftJson: rawDraftJson,
                importedAt: importedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sourceImage = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> rawDraftJson = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
              }) => ImportsCompanion.insert(
                id: id,
                sourceImage: sourceImage,
                model: model,
                rawDraftJson: rawDraftJson,
                importedAt: importedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ImportsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                wordsRefs = false,
                structuresRefs = false,
                exampleSentencesRefs = false,
                grammarGlueRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (wordsRefs) db.words,
                    if (structuresRefs) db.structures,
                    if (exampleSentencesRefs) db.exampleSentences,
                    if (grammarGlueRefs) db.grammarGlue,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (wordsRefs)
                        await $_getPrefetchedData<Import, $ImportsTable, Word>(
                          currentTable: table,
                          referencedTable: $$ImportsTableReferences
                              ._wordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ImportsTableReferences(db, table, p0).wordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.importId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (structuresRefs)
                        await $_getPrefetchedData<
                          Import,
                          $ImportsTable,
                          Structure
                        >(
                          currentTable: table,
                          referencedTable: $$ImportsTableReferences
                              ._structuresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ImportsTableReferences(
                                db,
                                table,
                                p0,
                              ).structuresRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.importId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exampleSentencesRefs)
                        await $_getPrefetchedData<
                          Import,
                          $ImportsTable,
                          ExampleSentence
                        >(
                          currentTable: table,
                          referencedTable: $$ImportsTableReferences
                              ._exampleSentencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ImportsTableReferences(
                                db,
                                table,
                                p0,
                              ).exampleSentencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.importId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (grammarGlueRefs)
                        await $_getPrefetchedData<
                          Import,
                          $ImportsTable,
                          GrammarGlueData
                        >(
                          currentTable: table,
                          referencedTable: $$ImportsTableReferences
                              ._grammarGlueRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ImportsTableReferences(
                                db,
                                table,
                                p0,
                              ).grammarGlueRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.importId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ImportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportsTable,
      Import,
      $$ImportsTableFilterComposer,
      $$ImportsTableOrderingComposer,
      $$ImportsTableAnnotationComposer,
      $$ImportsTableCreateCompanionBuilder,
      $$ImportsTableUpdateCompanionBuilder,
      (Import, $$ImportsTableReferences),
      Import,
      PrefetchHooks Function({
        bool wordsRefs,
        bool structuresRefs,
        bool exampleSentencesRefs,
        bool grammarGlueRefs,
      })
    >;
typedef $$WordsTableCreateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      required String kana,
      Value<String> kanji,
      Value<String?> meaning,
      required WordRole role,
      Value<bool> kanaOnly,
      Value<MeaningSource> meaningSource,
      Value<ItemStatus> status,
      Value<String?> notes,
      Value<int?> importId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$WordsTableUpdateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      Value<String> kana,
      Value<String> kanji,
      Value<String?> meaning,
      Value<WordRole> role,
      Value<bool> kanaOnly,
      Value<MeaningSource> meaningSource,
      Value<ItemStatus> status,
      Value<String?> notes,
      Value<int?> importId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$WordsTableReferences
    extends BaseReferences<_$AppDatabase, $WordsTable, Word> {
  $$WordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ImportsTable _importIdTable(_$AppDatabase db) =>
      db.imports.createAlias('words__import_id__imports__id');

  $$ImportsTableProcessedTableManager? get importId {
    final $_column = $_itemColumn<int>('import_id');
    if ($_column == null) return null;
    final manager = $$ImportsTableTableManager(
      $_db,
      $_db.imports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_importIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExampleSentencesTable, List<ExampleSentence>>
  _exampleSentencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exampleSentences,
    aliasName: 'words__id__example_sentences__word_id',
  );

  $$ExampleSentencesTableProcessedTableManager get exampleSentencesRefs {
    final manager = $$ExampleSentencesTableTableManager(
      $_db,
      $_db.exampleSentences,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exampleSentencesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ConversationWordsTable, List<ConversationWord>>
  _conversationWordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.conversationWords,
        aliasName: 'words__id__conversation_words__word_id',
      );

  $$ConversationWordsTableProcessedTableManager get conversationWordsRefs {
    final manager = $$ConversationWordsTableTableManager(
      $_db,
      $_db.conversationWords,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _conversationWordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kana => $composableBuilder(
    column: $table.kana,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kanji => $composableBuilder(
    column: $table.kanji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WordRole, WordRole, String> get role =>
      $composableBuilder(
        column: $table.role,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get kanaOnly => $composableBuilder(
    column: $table.kanaOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MeaningSource, MeaningSource, String>
  get meaningSource => $composableBuilder(
    column: $table.meaningSource,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemStatus, ItemStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ImportsTableFilterComposer get importId {
    final $$ImportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.imports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportsTableFilterComposer(
            $db: $db,
            $table: $db.imports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> exampleSentencesRefs(
    Expression<bool> Function($$ExampleSentencesTableFilterComposer f) f,
  ) {
    final $$ExampleSentencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exampleSentences,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExampleSentencesTableFilterComposer(
            $db: $db,
            $table: $db.exampleSentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> conversationWordsRefs(
    Expression<bool> Function($$ConversationWordsTableFilterComposer f) f,
  ) {
    final $$ConversationWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversationWords,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationWordsTableFilterComposer(
            $db: $db,
            $table: $db.conversationWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kana => $composableBuilder(
    column: $table.kana,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kanji => $composableBuilder(
    column: $table.kanji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get kanaOnly => $composableBuilder(
    column: $table.kanaOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaningSource => $composableBuilder(
    column: $table.meaningSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ImportsTableOrderingComposer get importId {
    final $$ImportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.imports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportsTableOrderingComposer(
            $db: $db,
            $table: $db.imports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kana =>
      $composableBuilder(column: $table.kana, builder: (column) => column);

  GeneratedColumn<String> get kanji =>
      $composableBuilder(column: $table.kanji, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WordRole, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get kanaOnly =>
      $composableBuilder(column: $table.kanaOnly, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MeaningSource, String> get meaningSource =>
      $composableBuilder(
        column: $table.meaningSource,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<ItemStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ImportsTableAnnotationComposer get importId {
    final $$ImportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.imports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportsTableAnnotationComposer(
            $db: $db,
            $table: $db.imports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> exampleSentencesRefs<T extends Object>(
    Expression<T> Function($$ExampleSentencesTableAnnotationComposer a) f,
  ) {
    final $$ExampleSentencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exampleSentences,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExampleSentencesTableAnnotationComposer(
            $db: $db,
            $table: $db.exampleSentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> conversationWordsRefs<T extends Object>(
    Expression<T> Function($$ConversationWordsTableAnnotationComposer a) f,
  ) {
    final $$ConversationWordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.conversationWords,
          getReferencedColumn: (t) => t.wordId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationWordsTableAnnotationComposer(
                $db: $db,
                $table: $db.conversationWords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          Word,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (Word, $$WordsTableReferences),
          Word,
          PrefetchHooks Function({
            bool importId,
            bool exampleSentencesRefs,
            bool conversationWordsRefs,
          })
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kana = const Value.absent(),
                Value<String> kanji = const Value.absent(),
                Value<String?> meaning = const Value.absent(),
                Value<WordRole> role = const Value.absent(),
                Value<bool> kanaOnly = const Value.absent(),
                Value<MeaningSource> meaningSource = const Value.absent(),
                Value<ItemStatus> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> importId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                kana: kana,
                kanji: kanji,
                meaning: meaning,
                role: role,
                kanaOnly: kanaOnly,
                meaningSource: meaningSource,
                status: status,
                notes: notes,
                importId: importId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kana,
                Value<String> kanji = const Value.absent(),
                Value<String?> meaning = const Value.absent(),
                required WordRole role,
                Value<bool> kanaOnly = const Value.absent(),
                Value<MeaningSource> meaningSource = const Value.absent(),
                Value<ItemStatus> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> importId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WordsCompanion.insert(
                id: id,
                kana: kana,
                kanji: kanji,
                meaning: meaning,
                role: role,
                kanaOnly: kanaOnly,
                meaningSource: meaningSource,
                status: status,
                notes: notes,
                importId: importId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$WordsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                importId = false,
                exampleSentencesRefs = false,
                conversationWordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (exampleSentencesRefs) db.exampleSentences,
                    if (conversationWordsRefs) db.conversationWords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (importId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.importId,
                                    referencedTable: $$WordsTableReferences
                                        ._importIdTable(db),
                                    referencedColumn: $$WordsTableReferences
                                        ._importIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (exampleSentencesRefs)
                        await $_getPrefetchedData<
                          Word,
                          $WordsTable,
                          ExampleSentence
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._exampleSentencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).exampleSentencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (conversationWordsRefs)
                        await $_getPrefetchedData<
                          Word,
                          $WordsTable,
                          ConversationWord
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._conversationWordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationWordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      Word,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (Word, $$WordsTableReferences),
      Word,
      PrefetchHooks Function({
        bool importId,
        bool exampleSentencesRefs,
        bool conversationWordsRefs,
      })
    >;
typedef $$StructuresTableCreateCompanionBuilder =
    StructuresCompanion Function({
      Value<int> id,
      required String template,
      Value<String?> notes,
      Value<ItemStatus> status,
      Value<int?> importId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$StructuresTableUpdateCompanionBuilder =
    StructuresCompanion Function({
      Value<int> id,
      Value<String> template,
      Value<String?> notes,
      Value<ItemStatus> status,
      Value<int?> importId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$StructuresTableReferences
    extends BaseReferences<_$AppDatabase, $StructuresTable, Structure> {
  $$StructuresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ImportsTable _importIdTable(_$AppDatabase db) =>
      db.imports.createAlias('structures__import_id__imports__id');

  $$ImportsTableProcessedTableManager? get importId {
    final $_column = $_itemColumn<int>('import_id');
    if ($_column == null) return null;
    final manager = $$ImportsTableTableManager(
      $_db,
      $_db.imports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_importIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SlotsTable, List<Slot>> _slotsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.slots,
    aliasName: 'structures__id__slots__structure_id',
  );

  $$SlotsTableProcessedTableManager get slotsRefs {
    final manager = $$SlotsTableTableManager(
      $_db,
      $_db.slots,
    ).filter((f) => f.structureId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_slotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExampleSentencesTable, List<ExampleSentence>>
  _exampleSentencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exampleSentences,
    aliasName: 'structures__id__example_sentences__structure_id',
  );

  $$ExampleSentencesTableProcessedTableManager get exampleSentencesRefs {
    final manager = $$ExampleSentencesTableTableManager(
      $_db,
      $_db.exampleSentences,
    ).filter((f) => f.structureId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exampleSentencesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ConversationStructuresTable,
    List<ConversationStructure>
  >
  _conversationStructuresRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.conversationStructures,
        aliasName: 'structures__id__conversation_structures__structure_id',
      );

  $$ConversationStructuresTableProcessedTableManager
  get conversationStructuresRefs {
    final manager = $$ConversationStructuresTableTableManager(
      $_db,
      $_db.conversationStructures,
    ).filter((f) => f.structureId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _conversationStructuresRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StructuresTableFilterComposer
    extends Composer<_$AppDatabase, $StructuresTable> {
  $$StructuresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get template => $composableBuilder(
    column: $table.template,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemStatus, ItemStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ImportsTableFilterComposer get importId {
    final $$ImportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.imports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportsTableFilterComposer(
            $db: $db,
            $table: $db.imports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> slotsRefs(
    Expression<bool> Function($$SlotsTableFilterComposer f) f,
  ) {
    final $$SlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.slots,
      getReferencedColumn: (t) => t.structureId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SlotsTableFilterComposer(
            $db: $db,
            $table: $db.slots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exampleSentencesRefs(
    Expression<bool> Function($$ExampleSentencesTableFilterComposer f) f,
  ) {
    final $$ExampleSentencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exampleSentences,
      getReferencedColumn: (t) => t.structureId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExampleSentencesTableFilterComposer(
            $db: $db,
            $table: $db.exampleSentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> conversationStructuresRefs(
    Expression<bool> Function($$ConversationStructuresTableFilterComposer f) f,
  ) {
    final $$ConversationStructuresTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.conversationStructures,
          getReferencedColumn: (t) => t.structureId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationStructuresTableFilterComposer(
                $db: $db,
                $table: $db.conversationStructures,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$StructuresTableOrderingComposer
    extends Composer<_$AppDatabase, $StructuresTable> {
  $$StructuresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get template => $composableBuilder(
    column: $table.template,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ImportsTableOrderingComposer get importId {
    final $$ImportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.imports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportsTableOrderingComposer(
            $db: $db,
            $table: $db.imports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StructuresTableAnnotationComposer
    extends Composer<_$AppDatabase, $StructuresTable> {
  $$StructuresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get template =>
      $composableBuilder(column: $table.template, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ImportsTableAnnotationComposer get importId {
    final $$ImportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.imports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportsTableAnnotationComposer(
            $db: $db,
            $table: $db.imports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> slotsRefs<T extends Object>(
    Expression<T> Function($$SlotsTableAnnotationComposer a) f,
  ) {
    final $$SlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.slots,
      getReferencedColumn: (t) => t.structureId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.slots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exampleSentencesRefs<T extends Object>(
    Expression<T> Function($$ExampleSentencesTableAnnotationComposer a) f,
  ) {
    final $$ExampleSentencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exampleSentences,
      getReferencedColumn: (t) => t.structureId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExampleSentencesTableAnnotationComposer(
            $db: $db,
            $table: $db.exampleSentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> conversationStructuresRefs<T extends Object>(
    Expression<T> Function($$ConversationStructuresTableAnnotationComposer a) f,
  ) {
    final $$ConversationStructuresTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.conversationStructures,
          getReferencedColumn: (t) => t.structureId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationStructuresTableAnnotationComposer(
                $db: $db,
                $table: $db.conversationStructures,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$StructuresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StructuresTable,
          Structure,
          $$StructuresTableFilterComposer,
          $$StructuresTableOrderingComposer,
          $$StructuresTableAnnotationComposer,
          $$StructuresTableCreateCompanionBuilder,
          $$StructuresTableUpdateCompanionBuilder,
          (Structure, $$StructuresTableReferences),
          Structure,
          PrefetchHooks Function({
            bool importId,
            bool slotsRefs,
            bool exampleSentencesRefs,
            bool conversationStructuresRefs,
          })
        > {
  $$StructuresTableTableManager(_$AppDatabase db, $StructuresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StructuresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StructuresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StructuresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> template = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<ItemStatus> status = const Value.absent(),
                Value<int?> importId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StructuresCompanion(
                id: id,
                template: template,
                notes: notes,
                status: status,
                importId: importId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String template,
                Value<String?> notes = const Value.absent(),
                Value<ItemStatus> status = const Value.absent(),
                Value<int?> importId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StructuresCompanion.insert(
                id: id,
                template: template,
                notes: notes,
                status: status,
                importId: importId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StructuresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                importId = false,
                slotsRefs = false,
                exampleSentencesRefs = false,
                conversationStructuresRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (slotsRefs) db.slots,
                    if (exampleSentencesRefs) db.exampleSentences,
                    if (conversationStructuresRefs) db.conversationStructures,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (importId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.importId,
                                    referencedTable: $$StructuresTableReferences
                                        ._importIdTable(db),
                                    referencedColumn:
                                        $$StructuresTableReferences
                                            ._importIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (slotsRefs)
                        await $_getPrefetchedData<
                          Structure,
                          $StructuresTable,
                          Slot
                        >(
                          currentTable: table,
                          referencedTable: $$StructuresTableReferences
                              ._slotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StructuresTableReferences(
                                db,
                                table,
                                p0,
                              ).slotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.structureId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exampleSentencesRefs)
                        await $_getPrefetchedData<
                          Structure,
                          $StructuresTable,
                          ExampleSentence
                        >(
                          currentTable: table,
                          referencedTable: $$StructuresTableReferences
                              ._exampleSentencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StructuresTableReferences(
                                db,
                                table,
                                p0,
                              ).exampleSentencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.structureId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (conversationStructuresRefs)
                        await $_getPrefetchedData<
                          Structure,
                          $StructuresTable,
                          ConversationStructure
                        >(
                          currentTable: table,
                          referencedTable: $$StructuresTableReferences
                              ._conversationStructuresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StructuresTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationStructuresRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.structureId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StructuresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StructuresTable,
      Structure,
      $$StructuresTableFilterComposer,
      $$StructuresTableOrderingComposer,
      $$StructuresTableAnnotationComposer,
      $$StructuresTableCreateCompanionBuilder,
      $$StructuresTableUpdateCompanionBuilder,
      (Structure, $$StructuresTableReferences),
      Structure,
      PrefetchHooks Function({
        bool importId,
        bool slotsRefs,
        bool exampleSentencesRefs,
        bool conversationStructuresRefs,
      })
    >;
typedef $$SlotsTableCreateCompanionBuilder =
    SlotsCompanion Function({
      Value<int> id,
      required int structureId,
      required String name,
      required WordRole role,
      Value<SlotForm> form,
      Value<int> ordinal,
    });
typedef $$SlotsTableUpdateCompanionBuilder =
    SlotsCompanion Function({
      Value<int> id,
      Value<int> structureId,
      Value<String> name,
      Value<WordRole> role,
      Value<SlotForm> form,
      Value<int> ordinal,
    });

final class $$SlotsTableReferences
    extends BaseReferences<_$AppDatabase, $SlotsTable, Slot> {
  $$SlotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StructuresTable _structureIdTable(_$AppDatabase db) =>
      db.structures.createAlias('slots__structure_id__structures__id');

  $$StructuresTableProcessedTableManager get structureId {
    final $_column = $_itemColumn<int>('structure_id')!;

    final manager = $$StructuresTableTableManager(
      $_db,
      $_db.structures,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_structureIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SlotsTableFilterComposer extends Composer<_$AppDatabase, $SlotsTable> {
  $$SlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WordRole, WordRole, String> get role =>
      $composableBuilder(
        column: $table.role,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<SlotForm, SlotForm, String> get form =>
      $composableBuilder(
        column: $table.form,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  $$StructuresTableFilterComposer get structureId {
    final $$StructuresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.structureId,
      referencedTable: $db.structures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StructuresTableFilterComposer(
            $db: $db,
            $table: $db.structures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $SlotsTable> {
  $$SlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get form => $composableBuilder(
    column: $table.form,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  $$StructuresTableOrderingComposer get structureId {
    final $$StructuresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.structureId,
      referencedTable: $db.structures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StructuresTableOrderingComposer(
            $db: $db,
            $table: $db.structures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SlotsTable> {
  $$SlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WordRole, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SlotForm, String> get form =>
      $composableBuilder(column: $table.form, builder: (column) => column);

  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  $$StructuresTableAnnotationComposer get structureId {
    final $$StructuresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.structureId,
      referencedTable: $db.structures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StructuresTableAnnotationComposer(
            $db: $db,
            $table: $db.structures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SlotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SlotsTable,
          Slot,
          $$SlotsTableFilterComposer,
          $$SlotsTableOrderingComposer,
          $$SlotsTableAnnotationComposer,
          $$SlotsTableCreateCompanionBuilder,
          $$SlotsTableUpdateCompanionBuilder,
          (Slot, $$SlotsTableReferences),
          Slot,
          PrefetchHooks Function({bool structureId})
        > {
  $$SlotsTableTableManager(_$AppDatabase db, $SlotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> structureId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<WordRole> role = const Value.absent(),
                Value<SlotForm> form = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
              }) => SlotsCompanion(
                id: id,
                structureId: structureId,
                name: name,
                role: role,
                form: form,
                ordinal: ordinal,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int structureId,
                required String name,
                required WordRole role,
                Value<SlotForm> form = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
              }) => SlotsCompanion.insert(
                id: id,
                structureId: structureId,
                name: name,
                role: role,
                form: form,
                ordinal: ordinal,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SlotsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({structureId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (structureId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.structureId,
                                referencedTable: $$SlotsTableReferences
                                    ._structureIdTable(db),
                                referencedColumn: $$SlotsTableReferences
                                    ._structureIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SlotsTable,
      Slot,
      $$SlotsTableFilterComposer,
      $$SlotsTableOrderingComposer,
      $$SlotsTableAnnotationComposer,
      $$SlotsTableCreateCompanionBuilder,
      $$SlotsTableUpdateCompanionBuilder,
      (Slot, $$SlotsTableReferences),
      Slot,
      PrefetchHooks Function({bool structureId})
    >;
typedef $$ExampleSentencesTableCreateCompanionBuilder =
    ExampleSentencesCompanion Function({
      Value<int> id,
      required String sentence,
      Value<int?> wordId,
      Value<int?> structureId,
      Value<int?> importId,
      Value<DateTime> createdAt,
    });
typedef $$ExampleSentencesTableUpdateCompanionBuilder =
    ExampleSentencesCompanion Function({
      Value<int> id,
      Value<String> sentence,
      Value<int?> wordId,
      Value<int?> structureId,
      Value<int?> importId,
      Value<DateTime> createdAt,
    });

final class $$ExampleSentencesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ExampleSentencesTable, ExampleSentence> {
  $$ExampleSentencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('example_sentences__word_id__words__id');

  $$WordsTableProcessedTableManager? get wordId {
    final $_column = $_itemColumn<int>('word_id');
    if ($_column == null) return null;
    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StructuresTable _structureIdTable(_$AppDatabase db) => db.structures
      .createAlias('example_sentences__structure_id__structures__id');

  $$StructuresTableProcessedTableManager? get structureId {
    final $_column = $_itemColumn<int>('structure_id');
    if ($_column == null) return null;
    final manager = $$StructuresTableTableManager(
      $_db,
      $_db.structures,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_structureIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ImportsTable _importIdTable(_$AppDatabase db) =>
      db.imports.createAlias('example_sentences__import_id__imports__id');

  $$ImportsTableProcessedTableManager? get importId {
    final $_column = $_itemColumn<int>('import_id');
    if ($_column == null) return null;
    final manager = $$ImportsTableTableManager(
      $_db,
      $_db.imports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_importIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExampleSentencesTableFilterComposer
    extends Composer<_$AppDatabase, $ExampleSentencesTable> {
  $$ExampleSentencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sentence => $composableBuilder(
    column: $table.sentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StructuresTableFilterComposer get structureId {
    final $$StructuresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.structureId,
      referencedTable: $db.structures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StructuresTableFilterComposer(
            $db: $db,
            $table: $db.structures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ImportsTableFilterComposer get importId {
    final $$ImportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.imports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportsTableFilterComposer(
            $db: $db,
            $table: $db.imports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExampleSentencesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExampleSentencesTable> {
  $$ExampleSentencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sentence => $composableBuilder(
    column: $table.sentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StructuresTableOrderingComposer get structureId {
    final $$StructuresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.structureId,
      referencedTable: $db.structures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StructuresTableOrderingComposer(
            $db: $db,
            $table: $db.structures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ImportsTableOrderingComposer get importId {
    final $$ImportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.imports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportsTableOrderingComposer(
            $db: $db,
            $table: $db.imports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExampleSentencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExampleSentencesTable> {
  $$ExampleSentencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sentence =>
      $composableBuilder(column: $table.sentence, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StructuresTableAnnotationComposer get structureId {
    final $$StructuresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.structureId,
      referencedTable: $db.structures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StructuresTableAnnotationComposer(
            $db: $db,
            $table: $db.structures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ImportsTableAnnotationComposer get importId {
    final $$ImportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.imports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportsTableAnnotationComposer(
            $db: $db,
            $table: $db.imports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExampleSentencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExampleSentencesTable,
          ExampleSentence,
          $$ExampleSentencesTableFilterComposer,
          $$ExampleSentencesTableOrderingComposer,
          $$ExampleSentencesTableAnnotationComposer,
          $$ExampleSentencesTableCreateCompanionBuilder,
          $$ExampleSentencesTableUpdateCompanionBuilder,
          (ExampleSentence, $$ExampleSentencesTableReferences),
          ExampleSentence,
          PrefetchHooks Function({bool wordId, bool structureId, bool importId})
        > {
  $$ExampleSentencesTableTableManager(
    _$AppDatabase db,
    $ExampleSentencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExampleSentencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExampleSentencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExampleSentencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sentence = const Value.absent(),
                Value<int?> wordId = const Value.absent(),
                Value<int?> structureId = const Value.absent(),
                Value<int?> importId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExampleSentencesCompanion(
                id: id,
                sentence: sentence,
                wordId: wordId,
                structureId: structureId,
                importId: importId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sentence,
                Value<int?> wordId = const Value.absent(),
                Value<int?> structureId = const Value.absent(),
                Value<int?> importId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExampleSentencesCompanion.insert(
                id: id,
                sentence: sentence,
                wordId: wordId,
                structureId: structureId,
                importId: importId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExampleSentencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({wordId = false, structureId = false, importId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (wordId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.wordId,
                                    referencedTable:
                                        $$ExampleSentencesTableReferences
                                            ._wordIdTable(db),
                                    referencedColumn:
                                        $$ExampleSentencesTableReferences
                                            ._wordIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (structureId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.structureId,
                                    referencedTable:
                                        $$ExampleSentencesTableReferences
                                            ._structureIdTable(db),
                                    referencedColumn:
                                        $$ExampleSentencesTableReferences
                                            ._structureIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (importId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.importId,
                                    referencedTable:
                                        $$ExampleSentencesTableReferences
                                            ._importIdTable(db),
                                    referencedColumn:
                                        $$ExampleSentencesTableReferences
                                            ._importIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ExampleSentencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExampleSentencesTable,
      ExampleSentence,
      $$ExampleSentencesTableFilterComposer,
      $$ExampleSentencesTableOrderingComposer,
      $$ExampleSentencesTableAnnotationComposer,
      $$ExampleSentencesTableCreateCompanionBuilder,
      $$ExampleSentencesTableUpdateCompanionBuilder,
      (ExampleSentence, $$ExampleSentencesTableReferences),
      ExampleSentence,
      PrefetchHooks Function({bool wordId, bool structureId, bool importId})
    >;
typedef $$GeneratedConversationsTableCreateCompanionBuilder =
    GeneratedConversationsCompanion Function({
      Value<int> id,
      required String payloadJson,
      Value<String> title,
      required int lineCount,
      Value<String?> audioPath,
      Value<DateTime> createdAt,
      Value<DateTime?> lastPracticedAt,
    });
typedef $$GeneratedConversationsTableUpdateCompanionBuilder =
    GeneratedConversationsCompanion Function({
      Value<int> id,
      Value<String> payloadJson,
      Value<String> title,
      Value<int> lineCount,
      Value<String?> audioPath,
      Value<DateTime> createdAt,
      Value<DateTime?> lastPracticedAt,
    });

final class $$GeneratedConversationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $GeneratedConversationsTable,
          GeneratedConversation
        > {
  $$GeneratedConversationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ConversationWordsTable, List<ConversationWord>>
  _conversationWordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.conversationWords,
        aliasName:
            'generated_conversations__id__conversation_words__conversation_id',
      );

  $$ConversationWordsTableProcessedTableManager get conversationWordsRefs {
    final manager = $$ConversationWordsTableTableManager(
      $_db,
      $_db.conversationWords,
    ).filter((f) => f.conversationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _conversationWordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ConversationStructuresTable,
    List<ConversationStructure>
  >
  _conversationStructuresRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.conversationStructures,
    aliasName:
        'generated_conversations__id__conversation_structures__conversation_id',
  );

  $$ConversationStructuresTableProcessedTableManager
  get conversationStructuresRefs {
    final manager = $$ConversationStructuresTableTableManager(
      $_db,
      $_db.conversationStructures,
    ).filter((f) => f.conversationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _conversationStructuresRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GeneratedConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $GeneratedConversationsTable> {
  $$GeneratedConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineCount => $composableBuilder(
    column: $table.lineCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPracticedAt => $composableBuilder(
    column: $table.lastPracticedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> conversationWordsRefs(
    Expression<bool> Function($$ConversationWordsTableFilterComposer f) f,
  ) {
    final $$ConversationWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversationWords,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationWordsTableFilterComposer(
            $db: $db,
            $table: $db.conversationWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> conversationStructuresRefs(
    Expression<bool> Function($$ConversationStructuresTableFilterComposer f) f,
  ) {
    final $$ConversationStructuresTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.conversationStructures,
          getReferencedColumn: (t) => t.conversationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationStructuresTableFilterComposer(
                $db: $db,
                $table: $db.conversationStructures,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GeneratedConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $GeneratedConversationsTable> {
  $$GeneratedConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineCount => $composableBuilder(
    column: $table.lineCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPracticedAt => $composableBuilder(
    column: $table.lastPracticedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GeneratedConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GeneratedConversationsTable> {
  $$GeneratedConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get lineCount =>
      $composableBuilder(column: $table.lineCount, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPracticedAt => $composableBuilder(
    column: $table.lastPracticedAt,
    builder: (column) => column,
  );

  Expression<T> conversationWordsRefs<T extends Object>(
    Expression<T> Function($$ConversationWordsTableAnnotationComposer a) f,
  ) {
    final $$ConversationWordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.conversationWords,
          getReferencedColumn: (t) => t.conversationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationWordsTableAnnotationComposer(
                $db: $db,
                $table: $db.conversationWords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> conversationStructuresRefs<T extends Object>(
    Expression<T> Function($$ConversationStructuresTableAnnotationComposer a) f,
  ) {
    final $$ConversationStructuresTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.conversationStructures,
          getReferencedColumn: (t) => t.conversationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationStructuresTableAnnotationComposer(
                $db: $db,
                $table: $db.conversationStructures,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GeneratedConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GeneratedConversationsTable,
          GeneratedConversation,
          $$GeneratedConversationsTableFilterComposer,
          $$GeneratedConversationsTableOrderingComposer,
          $$GeneratedConversationsTableAnnotationComposer,
          $$GeneratedConversationsTableCreateCompanionBuilder,
          $$GeneratedConversationsTableUpdateCompanionBuilder,
          (GeneratedConversation, $$GeneratedConversationsTableReferences),
          GeneratedConversation,
          PrefetchHooks Function({
            bool conversationWordsRefs,
            bool conversationStructuresRefs,
          })
        > {
  $$GeneratedConversationsTableTableManager(
    _$AppDatabase db,
    $GeneratedConversationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeneratedConversationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$GeneratedConversationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GeneratedConversationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> lineCount = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastPracticedAt = const Value.absent(),
              }) => GeneratedConversationsCompanion(
                id: id,
                payloadJson: payloadJson,
                title: title,
                lineCount: lineCount,
                audioPath: audioPath,
                createdAt: createdAt,
                lastPracticedAt: lastPracticedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String payloadJson,
                Value<String> title = const Value.absent(),
                required int lineCount,
                Value<String?> audioPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastPracticedAt = const Value.absent(),
              }) => GeneratedConversationsCompanion.insert(
                id: id,
                payloadJson: payloadJson,
                title: title,
                lineCount: lineCount,
                audioPath: audioPath,
                createdAt: createdAt,
                lastPracticedAt: lastPracticedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GeneratedConversationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                conversationWordsRefs = false,
                conversationStructuresRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (conversationWordsRefs) db.conversationWords,
                    if (conversationStructuresRefs) db.conversationStructures,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (conversationWordsRefs)
                        await $_getPrefetchedData<
                          GeneratedConversation,
                          $GeneratedConversationsTable,
                          ConversationWord
                        >(
                          currentTable: table,
                          referencedTable:
                              $$GeneratedConversationsTableReferences
                                  ._conversationWordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GeneratedConversationsTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationWordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.conversationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (conversationStructuresRefs)
                        await $_getPrefetchedData<
                          GeneratedConversation,
                          $GeneratedConversationsTable,
                          ConversationStructure
                        >(
                          currentTable: table,
                          referencedTable:
                              $$GeneratedConversationsTableReferences
                                  ._conversationStructuresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GeneratedConversationsTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationStructuresRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.conversationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GeneratedConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GeneratedConversationsTable,
      GeneratedConversation,
      $$GeneratedConversationsTableFilterComposer,
      $$GeneratedConversationsTableOrderingComposer,
      $$GeneratedConversationsTableAnnotationComposer,
      $$GeneratedConversationsTableCreateCompanionBuilder,
      $$GeneratedConversationsTableUpdateCompanionBuilder,
      (GeneratedConversation, $$GeneratedConversationsTableReferences),
      GeneratedConversation,
      PrefetchHooks Function({
        bool conversationWordsRefs,
        bool conversationStructuresRefs,
      })
    >;
typedef $$ConversationWordsTableCreateCompanionBuilder =
    ConversationWordsCompanion Function({
      required int conversationId,
      required int wordId,
      Value<int> rowid,
    });
typedef $$ConversationWordsTableUpdateCompanionBuilder =
    ConversationWordsCompanion Function({
      Value<int> conversationId,
      Value<int> wordId,
      Value<int> rowid,
    });

final class $$ConversationWordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ConversationWordsTable,
          ConversationWord
        > {
  $$ConversationWordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GeneratedConversationsTable _conversationIdTable(_$AppDatabase db) =>
      db.generatedConversations.createAlias(
        'conversation_words__conversation_id__generated_conversations__id',
      );

  $$GeneratedConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<int>('conversation_id')!;

    final manager = $$GeneratedConversationsTableTableManager(
      $_db,
      $_db.generatedConversations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('conversation_words__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ConversationWordsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationWordsTable> {
  $$ConversationWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$GeneratedConversationsTableFilterComposer get conversationId {
    final $$GeneratedConversationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationId,
          referencedTable: $db.generatedConversations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GeneratedConversationsTableFilterComposer(
                $db: $db,
                $table: $db.generatedConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationWordsTable> {
  $$ConversationWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$GeneratedConversationsTableOrderingComposer get conversationId {
    final $$GeneratedConversationsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationId,
          referencedTable: $db.generatedConversations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GeneratedConversationsTableOrderingComposer(
                $db: $db,
                $table: $db.generatedConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationWordsTable> {
  $$ConversationWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$GeneratedConversationsTableAnnotationComposer get conversationId {
    final $$GeneratedConversationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationId,
          referencedTable: $db.generatedConversations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GeneratedConversationsTableAnnotationComposer(
                $db: $db,
                $table: $db.generatedConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationWordsTable,
          ConversationWord,
          $$ConversationWordsTableFilterComposer,
          $$ConversationWordsTableOrderingComposer,
          $$ConversationWordsTableAnnotationComposer,
          $$ConversationWordsTableCreateCompanionBuilder,
          $$ConversationWordsTableUpdateCompanionBuilder,
          (ConversationWord, $$ConversationWordsTableReferences),
          ConversationWord,
          PrefetchHooks Function({bool conversationId, bool wordId})
        > {
  $$ConversationWordsTableTableManager(
    _$AppDatabase db,
    $ConversationWordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationWordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> conversationId = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationWordsCompanion(
                conversationId: conversationId,
                wordId: wordId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int conversationId,
                required int wordId,
                Value<int> rowid = const Value.absent(),
              }) => ConversationWordsCompanion.insert(
                conversationId: conversationId,
                wordId: wordId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConversationWordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({conversationId = false, wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (conversationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.conversationId,
                                referencedTable:
                                    $$ConversationWordsTableReferences
                                        ._conversationIdTable(db),
                                referencedColumn:
                                    $$ConversationWordsTableReferences
                                        ._conversationIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable:
                                    $$ConversationWordsTableReferences
                                        ._wordIdTable(db),
                                referencedColumn:
                                    $$ConversationWordsTableReferences
                                        ._wordIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ConversationWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationWordsTable,
      ConversationWord,
      $$ConversationWordsTableFilterComposer,
      $$ConversationWordsTableOrderingComposer,
      $$ConversationWordsTableAnnotationComposer,
      $$ConversationWordsTableCreateCompanionBuilder,
      $$ConversationWordsTableUpdateCompanionBuilder,
      (ConversationWord, $$ConversationWordsTableReferences),
      ConversationWord,
      PrefetchHooks Function({bool conversationId, bool wordId})
    >;
typedef $$ConversationStructuresTableCreateCompanionBuilder =
    ConversationStructuresCompanion Function({
      required int conversationId,
      required int structureId,
      Value<int> rowid,
    });
typedef $$ConversationStructuresTableUpdateCompanionBuilder =
    ConversationStructuresCompanion Function({
      Value<int> conversationId,
      Value<int> structureId,
      Value<int> rowid,
    });

final class $$ConversationStructuresTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ConversationStructuresTable,
          ConversationStructure
        > {
  $$ConversationStructuresTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GeneratedConversationsTable _conversationIdTable(_$AppDatabase db) =>
      db.generatedConversations.createAlias(
        'conversation_structures__conversation_id__generated_conversations__id',
      );

  $$GeneratedConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<int>('conversation_id')!;

    final manager = $$GeneratedConversationsTableTableManager(
      $_db,
      $_db.generatedConversations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StructuresTable _structureIdTable(_$AppDatabase db) => db.structures
      .createAlias('conversation_structures__structure_id__structures__id');

  $$StructuresTableProcessedTableManager get structureId {
    final $_column = $_itemColumn<int>('structure_id')!;

    final manager = $$StructuresTableTableManager(
      $_db,
      $_db.structures,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_structureIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ConversationStructuresTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationStructuresTable> {
  $$ConversationStructuresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$GeneratedConversationsTableFilterComposer get conversationId {
    final $$GeneratedConversationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationId,
          referencedTable: $db.generatedConversations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GeneratedConversationsTableFilterComposer(
                $db: $db,
                $table: $db.generatedConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$StructuresTableFilterComposer get structureId {
    final $$StructuresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.structureId,
      referencedTable: $db.structures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StructuresTableFilterComposer(
            $db: $db,
            $table: $db.structures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationStructuresTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationStructuresTable> {
  $$ConversationStructuresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$GeneratedConversationsTableOrderingComposer get conversationId {
    final $$GeneratedConversationsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationId,
          referencedTable: $db.generatedConversations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GeneratedConversationsTableOrderingComposer(
                $db: $db,
                $table: $db.generatedConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$StructuresTableOrderingComposer get structureId {
    final $$StructuresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.structureId,
      referencedTable: $db.structures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StructuresTableOrderingComposer(
            $db: $db,
            $table: $db.structures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationStructuresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationStructuresTable> {
  $$ConversationStructuresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$GeneratedConversationsTableAnnotationComposer get conversationId {
    final $$GeneratedConversationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationId,
          referencedTable: $db.generatedConversations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GeneratedConversationsTableAnnotationComposer(
                $db: $db,
                $table: $db.generatedConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$StructuresTableAnnotationComposer get structureId {
    final $$StructuresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.structureId,
      referencedTable: $db.structures,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StructuresTableAnnotationComposer(
            $db: $db,
            $table: $db.structures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationStructuresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationStructuresTable,
          ConversationStructure,
          $$ConversationStructuresTableFilterComposer,
          $$ConversationStructuresTableOrderingComposer,
          $$ConversationStructuresTableAnnotationComposer,
          $$ConversationStructuresTableCreateCompanionBuilder,
          $$ConversationStructuresTableUpdateCompanionBuilder,
          (ConversationStructure, $$ConversationStructuresTableReferences),
          ConversationStructure,
          PrefetchHooks Function({bool conversationId, bool structureId})
        > {
  $$ConversationStructuresTableTableManager(
    _$AppDatabase db,
    $ConversationStructuresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationStructuresTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ConversationStructuresTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ConversationStructuresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> conversationId = const Value.absent(),
                Value<int> structureId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationStructuresCompanion(
                conversationId: conversationId,
                structureId: structureId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int conversationId,
                required int structureId,
                Value<int> rowid = const Value.absent(),
              }) => ConversationStructuresCompanion.insert(
                conversationId: conversationId,
                structureId: structureId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConversationStructuresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({conversationId = false, structureId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (conversationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.conversationId,
                                    referencedTable:
                                        $$ConversationStructuresTableReferences
                                            ._conversationIdTable(db),
                                    referencedColumn:
                                        $$ConversationStructuresTableReferences
                                            ._conversationIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (structureId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.structureId,
                                    referencedTable:
                                        $$ConversationStructuresTableReferences
                                            ._structureIdTable(db),
                                    referencedColumn:
                                        $$ConversationStructuresTableReferences
                                            ._structureIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ConversationStructuresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationStructuresTable,
      ConversationStructure,
      $$ConversationStructuresTableFilterComposer,
      $$ConversationStructuresTableOrderingComposer,
      $$ConversationStructuresTableAnnotationComposer,
      $$ConversationStructuresTableCreateCompanionBuilder,
      $$ConversationStructuresTableUpdateCompanionBuilder,
      (ConversationStructure, $$ConversationStructuresTableReferences),
      ConversationStructure,
      PrefetchHooks Function({bool conversationId, bool structureId})
    >;
typedef $$SrsCardsTableCreateCompanionBuilder =
    SrsCardsCompanion Function({
      Value<int> id,
      required SrsItemType itemType,
      required int itemId,
      Value<double> ease,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<int> lapses,
      Value<DateTime> dueAt,
      Value<DateTime?> lastReviewedAt,
    });
typedef $$SrsCardsTableUpdateCompanionBuilder =
    SrsCardsCompanion Function({
      Value<int> id,
      Value<SrsItemType> itemType,
      Value<int> itemId,
      Value<double> ease,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<int> lapses,
      Value<DateTime> dueAt,
      Value<DateTime?> lastReviewedAt,
    });

class $$SrsCardsTableFilterComposer
    extends Composer<_$AppDatabase, $SrsCardsTable> {
  $$SrsCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SrsItemType, SrsItemType, String>
  get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SrsCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $SrsCardsTable> {
  $$SrsCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SrsCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SrsCardsTable> {
  $$SrsCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SrsItemType, String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<double> get ease =>
      $composableBuilder(column: $table.ease, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );
}

class $$SrsCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SrsCardsTable,
          SrsCard,
          $$SrsCardsTableFilterComposer,
          $$SrsCardsTableOrderingComposer,
          $$SrsCardsTableAnnotationComposer,
          $$SrsCardsTableCreateCompanionBuilder,
          $$SrsCardsTableUpdateCompanionBuilder,
          (SrsCard, BaseReferences<_$AppDatabase, $SrsCardsTable, SrsCard>),
          SrsCard,
          PrefetchHooks Function()
        > {
  $$SrsCardsTableTableManager(_$AppDatabase db, $SrsCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SrsCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SrsCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SrsCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<SrsItemType> itemType = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<double> ease = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
              }) => SrsCardsCompanion(
                id: id,
                itemType: itemType,
                itemId: itemId,
                ease: ease,
                intervalDays: intervalDays,
                repetitions: repetitions,
                lapses: lapses,
                dueAt: dueAt,
                lastReviewedAt: lastReviewedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required SrsItemType itemType,
                required int itemId,
                Value<double> ease = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
              }) => SrsCardsCompanion.insert(
                id: id,
                itemType: itemType,
                itemId: itemId,
                ease: ease,
                intervalDays: intervalDays,
                repetitions: repetitions,
                lapses: lapses,
                dueAt: dueAt,
                lastReviewedAt: lastReviewedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SrsCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SrsCardsTable,
      SrsCard,
      $$SrsCardsTableFilterComposer,
      $$SrsCardsTableOrderingComposer,
      $$SrsCardsTableAnnotationComposer,
      $$SrsCardsTableCreateCompanionBuilder,
      $$SrsCardsTableUpdateCompanionBuilder,
      (SrsCard, BaseReferences<_$AppDatabase, $SrsCardsTable, SrsCard>),
      SrsCard,
      PrefetchHooks Function()
    >;
typedef $$GrammarGlueTableCreateCompanionBuilder =
    GrammarGlueCompanion Function({
      Value<int> id,
      required String surface,
      required GlueKind kind,
      Value<int?> importId,
      Value<DateTime> addedAt,
    });
typedef $$GrammarGlueTableUpdateCompanionBuilder =
    GrammarGlueCompanion Function({
      Value<int> id,
      Value<String> surface,
      Value<GlueKind> kind,
      Value<int?> importId,
      Value<DateTime> addedAt,
    });

final class $$GrammarGlueTableReferences
    extends BaseReferences<_$AppDatabase, $GrammarGlueTable, GrammarGlueData> {
  $$GrammarGlueTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ImportsTable _importIdTable(_$AppDatabase db) =>
      db.imports.createAlias('grammar_glue__import_id__imports__id');

  $$ImportsTableProcessedTableManager? get importId {
    final $_column = $_itemColumn<int>('import_id');
    if ($_column == null) return null;
    final manager = $$ImportsTableTableManager(
      $_db,
      $_db.imports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_importIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GrammarGlueTableFilterComposer
    extends Composer<_$AppDatabase, $GrammarGlueTable> {
  $$GrammarGlueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surface => $composableBuilder(
    column: $table.surface,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GlueKind, GlueKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ImportsTableFilterComposer get importId {
    final $$ImportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.imports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportsTableFilterComposer(
            $db: $db,
            $table: $db.imports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrammarGlueTableOrderingComposer
    extends Composer<_$AppDatabase, $GrammarGlueTable> {
  $$GrammarGlueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surface => $composableBuilder(
    column: $table.surface,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ImportsTableOrderingComposer get importId {
    final $$ImportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.imports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportsTableOrderingComposer(
            $db: $db,
            $table: $db.imports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrammarGlueTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrammarGlueTable> {
  $$GrammarGlueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surface =>
      $composableBuilder(column: $table.surface, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GlueKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$ImportsTableAnnotationComposer get importId {
    final $$ImportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.imports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportsTableAnnotationComposer(
            $db: $db,
            $table: $db.imports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrammarGlueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GrammarGlueTable,
          GrammarGlueData,
          $$GrammarGlueTableFilterComposer,
          $$GrammarGlueTableOrderingComposer,
          $$GrammarGlueTableAnnotationComposer,
          $$GrammarGlueTableCreateCompanionBuilder,
          $$GrammarGlueTableUpdateCompanionBuilder,
          (GrammarGlueData, $$GrammarGlueTableReferences),
          GrammarGlueData,
          PrefetchHooks Function({bool importId})
        > {
  $$GrammarGlueTableTableManager(_$AppDatabase db, $GrammarGlueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrammarGlueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrammarGlueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrammarGlueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> surface = const Value.absent(),
                Value<GlueKind> kind = const Value.absent(),
                Value<int?> importId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => GrammarGlueCompanion(
                id: id,
                surface: surface,
                kind: kind,
                importId: importId,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String surface,
                required GlueKind kind,
                Value<int?> importId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => GrammarGlueCompanion.insert(
                id: id,
                surface: surface,
                kind: kind,
                importId: importId,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GrammarGlueTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({importId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (importId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.importId,
                                referencedTable: $$GrammarGlueTableReferences
                                    ._importIdTable(db),
                                referencedColumn: $$GrammarGlueTableReferences
                                    ._importIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GrammarGlueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GrammarGlueTable,
      GrammarGlueData,
      $$GrammarGlueTableFilterComposer,
      $$GrammarGlueTableOrderingComposer,
      $$GrammarGlueTableAnnotationComposer,
      $$GrammarGlueTableCreateCompanionBuilder,
      $$GrammarGlueTableUpdateCompanionBuilder,
      (GrammarGlueData, $$GrammarGlueTableReferences),
      GrammarGlueData,
      PrefetchHooks Function({bool importId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ImportsTableTableManager get imports =>
      $$ImportsTableTableManager(_db, _db.imports);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$StructuresTableTableManager get structures =>
      $$StructuresTableTableManager(_db, _db.structures);
  $$SlotsTableTableManager get slots =>
      $$SlotsTableTableManager(_db, _db.slots);
  $$ExampleSentencesTableTableManager get exampleSentences =>
      $$ExampleSentencesTableTableManager(_db, _db.exampleSentences);
  $$GeneratedConversationsTableTableManager get generatedConversations =>
      $$GeneratedConversationsTableTableManager(
        _db,
        _db.generatedConversations,
      );
  $$ConversationWordsTableTableManager get conversationWords =>
      $$ConversationWordsTableTableManager(_db, _db.conversationWords);
  $$ConversationStructuresTableTableManager get conversationStructures =>
      $$ConversationStructuresTableTableManager(
        _db,
        _db.conversationStructures,
      );
  $$SrsCardsTableTableManager get srsCards =>
      $$SrsCardsTableTableManager(_db, _db.srsCards);
  $$GrammarGlueTableTableManager get grammarGlue =>
      $$GrammarGlueTableTableManager(_db, _db.grammarGlue);
}
