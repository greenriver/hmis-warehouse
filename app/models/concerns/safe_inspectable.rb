# some objects on too large to show
module SafeInspectable
  extend ActiveSupport::Concern

  def to_s
    inspect
  end

  def inspect
    "#{self.class.name}##{object_id}"
  end
end
