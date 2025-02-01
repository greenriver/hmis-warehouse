module Hmis::Ce
  def self.table_name_prefix
    'ce_'
  end

  def self.configuration
    # don't memoize this as we're in a class context here
    Hmis::Ce::Configuration.new
  end
end
