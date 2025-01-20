module Hmis::Ce
  def self.table_name_prefix
    'ce_'
  end

  def self.enabled?
    Rails.env.development? || Rails.env.test?
  end
end
