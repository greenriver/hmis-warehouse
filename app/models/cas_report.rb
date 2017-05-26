# gets dumped into by CAS; is 
class CasReport < ActiveRecord::Base
  def readonly?
    true
  end
end
