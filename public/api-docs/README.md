# API Documentation

This directory contains the API documentation for the Social App for Fixd.

## Files

- `index.html` - Swagger UI interface for browsing the API
- `swagger.yaml` - OpenAPI 3.0 specification file

## Accessing the Documentation

### Web Interface
Visit: http://localhost:3000/api-docs/

The Swagger UI provides an interactive interface where you can:
- Browse all available endpoints
- View request/response schemas
- Test API endpoints directly from the browser
- View example requests and responses

### API Specification
Direct access to the OpenAPI spec: http://localhost:3000/api-docs/swagger.yaml

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register a new user
- `POST /api/v1/auth/sign_in` - Sign in user and get JWT token
- `DELETE /api/v1/auth/sign_out` - Sign out user
- `GET /api/v1/auth/me` - Get current user info (requires authentication)

### Posts
- `GET /api/v1/posts` - List all active posts with pagination (requires authentication)
- `POST /api/v1/posts` - Create a new post (requires authentication)
- `GET /api/v1/posts/:id` - Get a specific post and increment view count (requires authentication)
- `PATCH /api/v1/posts/:id` - Update a post (requires authentication, owner only)
- `DELETE /api/v1/posts/:id` - Soft delete a post (requires authentication, owner only)

#### Post Features
- **Soft Deletion**: Posts are soft deleted (deleted_at timestamp set) rather than permanently removed
- **View Counting**: View count automatically increments when a post is accessed
- **Authorization**: Users can only update/delete their own posts
- **Pagination**: Post listing supports page and per_page parameters
- **Rich Data**: Posts include metadata, jsonb fields, and rating information
- **Rating Integration**: Posts display average_rating and rating_count from user ratings

### Ratings
- `GET /api/v1/posts/:post_id/rating` - Get user's rating for a post (requires authentication)
- `POST /api/v1/posts/:post_id/rating` - Create a rating for a post (requires authentication)
- `PATCH /api/v1/posts/:post_id/rating` - Update user's rating for a post (requires authentication)
- `DELETE /api/v1/posts/:post_id/rating` - Delete user's rating for a post (requires authentication)

#### Rating Features
- **Star Rating**: 1-5 star rating system with validation
- **User Uniqueness**: Each user can only rate a post once (database constraint)
- **Real-time Updates**: Post statistics (average_rating, rating_count) update automatically
- **User Isolation**: Users can only see/modify their own ratings
- **Multi-user Support**: Multiple users can rate the same post
- **Cached Statistics**: Post responses include aggregated rating data

## Authentication

The API uses JWT tokens for authentication. For testing purposes, placeholder tokens are used in the format:
`jwt_token_placeholder_{user_id}`

Example: `jwt_token_placeholder_1` for user with ID 1

## Testing the API

You can test the API endpoints directly from the Swagger UI interface, or using curl commands:

```bash
# Register a new user
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com","username":"testuser","password":"password123","password_confirmation":"password123"}}'

# Sign in
curl -X POST http://localhost:3000/api/v1/auth/sign_in \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com","password":"password123"}}'

# Get current user (replace TOKEN with actual token)
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer TOKEN"

# Sign out
curl -X DELETE http://localhost:3000/api/v1/auth/sign_out
```

## Development

To update the API documentation:

1. Edit `swagger.yaml` to modify the OpenAPI specification
2. The changes will be reflected immediately in the Swagger UI
3. No server restart is required for documentation changes

## Notes

- All endpoints return JSON responses
- The API follows RESTful conventions
- Error responses include detailed validation messages
- JWT tokens are currently placeholder implementations for development
