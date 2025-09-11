class QueryAnalyzer
  class UnsafeQueryError < StandardError; end

  # Safe, plan-only (does NOT execute the query)
  def self.plan(relation)
    raise ArgumentError, "Expected ActiveRecord::Relation" unless relation.is_a?(ActiveRecord::Relation)
    relation.explain # Rails does the EXPLAIN call internally
  end

  # Helper (optional): ensure you're only explaining SELECTs
  def self.ensure_select!(relation)
    sql = relation.to_sql.strip.upcase
    raise UnsafeQueryError, "Only SELECT statements can be explained" unless sql.start_with?("SELECT")
  end
end
