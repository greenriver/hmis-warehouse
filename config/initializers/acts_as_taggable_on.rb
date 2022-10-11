# Rails.logger.debug "Running initializer in #{__FILE__}"

# Store the tags in the warehouse
require Rails.root.join('config', 'initializers', 'db_warehouse')
module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    establish_connection DB_WAREHOUSE
  end
  class Tagging < ::ActiveRecord::Base
    establish_connection DB_WAREHOUSE
  end
end
# ActsAsTaggableOn.force_lowercase = true
# ActsAsTaggableOn.force_parameterize = true
