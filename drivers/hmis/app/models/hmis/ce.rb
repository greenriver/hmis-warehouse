module Hmis::Ce
  def self.table_name_prefix
    'ce_'
  end

  def self.enabled?
    # perhaps this should be an env or db config flag
    Rails.env.development? || Rails.env.test?
  end
end
