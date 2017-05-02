class EtoBase < ActiveRecord::Base
  establish_connection :eto
  self.abstract_class = true

  def readonly?
    true
  end
end
