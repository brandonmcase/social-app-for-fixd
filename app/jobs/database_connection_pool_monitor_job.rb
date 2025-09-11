class DatabaseConnectionPoolMonitorJob < ApplicationJob
  queue_as :default

  def perform
    DatabaseConnectionPoolService.log_pool_status

    # Check connection health
    unless DatabaseConnectionPoolService.ensure_connection_health
      Rails.logger.error "Database connection health check failed"
      # In a production environment, you might want to send alerts here
    end

  rescue => e
    Rails.logger.error "DatabaseConnectionPoolMonitorJob failed: #{e.message}"
    raise e
  end
end
