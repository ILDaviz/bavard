# Best Practices

1. **Follow Conventions**: Stick to plural table names, `id` primary keys, and snake_case columns. It saves configuration time.
2. **Use Code Generation**: The `@fillable` annotation provides type safety, which prevents runtime casting errors and makes refactoring easier.
3. **Eager Load Relationships**: Always use `withRelations` when iterating over a list of models to avoid N+1 query performance issues.
4. **Guard Your Models**: Always define `fillable` or `guarded` to prevent mass-assignment vulnerabilities.
5. **Use Transactions**: Wrap related operations (e.g., creating a user and their profile) in a transaction to ensure data consistency.
6. **Keep Models Thin**: Move complex business logic to Service classes, keeping Models focused on data definition and relationships.
7. **Use Scopes**: Use Global Scopes for cross-cutting concerns like Multi-Tenancy or Soft Deletes instead of manually adding `where` clauses everywhere.
