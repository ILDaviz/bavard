# Lifecycle Hooks

Lifecycle hooks allow you to hook into specific points in the model's life cycle.

## Available Hooks

- `onSaving()`: Before save (create or update). Return `false` to cancel.
- `onSaved()`: After save.
- `onDeleting()`: Before delete. Return `false` to cancel.
- `onDeleted()`: After delete.

## Example

```dart
class User extends Model {
  @override
  Future<bool> onSaving() async {
    // Validate
    if (attributes['email'] == null) {
      return false; // Cancel save
    }
    
    // Mutate
    attributes['name'] = attributes['name'].toString().toUpperCase();
    
    return true; // Proceed
  }

  @override
  Future<void> onSaved() async {
    print('User ${id} was saved!');
  }
}
```
