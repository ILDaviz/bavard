/// Marks a Model class for code generation.
///
/// Triggers generation of the `.g.dart` part file containing type-safe attribute accessors
/// and mass-assignment logic via [GuardsAttributes.fill].
const fillable = Fillable();

class Fillable {
  const Fillable();
}

/// Marks a Pivot class for code generation.
///
/// Triggers generation of:
/// 1. Strongly typed getters/setters for columns defined as static consts.
/// 2. A static `schema` list containing all defined columns.
class BavardPivot {
  const BavardPivot();
}