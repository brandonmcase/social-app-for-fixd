# API Testing Guide with cURL

This guide provides comprehensive cURL examples for testing the Social App API with real JWT authentication.

## Prerequisites

1. **Set JWT Secret** (required):
   ```bash
   export JWT_SECRET_KEY="your_super_secret_jwt_key_change_this_in_production"
   ```

2. **Start the server**:
   ```bash
   bundle exec rails server
   ```

3. **Base URL**: `http://localhost:3000`

---

## 🔐 Authentication Endpoints

### 1. Register a New User

**Endpoint**: `POST /api/v1/auth/register`

```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "username": "testuser",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
```

**Expected Response**:
```json
{
  "data": {
    "id": 1,
    "email": "test@example.com",
    "username": "testuser"
  },
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJ1c2VybmFtZSI6InRlc3R1c2VyIiwiZXhwIjoxNzU3NjIwODc3LCJpYXQiOjE3NTc1MzQ0Nzd9.example_signature"
}
```

### 2. Sign In

**Endpoint**: `POST /api/v1/auth/sign_in`

```bash
curl -X POST http://localhost:3000/api/v1/auth/sign_in \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123"
    }
  }'
```

**Expected Response**:
```json
{
  "data": {
    "id": 1,
    "email": "test@example.com",
    "username": "testuser"
  },
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJ1c2VybmFtZSI6InRlc3R1c2VyIiwiZXhwIjoxNzU3NjIwODc3LCJpYXQiOjE3NTc1MzQ0Nzd9.example_signature"
}
```

### 3. Get Current User Info

**Endpoint**: `GET /api/v1/auth/me`

```bash
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

**Expected Response**:
```json
{
  "data": {
    "id": 1,
    "email": "test@example.com",
    "username": "testuser"
  }
}
```

### 4. Sign Out

**Endpoint**: `DELETE /api/v1/auth/sign_out`

```bash
curl -X DELETE http://localhost:3000/api/v1/auth/sign_out \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

**Expected Response**: `204 No Content`

---

## 📝 Posts Endpoints

### 1. Create a Post

**Endpoint**: `POST /api/v1/posts`

```bash
curl -X POST http://localhost:3000/api/v1/posts \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "post": {
      "title": "My Amazing Post",
      "body": "This is the content of my post. It can be up to 1000 characters long."
    }
  }'
```

**Expected Response**:
```json
{
  "id": 1,
  "title": "My Amazing Post",
  "body": "This is the content of my post. It can be up to 1000 characters long.",
  "user_id": 1,
  "deleted_at": null,
  "view_count": 0,
  "metadata": {},
  "jsonb": {},
  "average_rating": "0.0",
  "rating_count": 0,
  "created_at": "2025-09-10T20:01:29.121Z",
  "updated_at": "2025-09-10T20:01:29.121Z"
}
```

### 2. Get All Posts (Paginated)

**Endpoint**: `GET /api/v1/posts`

