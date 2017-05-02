class CasBase < ActiveRecord::Base
  establish_connection "#{Rails.env}_cas".parameterize.underscore.to_sym
  self.abstract_class = true
end
