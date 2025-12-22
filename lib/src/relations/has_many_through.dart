import 'relation.dart';
import '../core/utils.dart';
import '../core/model.dart';

/// Defines a distant one-to-many relationship linking a Parent to a Target via an Intermediate model.
///
/// e.g. A `Country` has many `Post`s through `User`:
/// Country (Parent) -> User (Intermediate, holds `country_id`) -> Post (Target, holds `user_id`).
class HasManyThrough<R extends Model, I extends Model> extends Relation<R> {
  final I Function(Map<String, dynamic>) intermediateCreator;

  /// Foreign key on the Intermediate table pointing to the Parent.
  final String? firstKey;

  /// Foreign key on the Target table pointing to the Intermediate model.
  final String? secondKey;

  HasManyThrough(
    super.parent,
    super.creator,
    this.intermediateCreator,
    this.firstKey,
    this.secondKey,
  ) {
    addConstraints();
  }

  // --- Internal Helpers for Key Resolution ---

  String get _intermediateTable => intermediateCreator({}).table;

  /// Resolves the foreign key pointing to Parent, defaulting to snake_case convention if null.
  String get _firstKey => firstKey ?? Utils.foreignKey(parent.table);

  /// Resolves the foreign key pointing to Intermediate, defaulting to snake_case convention if null.
  String get _secondKey => secondKey ?? Utils.foreignKey(_intermediateTable);

  /// Configures the query for a single parent instance.
  ///
  /// Performs an INNER JOIN between the Target and Intermediate tables (`target.second_key = intermediate.id`)
  /// so that results can be filtered by the Parent's ID (`intermediate.first_key = parent.id`).
  @override
  void addConstraints() {
    join(
      _intermediateTable,
      '$_intermediateTable.id',
      '=',
      '$table.$_secondKey',
    );
    where('$_intermediateTable.$_firstKey', parent.id);
  }

  /// Eagerly loads relationships for a list of parents to avoid N+1 queries.
  ///
  @override
  Future<void> match(
    List<Model> models,
    String relationName, {
    List<String> nested = const [],
  }) async {
    final parentIds = getKeys(models, parent.primaryKey);

    final intermediateResults = await intermediateCreator(
      {},
    ).newQuery().select(['id', _firstKey]).whereIn(_firstKey, parentIds).get();

    final intermediateMap = {
      for (var r in intermediateResults)
        normKey(r.id): normKey(r.attributes[_firstKey]),
    };

    final intermediateIds = intermediateMap.keys.whereType<String>().toList();
    if (intermediateIds.isEmpty) return;

    final targets =
        (await creator({})
            .newQuery()
            .withRelations(nested)
            .whereIn(_secondKey, intermediateIds)
            .get()).cast<R>();

    for (var model in models) {
      final myParentId = normKey(model.id);

      final relevantIntermediateIds = intermediateMap.entries
          .where((e) => e.value == myParentId)
          .map((e) => e.key)
          .toSet();

      model.relations[relationName] = targets
          .where(
            (t) => relevantIntermediateIds.contains(
              normKey(t.attributes[_secondKey]),
            ),
          )
          .toList();
    }
  }
}
