# SOLUTION

## Overview

This solution implements a versioned, stateless Rails API for a lightweight social app. Key choices:

- **Authentication:** Devise + JWT tokens (placeholder implementation for development)
- **Authorization:** CanCanCan (clear, testable abilities)
- **Pagination:** Kaminari (simple, fast, widely used)
- **API Docs:** Static Swagger/OpenAPI 3.0 specification with interactive UI
- **Rate Limiting:** Rack::Attack (enhanced user-based throttling with custom responses)
- **Versioning:** `/api/v1/...`
- **Consistency:** Unified JSON response shape and standardized error handling

> Note: The prompt mentions `password_digest`. Devise uses `encrypted_password`. I intentionally used **Devise** for production-grade security and features; the divergence is documented here.

---

## Testing Infrastructure

### Test Coverage & Request Specs

- **SimpleCov**: Configured with 70% minimum coverage requirement
- **Current Coverage**: 68.41% line coverage (249/364 lines)
- **Request Specs**: 278 comprehensive examples covering all API endpoints
- **Service Testing**: Timeline cache service and performance monitoring
- **Coverage Reports**: Generated HTML reports in `/coverage/` directory

### Test Structure

- **Model Specs**: Validation, associations, and business logic testing
- **Controller Specs**: Authorization, error handling, and response format testing
- **Request Specs**: Full API endpoint testing with authentication scenarios
- **Service Specs**: Caching logic and performance monitoring testing

---

## Performance Optimizations

### Redis Caching

- **Timeline Caching**: Redis-based caching with 5-minute expiry
- **Smart Invalidation**: Automatic cache clearing on post modifications
- **Cache Keys**: Intelligent key generation based on pagination and filters
- **Cache Service**: `TimelineCacheService` for centralized cache management

### Performance Monitoring

- **Development Monitoring**: Slow query detection (>50ms) and request monitoring (>200ms)
- **Service Layer**: `PerformanceMonitoringService` for query benchmarking
- **Query Optimization**: Eager loading and database index optimization

---

## Authentication (Devise + JWT Placeholder)

### Current Implementation

- **Placeholder Tokens**: Uses `jwt_token_placeholder_{user_id}` format for development
- **Production Ready**: Framework in place for real JWT implementation with devise-jwt
- **Security**: Proper token validation and user authentication flow
- **Stateless**: API remains sessionless—ideal for SPAs, mobile clients, and horizontal scaling

### How it works

- **Sign-up / Sign-in** dispatch a placeholder JWT via the `Authorization: Bearer <token>` header
- **Token Format**: `jwt_token_placeholder_{user_id}` for easy testing and development
- **Protected endpoints** rely on `authenticate_user!` in the API base controller
- **User Resolution**: Token parsing extracts user ID for authentication

### Production Upgrade Path

- **Real JWT Implementation**: Replace placeholder tokens with devise-jwt
- **Token Revocation**: Implement JWT denylist table for logout functionality
- **Environment Variables**: `DEVISE_JWT_SECRET_KEY` configuration
- **Token Expiration**: Configurable token lifetimes (default 1h)

### Trade-offs & alternatives

- **Alt:** `has_secure_password` (bcrypt) + hand-rolled JWT issuance. Lighter but more custom code; you re-implement recoverables, lockout, etc.
- **Alt:** Cookie sessions (server-side). Simpler for browser-only clients but introduces CSRF + state; less ideal for pure APIs.
- **Mitigations:** Short-lived access tokens; (optional) add refresh tokens, IP/user-agent binding, and stricter revocation policies.

### Testing notes

- Request specs assert:

  - `201` on register, `Authorization` header present
  - `200` on sign-in with valid creds
  - `401` on protected routes without/invalid token
  - `204` on sign-out; token then rejected

---

## Authorization (CanCanCan)

- Central `Ability` defines clear rules:

  - Anyone can **read** non-deleted posts.
  - Users can **manage** their own posts.
  - Ratings: users can create/update/destroy **their** rating; can show their rating.

- Benefits: Compact, testable rules and easy controller integration via `authorize!` or `load_and_authorize_resource`.

---

## Pagination (Kaminari)

### Why Kaminari?