```bash
# Get first page (default 20 posts)
curl -X GET http://localhost:3000/api/v1/posts \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"

# Get specific page with custom per_page
curl -X GET "http://localhost:3000/api/v1/posts?page=2&per_page=10" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

**Expected Response**:
```json
{
  "data": [
    {
      "id": 1,
      "title": "My Amazing Post",
      "body": "This is the content of my post...",
      "user_id": 1,
      "deleted_at": null,
      "view_count": 0,
      "metadata": {},
      "jsonb": {},
      "average_rating": "0.0",
      "rating_count": 0,
      "created_at": "2025-09-10T20:01:29.121Z",
      "updated_at": "2025-09-10T20:01:29.121Z"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total_pages": 1,
    "total_count": 1
  }
}
```

### 3. Get a Specific Post

**Endpoint**: `GET /api/v1/posts/:id`

```bash
curl -X GET http://localhost:3000/api/v1/posts/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

**Expected Response**:
```json
{
  "id": 1,
  "title": "My Amazing Post",
  "body": "This is the content of my post...",
  "user_id": 1,
  "deleted_at": null,
  "view_count": 0,
  "metadata": {},
  "jsonb": {},
  "average_rating": "0.0",
  "rating_count": 0,
  "created_at": "2025-09-10T20:01:29.121Z",
  "updated_at": "2025-09-10T20:01:29.121Z"
}
```

### 4. Update a Post

**Endpoint**: `PATCH /api/v1/posts/:id`

```bash
curl -X PATCH http://localhost:3000/api/v1/posts/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "post": {
      "title": "Updated Post Title",
      "body": "Updated post content"
    }
  }'
```

**Expected Response**:
```json
{
  "id": 1,
  "title": "Updated Post Title",
  "body": "Updated post content",
  "user_id": 1,
  "deleted_at": null,
  "view_count": 0,
  "metadata": {},
  "jsonb": {},
  "average_rating": "0.0",
  "rating_count": 0,
  "created_at": "2025-09-10T20:01:29.121Z",
  "updated_at": "2025-09-10T20:01:29.121Z"
}
```

### 5. Soft Delete a Post

**Endpoint**: `DELETE /api/v1/posts/:id`

```bash
curl -X DELETE http://localhost:3000/api/v1/posts/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

**Expected Response**: `204 No Content`

---

## ⭐ Rating Endpoints

### 1. Create a Rating

**Endpoint**: `POST /api/v1/posts/:post_id/rating`

```bash
curl -X POST http://localhost:3000/api/v1/posts/1/rating \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "rating": {
      "rating": 5
    }
  }'
```

**Expected Response**:
```json
{
  "id": 1,
  "user_id": 1,
  "post_id": 1,
  "rating": 5,
  "created_at": "2025-09-10T20:01:29.121Z",
  "updated_at": "2025-09-10T20:01:29.121Z"
}
```

### 2. Get User's Rating for a Post

**Endpoint**: `GET /api/v1/posts/:post_id/rating`

```bash
curl -X GET http://localhost:3000/api/v1/posts/1/rating \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

**Expected Response**:
```json
{
  "id": 1,
  "user_id": 1,
  "post_id": 1,
  "rating": 5,
  "created_at": "2025-09-10T20:01:29.121Z",
  "updated_at": "2025-09-10T20:01:29.121Z"
}
```

### 3. Update a Rating

**Endpoint**: `PATCH /api/v1/posts/:post_id/rating`

```bash
curl -X PATCH http://localhost:3000/api/v1/posts/1/rating \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "rating": {
      "rating": 4
    }
  }'
```

**Expected Response**:
```json
{
  "id": 1,
  "user_id": 1,
  "post_id": 1,
  "rating": 4,
  "created_at": "2025-09-10T20:01:29.121Z",
  "updated_at": "2025-09-10T20:01:29.121Z"
}
```

### 4. Delete a Rating

**Endpoint**: `DELETE /api/v1/posts/:post_id/rating`

```bash
curl -X DELETE http://localhost:3000/api/v1/posts/1/rating \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

**Expected Response**: `204 No Content`

---

## 📊 Timeline Endpoint

### Get Activity Timeline

**Endpoint**: `GET /api/v1/timeline`

```bash
# Get timeline (default pagination)
curl -X GET http://localhost:3000/api/v1/timeline \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"

# Get timeline with pagination
curl -X GET "http://localhost:3000/api/v1/timeline?page=1&per_page=10" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"

# Get timeline filtered by minimum rating
curl -X GET "http://localhost:3000/api/v1/timeline?min_rating=4.0" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"

# Combined filters
curl -X GET "http://localhost:3000/api/v1/timeline?page=1&per_page=5&min_rating=3.0" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

**Expected Response**:
```json
{
  "data": [
    {
      "id": 1,
      "title": "My Amazing Post",
      "body": "This is the content of my post...",
      "user_id": 1,
      "username": "testuser",
      "deleted_at": null,
      "view_count": 0,
      "metadata": {},
      "jsonb": {},
      "average_rating": "4.5",
      "rating_count": 2,
      "created_at": "2025-09-10T20:01:29.121Z",
      "updated_at": "2025-09-10T20:01:29.121Z"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total_pages": 1,
    "total_count": 1
  }
}
```

