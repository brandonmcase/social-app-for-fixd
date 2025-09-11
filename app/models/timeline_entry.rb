class TimelineEntry < ApplicationRecord
  self.table_name = "timeline_mv"
  def readonly? = true
end