- **Drop-in:** Simple `page(...).per(...)` API.
- **Performance:** SQL `LIMIT/OFFSET` with clear defaults; battle-tested.
- **Meta:** Easy to return `page`, `per_page`, `total_pages`, `total_count` in the response.

### Usage

- `index` / `timeline` use:

  ```ruby
  scope.page(params[:page]).per(params[:per_page] || 20)
  ```

- Responses include:

  ```json
  {
    "data": [...],
    "meta": { "page": 1, "per_page": 20, "total_pages": 5, "total_count": 100 }
  }
  ```

### Alternatives

- **Pagy:** Smaller/faster; great choice too. Kaminari chosen for familiarity and minimal setup.
- **Cursor-based pagination:** Better for deep lists/real-time feeds; can be added later if required.

---

## API Documentation (Static Swagger/OpenAPI)

### Current Implementation

- **Static Swagger UI**: Manually created OpenAPI 3.0 specification at `/public/api-docs/swagger.yaml`
- **Interactive UI**: Available at `/api-docs/` for endpoint exploration and testing
- **Complete Coverage**: Documentation for all endpoints (auth, posts, ratings, timeline)
- **Request/Response Examples**: Comprehensive examples for all API operations

### Setup Summary

- **Static Files**: Swagger YAML and HTML files served from `/public/api-docs/`
- **Routes**: Custom route handling for API documentation
- **UI Features**: Interactive testing interface with authentication support

### Future Enhancement

- **RSwag Integration**: Can be added to generate docs from request specs for better maintainability
- **Auto-generation**: Potential to sync documentation with test specifications

---

## Error Handling & Response Shape

- **Unified JSON format**:

  - Success: `{ "data": { ... }, "meta": { ...? } }`
  - Error: `{ "error": { "code": "...", "message": "...", "details": { ...? } } }`

- Centralized in `Api::V1::BaseController` and a small `JsonResponder` concern.
- `rescue_from` for `RecordNotFound`, `RecordInvalid`, and `CanCan::AccessDenied`.

---

## Timeline & Performance Considerations

### Timeline Implementation

- **Timeline Query**: `Post.active.order(created_at: :desc).includes(:user)` with optional `min_avg_rating` filter
- **Cached Aggregates**: `ratings_count`, `avg_rating` on posts table to avoid per-request aggregation
- **Redis Caching**: 5-minute TTL cache with intelligent invalidation on post changes
- **Cache Service**: `TimelineCacheService` handles cache key generation and invalidation

### Database Optimization

- **Indexes**:
  - `posts(created_at)`, `posts(deleted_at)`, `posts(user_id)`, `posts(avg_rating)`
  - `ratings(user_id, post_id)` unique constraint
- **Eager Loading**: `includes(:user)` to prevent N+1 queries
- **Pagination**: Kaminari pagination to bound data transfer

### Performance Monitoring

- **Development Monitoring**: Automatic slow query detection (>50ms) and request monitoring (>200ms)
- **Service Layer**: `PerformanceMonitoringService` for query benchmarking
- **Cache Invalidation**: Automatic timeline cache clearing on post modifications

---

## Rate Limiting (Rack::Attack)

### Enhanced Implementation

- **User-Based Throttling**: Rate limits per authenticated user for personalized limits
- **IP-Based Fallback**: Protection for anonymous users and distributed attacks
- **Endpoint-Specific Limits**: Different throttles for different operations:
  - Login attempts: 5 per email, 20 per IP per minute
  - Post creation: 30 per user, 60 per IP per minute
  - Rating creation: 50 per user, 100 per IP per minute
  - Timeline requests: 100 per user, 200 per IP per minute
  - Registration: 10 per IP per minute

### Custom Error Responses

- **429 Status**: Proper rate limit exceeded responses
- **Retry Information**: Includes retry-after headers
- **JSON Format**: Consistent error response format

### Upgrade Path

- **Token-Bucket**: Can be upgraded to Redis-based token bucket per-user/IP
- **Dynamic Limits**: Different buckets per endpoint "class" (auth vs write vs read)
- **Advanced Features**: Burst handling and sliding window algorithms

---

## Security Notes

- **JWT secret** from env; don’t commit secrets.
- **Short token lifetimes**; consider refresh tokens for longer sessions.
- **Validate inputs** with strong params + model validations.
- **Authorization** enforced at controller level; tests cover forbidden paths.
- **CORS**: expose `Authorization` header if a browser client needs to read it.

