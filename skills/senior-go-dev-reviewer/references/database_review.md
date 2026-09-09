# Database and Persistence Review

Read this when a Go change under review touches a database or persistence layer.

For PostgreSQL and pgvector systems:

- Context-aware DB calls
- No unbounded queries
- Proper index usage
- Explicit transactions
- Avoid N+1 queries
- Validate migrations are idempotent
- Ensure connection pool sizing is explicit

For ORMs (e.g., GORM):

- Avoid global DB instances
- Use explicit transactions
- Avoid silent query failures
- Disable implicit auto-migration in production
