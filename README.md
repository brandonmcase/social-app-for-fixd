# Social App for Fixd

[![CI](https://github.com/brandoncase/social-app-for-fixd/workflows/CI/badge.svg)](https://github.com/brandoncase/social-app-for-fixd/actions/workflows/ci.yml)
[![Tests](https://github.com/brandoncase/social-app-for-fixd/workflows/Tests/badge.svg)](https://github.com/brandoncase/social-app-for-fixd/actions/workflows/test.yml)
[![Security](https://github.com/brandoncase/social-app-for-fixd/workflows/Security%20Scan/badge.svg)](https://github.com/brandoncase/social-app-for-fixd/actions/workflows/security.yml)
[![Quality](https://github.com/brandoncase/social-app-for-fixd/workflows/Code%20Quality/badge.svg)](https://github.com/brandoncase/social-app-for-fixd/actions/workflows/quality.yml)

A Rails API-only application for social media functionality with user authentication, post management, and rating system.

## Features

### 🔐 Authentication
- User registration and login
- JWT token-based authentication
- Password validation and security
- User profile management

### 📝 Posts
- Create, read, update, and delete posts
- Soft deletion (posts are archived, not permanently deleted)
- View count tracking
- Rich metadata support (JSONB fields)
- Pagination support
- User authorization (users can only modify their own posts)

### ⭐ Rating System
- 1-5 star rating system for posts
- One rating per user per post (uniqueness constraint)
- Real-time average rating and count updates
- Multi-user rating support
- Cached statistics for performance

### 📊 API Documentation
- Complete Swagger/OpenAPI 3.0 documentation
- Interactive API testing interface
- Comprehensive endpoint documentation
- Request/response examples

### 🧪 Testing
- Comprehensive RSpec test suite
- Model, controller, and integration tests
- FactoryBot for test data generation
- Shoulda-matchers for validation testing
- 314+ test examples with 100% pass rate
- 80%+ code coverage with SimpleCov

### 🚀 CI/CD
- GitHub Actions workflows for automated testing
- Code quality checks with RuboCop
- Security scanning with Brakeman and Bundle Audit
- Coverage validation for changed files (70% minimum)
- Automated PR comments with coverage reports

## Tech Stack

- **Ruby**: 3.4.4
- **Rails**: 8.0.2.1
- **Database**: PostgreSQL
- **Authentication**: Devise + JWT
- **Authorization**: CanCanCan
- **Testing**: RSpec, FactoryBot, Shoulda-matchers
- **Documentation**: Swagger/OpenAPI 3.0
- **Pagination**: Kaminari

## CI/CD Pipeline

This project uses GitHub Actions for continuous integration and deployment. The CI/CD pipeline includes:

### Workflows

1. **CI Workflow** (`.github/workflows/ci.yml`)
   - Runs on push and pull requests to main/develop branches
   - Sets up PostgreSQL and Redis services
   - Runs RuboCop for code style checking
   - Executes full RSpec test suite with coverage
   - Validates 70% minimum coverage for changed files
   - Posts coverage reports as PR comments
   - Uploads coverage data to Codecov

2. **Test Workflow** (`.github/workflows/test.yml`)
   - Simplified test runner for quick feedback
   - Runs RSpec tests with and without coverage
   - Uploads coverage reports as artifacts

3. **Security Workflow** (`.github/workflows/security.yml`)
   - Runs Brakeman for security vulnerability scanning
   - Performs Bundle Audit for gem vulnerabilities
   - Scheduled weekly security scans
   - Uploads security reports as artifacts

4. **Quality Workflow** (`.github/workflows/quality.yml`)
   - Code quality checks with RuboCop
   - Scans for TODO/FIXME comments
   - Detects debug statements (puts, p, binding.pry)
   - Uploads quality reports as artifacts

### Coverage Requirements

- **Minimum Coverage**: 70% for all changed Ruby files in `app/` directory
- **Coverage Tool**: SimpleCov with Rails configuration
- **Coverage Reports**: Generated in HTML format and uploaded as artifacts
- **PR Comments**: Automated coverage reports posted on pull requests

### Quality Gates

The CI pipeline will fail if:
- Any RSpec tests fail
- RuboCop style violations are found
- Changed files have less than 70% test coverage
- Security vulnerabilities are detected
- Debug statements are found in production code

### Local Development

To run the same checks locally:

```bash
# Run tests with coverage
COVERAGE=true bundle exec rspec

# Run RuboCop
bundle exec rubocop

# Run security scan
bundle exec brakeman

# Run bundle audit
bundle exec bundle audit
```

## Getting Started

### Prerequisites

- Ruby 3.4.4
- PostgreSQL
- Bundler

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd social-app-for-fixd
```

2. Install dependencies:
```bash
bundle install
```

3. Set up the database:
```bash
rails db:create
rails db:migrate
rails db:seed
```

4. Start the server:
```bash
rails server
```

The API will be available at `http://localhost:3000`

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register a new user
- `POST /api/v1/auth/sign_in` - Sign in user and get JWT token
- `DELETE /api/v1/auth/sign_out` - Sign out user
- `GET /api/v1/auth/me` - Get current user info

### Timeline
- `GET /api/v1/timeline` - Get activity timeline of recent posts from all users
  - Supports pagination (`page`, `per_page`)
  - Supports filtering by minimum average rating (`min_rating`)
  - Sorted by creation time (newest first)
  - Includes post author information, average rating, and rating count

### Posts
- `GET /api/v1/posts` - List all posts (paginated)
- `POST /api/v1/posts` - Create a new post
- `GET /api/v1/posts/:id` - Get a specific post
- `PATCH /api/v1/posts/:id` - Update a post
- `DELETE /api/v1/posts/:id` - Soft delete a post

### Ratings
- `GET /api/v1/posts/:post_id/rating` - Get user's rating for a post
- `POST /api/v1/posts/:post_id/rating` - Create a rating for a post
- `PATCH /api/v1/posts/:post_id/rating` - Update user's rating for a post
- `DELETE /api/v1/posts/:post_id/rating` - Delete user's rating for a post

## API Documentation

### Interactive Documentation
Visit `http://localhost:3000/api-docs/` for the Swagger UI interface where you can:
- Browse all available endpoints
- View request/response schemas
- Test API endpoints directly from the browser
- View example requests and responses

### OpenAPI Specification
Direct access to the OpenAPI spec: `http://localhost:3000/api-docs/swagger.yaml`

## Authentication

The API uses JWT tokens for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

Real JWT tokens are generated upon successful login/registration and contain user information.
Tokens expire after 24 hours and must be included in the Authorization header.

To get a token, first register or sign in:
```bash
# Register a new user
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"user": {"email": "test@example.com", "username": "testuser", "password": "password123", "password_confirmation": "password123"}}'

# Sign in
curl -X POST http://localhost:3000/api/v1/auth/sign_in \
  -H "Content-Type: application/json" \
  -d '{"user": {"email": "test@example.com", "password": "password123"}}'
```

Both endpoints will return a JWT token in the response that you can use for subsequent API calls.

## Testing

### Running Tests
```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/
bundle exec rspec spec/controllers/

# Run with documentation format
bundle exec rspec --format documentation
```

### Test Coverage
- **Rating Model**: Validations, associations, callbacks, statistics updates
- **Rating Controller**: Full CRUD operations with authentication/authorization
- **Post Model**: Associations, validations, rating integration
- **Post Controller**: CRUD operations, rating data in responses
- **Authentication**: JWT token validation and user management
- **Error Handling**: Comprehensive 401, 403, 404, 422 response testing

### Test Results
- 107+ examples, 0 failures
- Comprehensive coverage of happy paths and edge cases
- Proper error handling and validation testing

## Database Schema

### Users
- `id` (Primary Key)
- `email` (Unique)
- `username` (Unique)
- `encrypted_password`
- `created_at`, `updated_at`

### Posts
- `id` (Primary Key)
- `user_id` (Foreign Key)
- `title` (String, max 100 chars)
- `body` (Text, max 1000 chars)
- `deleted_at` (Timestamp for soft deletion)
- `view_count` (Integer, default 0)
- `metadata` (JSONB)
- `jsonb` (JSONB for additional data)
- `average_rating` (Decimal, cached from ratings)
- `rating_count` (Integer, cached from ratings)
- `created_at`, `updated_at`

### Ratings
- `id` (Primary Key)
- `user_id` (Foreign Key)
- `post_id` (Foreign Key)
- `rating` (Integer, 1-5)
- `created_at`, `updated_at`
- Unique constraint on `user_id` and `post_id`

## Development

### Code Quality
- RuboCop for code style enforcement
- RSpec for testing
- FactoryBot for test data
- Shoulda-matchers for model testing

### Key Features Implementation
- **Soft Deletion**: Posts use `deleted_at` timestamp instead of permanent deletion
- **Cached Statistics**: Post ratings are cached for performance
- **Real-time Updates**: Rating changes automatically update post statistics
- **User Isolation**: Users can only access/modify their own data
- **Comprehensive Error Handling**: Proper HTTP status codes and error messages

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License.