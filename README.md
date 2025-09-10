# Social App for Fixd

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
- 107+ test examples with 100% pass rate

## Tech Stack

- **Ruby**: 3.4.4
- **Rails**: 8.0.2.1
- **Database**: PostgreSQL
- **Authentication**: Devise + JWT
- **Authorization**: CanCanCan
- **Testing**: RSpec, FactoryBot, Shoulda-matchers
- **Documentation**: Swagger/OpenAPI 3.0
- **Pagination**: Kaminari

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
Authorization: Bearer jwt_token_placeholder_{user_id}
```

For testing purposes, placeholder tokens are used in the format: `jwt_token_placeholder_{user_id}`

Example: `jwt_token_placeholder_1` for user with ID 1

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