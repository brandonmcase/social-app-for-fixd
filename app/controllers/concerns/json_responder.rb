module JsonResponder
  extend ActiveSupport::Concern

  # Standard success responses
  def render_success(data = nil, status: :ok, meta: nil)
    payload = {}
    payload[:data] = data if data
    payload[:meta] = meta if meta
    render json: payload, status: status
  end

  def render_created(data, meta: nil)
    render_success(data, status: :created, meta: meta)
  end

  def render_no_content
    head :no_content
  end

  # Standard error responses
  def render_error(code:, message:, details: nil, status: :bad_request)
    payload = { error: { code: code, message: message } }
    payload[:error][:details] = details if details
    render json: payload, status: status
  end

  def render_validation_error(errors, message: "Validation failed")
    render_error(
      code: "validation_error",
      message: message,
      details: errors.is_a?(ActiveModel::Errors) ? errors.full_messages : errors,
      status: :unprocessable_content
    )
  end

  def render_not_found(message = "Resource not found")
    render_error(code: "not_found", message: message, status: :not_found)
  end

  def render_unauthorized(message: "Invalid or missing token")
    render_error(code: "unauthorized", message: message, status: :unauthorized)
  end

  def render_forbidden(message = "Access denied")
    render_error(code: "forbidden", message: message, status: :forbidden)
  end

  # Resource-specific responses
  def render_resource(resource, options = {})
    status = options[:status] || :ok
    serializer = options[:serializer]
    meta = options[:meta]

    if serializer
      data = serializer.new(resource).as_json
    else
      data = resource
    end

    # For backward compatibility, don't wrap in data key for single resources
    if meta
      render json: { data: data, meta: meta }, status: status
    else
      render json: data, status: status
    end
  end

  def render_collection(collection, options = {})
    status = options[:status] || :ok
    serializer = options[:serializer]
    meta = options[:meta]

    if serializer
      data = collection.map { |item| serializer.new(item).as_json }
    else
      data = collection
    end

    # For backward compatibility, don't wrap in data key for collections
    if meta
      render json: { data: data, meta: meta }, status: status
    else
      render json: data, status: status
    end
  end

  # Handle ActiveRecord operations
  def render_save_result(resource, success_status: :ok, meta: nil)
    if resource.persisted?
      render_resource(resource, status: success_status, meta: meta)
    else
      render_validation_error(resource.errors)
    end
  end

  def render_create_result(resource, meta: nil)
    render_save_result(resource, success_status: :created, meta: meta)
  end

  def render_update_result(resource, meta: nil)
    render_save_result(resource, success_status: :ok, meta: meta)
  end

  # Pagination support
  def render_paginated(collection, options = {})
    meta = {
      pagination: {
        current_page: collection.current_page,
        total_pages: collection.total_pages,
        total_count: collection.total_count,
        per_page: collection.limit_value
      }
    }

    # For backward compatibility, don't wrap paginated collections in data key
    if options[:serializer]
      data = collection.map { |item| options[:serializer].new(item).as_json }
    else
      data = collection
    end

    render json: { data: data, meta: meta }, status: options[:status] || :ok
  end
end
