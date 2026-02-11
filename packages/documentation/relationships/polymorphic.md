# Polymorphic Relationships

A polymorphic relationship allows the target model to belong to more than one type of model using a single association.

## MorphOne & MorphMany

Imagine an application where both `Post` and `Video` models can have `Comment`s.

### Table Structure

```
posts
    id - integer
    title - string

videos
    id - integer
    title - string

comments
    id - integer
    body - string
    commentable_id - integer
    commentable_type - string
```

### Defining the Relationship

**Parent Models:**
```dart
class Post extends Model {
  MorphMany<Comment> comments() => morphMany(Comment.new, 'commentable');
}

class Video extends Model {
  MorphMany<Comment> comments() => morphMany(Comment.new, 'commentable');
}
```

**Child Model (Inverse):**
```dart
class Comment extends Model {
  MorphTo<Model> commentable() => morphToTyped('commentable', {
    'posts': Post.new,
    'videos': Video.new,
  });
}
```

**Note:** In the `MorphTo` definition, you must provide a map connecting the table names (stored in `commentable_type`) to the Model factories.

## MorphToMany

A many-to-many polymorphic relation allows a model to belong to many other models of different types via a pivot table. A common example is `Tag`s that can be applied to `Post`s and `Video`s.

### Table Structure

```
posts
    id - integer
    title - string

videos
    id - integer
    title - string

tags
    id - integer
    name - string

taggables (pivot table)
    tag_id - integer
    taggable_id - integer
    taggable_type - string
```

### Defining the Relationship

**Inverse (Tag):**
```dart
class Tag extends Model {
  MorphToMany<Post> posts() => morphToMany(Post.new, 'taggable');
  MorphToMany<Video> videos() => morphToMany(Video.new, 'taggable');
}
```

**Owning Side:**
```dart
class Post extends Model {
  MorphToMany<Tag> tags() => morphToMany(Tag.new, 'taggable');
}
```