---

## 🚨 Error Responses

### Authentication Errors

**401 Unauthorized** (Invalid/Missing Token):
```json
{
  "error": {
    "code": "unauthorized",
    "message": "Invalid or missing token"
  }
}
```

**401 Unauthorized** (Invalid Credentials):
```json
{
  "error": {
    "code": "authentication_error",
    "message": "Invalid email or password"
  }
}
```

### Validation Errors

**422 Unprocessable Content** (Registration Validation):
```json
{
  "error": {
    "code": "validation_error",
    "message": "Invalid registration",
    "details": {
      "email": ["has already been taken"],
      "username": ["has already been taken"]
    }
  }
}
```

**422 Unprocessable Content** (Post Validation):
```json
{
  "error": {
    "code": "validation_error",
    "message": "Invalid record",
    "details": {
      "title": ["can't be blank"],
      "body": ["is too long (maximum is 1000 characters)"]
    }
  }
}
```

### Authorization Errors

**403 Forbidden** (Access Denied):
```json
{
  "error": {
    "code": "forbidden",
    "message": "You are not authorized to perform this action"
  }
}
```

### Not Found Errors

**404 Not Found**:
```json
{
  "error": {
    "code": "not_found",
    "message": "Record not found"
  }
}
```

---

## 🔄 Complete Workflow Example

Here's a complete workflow to test the entire API:

```bash
# 1. Register a new user
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "workflow@example.com",
      "username": "workflowuser",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }')

# Extract JWT token from response
JWT_TOKEN=$(echo $REGISTER_RESPONSE | jq -r '.token')

# 2. Get current user info
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer $JWT_TOKEN"

# 3. Create a post
curl -X POST http://localhost:3000/api/v1/posts \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "post": {
      "title": "Workflow Test Post",
      "body": "This post was created during the complete workflow test."
    }
  }'

# 4. Rate the post
curl -X POST http://localhost:3000/api/v1/posts/1/rating \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rating": {
      "rating": 5
    }
  }'

# 5. Get timeline
curl -X GET http://localhost:3000/api/v1/timeline \
  -H "Authorization: Bearer $JWT_TOKEN"

# 6. Sign out
curl -X DELETE http://localhost:3000/api/v1/auth/sign_out \
  -H "Authorization: Bearer $JWT_TOKEN"
```

---

## 📋 Testing Checklist

- [ ] **Authentication**
  - [ ] Register new user
  - [ ] Sign in with valid credentials
  - [ ] Sign in with invalid credentials
  - [ ] Get current user info
  - [ ] Sign out

- [ ] **Posts**
  - [ ] Create post
  - [ ] Get all posts (paginated)
  - [ ] Get specific post
  - [ ] Update own post
  - [ ] Try to update another user's post (should fail)
  - [ ] Soft delete post

- [ ] **Ratings**
  - [ ] Create rating
  - [ ] Get user's rating
  - [ ] Update rating
  - [ ] Delete rating
  - [ ] Try to rate same post twice (should fail)

- [ ] **Timeline**
  - [ ] Get timeline
  - [ ] Get timeline with pagination
  - [ ] Get timeline with rating filter

- [ ] **Error Handling**
  - [ ] Test with invalid JWT token
  - [ ] Test with expired JWT token
  - [ ] Test without Authorization header
  - [ ] Test with malformed JSON

---

## 🔧 Environment Variables

Make sure to set these environment variables:

```bash
# Required for JWT token generation/validation
export JWT_SECRET_KEY="your_super_secret_jwt_key_change_this_in_production"

# Optional Devise configuration
export DEVISE_MAILER_SENDER="no-reply@example.com"
```

---

## 📚 Additional Resources

- **API Documentation**: Visit `http://localhost:3000/api-docs/` for interactive Swagger UI
- **OpenAPI Spec**: `http://localhost:3000/api-docs/swagger.yaml`
- **JWT Token Info**: Tokens expire after 24 hours and contain user information
- **Rate Limiting**: API has rate limiting enabled (see logs for 429 responses)

---

*Happy Testing! 🚀*