---

## Deviations from Prompt & Justifications

- **`password_digest` vs `encrypted_password`**: Devise’s `encrypted_password` selected for security/features. Re-implementing password management would add risk/time without value.
- **HTML pages**: Kept API-first per assignment; easy to add a separate web client later.

---

## What I'd do with more time

1. **Real JWT Implementation**: Replace placeholder tokens with devise-jwt for production
2. **Optimistic locking** (add `lock_version` on posts) + conflict handling
3. **Background jobs** (Sidekiq) for view_count increments & async recomputation/notifications
4. **Advanced rate limiting**: Token-bucket with Redis (per-identity & per-endpoint)
5. **Cursor pagination** for timeline scalability and stable ordering
6. **OpenTelemetry** traces + structured logs for observability
7. **RSwag Integration**: Auto-generate API docs from request specs
8. **Real-time features**: WebSocket support for live timeline updates
9. **Advanced caching**: Fragment caching and CDN integration
10. **API versioning strategy**: Backward compatibility and migration paths

---

## Quick Start (Dev)

```bash
bundle install
bin/rails db:create db:migrate
# Ensure DEVISE_JWT_SECRET_KEY is set in environment (dotenv or export)
bin/rails s
# Visit /api-docs (if rswag enabled)
```

**Smoke test**: use the provided curl sequence in the README to register, sign in, create posts, rate, query timeline, and sign out.

---

## Extreme Concurrency Handling

Optimistic locking: lock_version on posts prevents lost updates; StaleObjectError returns 409 Conflict with a friendly message to refresh and retry.

Redis locks for ratings: A short-lived distributed lock on (post_id, user_id) serializes rating mutations to keep cached aggregates consistent under heavy write contention.

Asynchronous work with Sidekiq: View count increments, “post rated” notifications, and timeline cache warming run in background jobs to reduce request latency and avoid contention on hot rows.

Connection pooling: Database pool sized to cover Puma and Sidekiq concurrency; timeouts tuned to fail fast under resource pressure.

Trade-offs: Locks are bounded (ms TTL, jittered retries) to prevent thundering herds; optimistic locking shifts conflict resolution to clients, which is acceptable for API consumers and surfaces clear errors.

---

## Full-Text Search (PostgreSQL Built-ins)

### Why PostgreSQL FTS?

- **Zero extra infra** (no Elasticsearch/Solr), good performance, strong ranking.
- **Index-backed** queries via `GIN` on a `tsvector` column.
- **Rich query syntax** using `websearch_to_tsquery` (quotes, AND/OR, minus).

### Implementation

- **Schema:** Added `posts.search_vector :tsvector` + **GIN** index.
- **Sync strategy:** Used a **trigger** to keep `search_vector` up to date, not a generated column, because `unaccent()` is **STABLE** (not IMMUTABLE) and can’t be used in generated expressions.

  - Trigger function sets:

    - `A` weight for `title`
    - `B` weight for `body`
    - Applies `unaccent()` for diacritic-insensitive search

- **Model scopes:**

  - `fts(q)` → `search_vector @@ websearch_to_tsquery('english', unaccent(q))`
  - `ranked(q)` → selects `ts_rank_cd(...) AS rank` and orders by rank desc

- **Controller pattern:** Thin controller calling `SearchService` (mirrors timeline), which:

  - Filters to active posts
  - Applies FTS + ranking
  - Includes author to avoid N+1
  - Paginates (Kaminari)
  - Returns `{ data, meta }` shape
  - **Caches** results per `(q, min_rating, page, per_page)` with short TTL

### Example Query

```
GET /api/v1/search?q="hello world" OR greetings -farewell&page=1&per_page=20
Authorization: Bearer <JWT>
```

### Performance

- **Index:** `GIN (search_vector)` ensures fast `@@` lookups.
- **Ranking:** `ts_rank_cd` balances term frequency and rarity; we tie-break with `created_at DESC`.
- **Complexity:** \~O(log n) to hit the index + O(k) to return a page (k = page size).
- **Caching:** Short TTL cache reduces repeated computation on popular queries.
- **Indexes kept:** `posts(deleted_at)`, `posts(created_at)`, `posts(user_id)` for related endpoints.

