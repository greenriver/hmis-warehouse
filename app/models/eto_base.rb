class EtoBase < ActiveRecord::Base
  establish_connection :eto rescue nil
  self.abstract_class = true

  def readonly?
    true
  end
end
