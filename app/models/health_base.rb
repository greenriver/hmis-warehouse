class HealthBase < ActiveRecord::Base
  establish_connection DB_HEALTH
  self.abstract_class = true
  has_paper_trail
end