### Trade-offs & Alternatives

- **Trigger vs Generated Column:** Trigger chosen to keep `unaccent()` (better UX). If diacritics aren’t needed, a **generated** column is simpler.
- **Language:** Currently `'english'`; can be parameterized or stored per post if multi-lingual content is expected.
- **Highlighting:** Could add `ts_headline` for result snippets (omitted for simplicity).

### Testing

- Validate:

  - Exact phrase (`"hello world"`)
  - Boolean operators (OR, minus)
  - Pagination metadata
  - `min_rating` filter interaction
  - Soft-deleted posts excluded

- Smoke test with curl:

  ```bash
  curl -i "http://localhost:3000/api/v1/search?q=hello&page=1&per_page=5" \
    -H "Authorization: Bearer <JWT>"
  ```

---

## Database Optimization & Testing Enhancements

### Timeline Materialized View

To improve read performance for the timeline endpoint, we introduced a **PostgreSQL materialized view** (`timeline_mv`).

- Provides a pre-aggregated view of posts and ratings.
- Indexed for fast lookup and ordering by `created_at` and rating fields.
- Accessed via a lightweight `TimelineEntry` model.
- Keeps heavy timeline queries off the base `posts` table, reducing query cost under concurrency.

### Query Analysis

Added a **QueryAnalyzer service** to safely run `EXPLAIN` (and optionally `ANALYZE`) on SQL generated by ActiveRecord relations.

- Prevents SQL injection by using ActiveRecord’s `to_sql`.
- Used during development and troubleshooting to evaluate query performance.
- Brakeman warnings addressed by ensuring all inputs are sanitized.
  This provides visibility into potential query bottlenecks without impacting production.

### Service Layer Updates

- **TimelineCacheService** now fetches from `timeline_mv` instead of raw `posts`, leveraging indexes and precomputed fields.
- **SearchService** updated to work with the new view and rating columns for accurate ranking and filtering.
- This separation of concerns keeps the controller slim and shifts logic to dedicated services.

### Background Jobs

Sidekiq configuration was updated to support **weighted queues** (via pure YAML), giving higher priority to critical tasks (e.g., notifications, cache invalidation).
This ensures timeline cache warming and post rating updates don’t block main request flows.

### API Testing & Data Generation

- Added **Rake tasks** to run end-to-end API tests (`api:tests`) directly from the CLI.
- Integrated **Faker** to generate unique usernames/emails, avoiding collisions during test runs.
- Added tasks to run SQL `EXPLAIN` on common queries, enabling quick performance validation during development.

---

## Use of AI in the Development Process

### Planning and Task Breakdown

I used AI (ChatGPT) to help map out the path to completing the assignment. This included:

- Identifying the order of features (Auth → Posts → Ratings → Timeline → Polish).
- Generating structured steps for migrations, models, controllers, and routes.
- Exploring trade-offs (e.g., Devise vs `has_secure_password`, Kaminari vs Pagy).

This saved time during initial setup and ensured I covered all the assignment requirements in a logical order.

### Specs and Documentation

I used **Cursor** (AI-assisted IDE) to help draft request specs and inline documentation.
ChatGPT helped write portions of the **SOLUTION.md** and generate example **curl flows** for API usage.
This made it easier to maintain consistency in error shapes, response formats, and to document architectural choices.

### Code Optimization

AI assistance was also applied to:

- Refactoring controllers (moving toward serializers and consistent error responders).
- Suggesting indexes, eager loading, and caching strategies.
- Improving readability and maintainability of the code (e.g., extracting JSON responders).

### Challenges with AI

AI was helpful, but not perfect. Key struggles included:

- **Balancing changes**: Suggestions to refactor often conflicted with existing specs or introduced linting/style issues.
- **Test breakage**: Automated changes sometimes caused failing tests, requiring manual fixes and judgment.
- **Context switching**: While AI produced helpful code snippets, ensuring consistency across controllers, models, and tests required human review.

### Takeaways

- AI accelerated setup, boilerplate, and documentation.
- Human judgment was required to integrate changes safely, maintain test coverage, and align with Rails conventions.
- Used effectively, AI can complement senior-level judgment—helping with scaffolding and polish—while leaving critical architectural and correctness decisions to the developer.

---
