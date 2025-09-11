class DatabaseConnectionPoolService
  def self.monitor_pool_status
    pool = ActiveRecord::Base.connection_pool

    {
      size: pool.size,
      checked_out: pool.checked_out.size,
      available: pool.available_count,
      waiting: pool.num_waiting_in_queue,
      utilization_percentage: (pool.checked_out.size.to_f / pool.size * 100).round(2)
    }
  end

  def self.log_pool_status
    status = monitor_pool_status
    Rails.logger.info "Database Connection Pool Status: #{status}"

    # Alert if pool utilization is high
    if status[:utilization_percentage] > 80
      Rails.logger.warn "High database connection pool utilization: #{status[:utilization_percentage]}%"
    end

    status
  end

  def self.ensure_connection_health
    # Check if we can establish a new connection
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      true
    rescue => e
      Rails.logger.error "Database connection health check failed: #{e.message}"
      false
    end
  end

  def self.with_connection_monitoring(&block)
    start_time = Time.current
    pool_status_before = monitor_pool_status

    result = yield

    pool_status_after = monitor_pool_status
    duration = Time.current - start_time

    Rails.logger.info "Database operation completed in #{duration.round(3)}s. Pool utilization: #{pool_status_before[:utilization_percentage]}% -> #{pool_status_after[:utilization_percentage]}%"

    result
  rescue => e
    Rails.logger.error "Database operation failed: #{e.message}"
    raise e
  end
end
