class CasBase < ActiveRecord::Base
  establish_connection "#{Rails.env}_cas".parameterize.underscore.to_sym
  self.abstract_class = true

  def self.db_exists?
    self.connection_pool.with_connection(&:active?) rescue false
  end
end
