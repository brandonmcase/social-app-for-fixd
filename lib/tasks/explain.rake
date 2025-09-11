namespace :db do
  desc "EXPLAIN (ANALYZE, BUFFERS) a named relation in dev. Example: bin/rails 'db:explain[Post.active.limit(10)]'"
  task :explain, [ :relation_code ] => :environment do |_t, args|
    abort "Dev only" unless Rails.env.development? || Rails.env.test?
    abort "Provide relation code" if args[:relation_code].to_s.strip.empty?

    relation = eval(args[:relation_code]) # dev-only convenience
    unless relation.is_a?(ActiveRecord::Relation)
      abort "Expected an ActiveRecord::Relation, got #{relation.class}"
    end

    sql = relation.to_sql
    raise "Only SELECT allowed" unless sql.strip.upcase.start_with?("SELECT")

    options = "ANALYZE, BUFFERS, TIMING"
    # Explain with parentheses syntax
    stmt = "EXPLAIN (#{options}) #{sql}"

    # NOTE: This is intentionally dev-only; do not move into app code.
    # If Brakeman flags this line in CI, add it to brakeman.ignore.
    rows = ActiveRecord::Base.connection.exec_query(stmt).rows
    puts rows.map(&:first).join("\n")
  end
end
