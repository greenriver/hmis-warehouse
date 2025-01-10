###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# contain our arel-helper methods, reduce name space pollution
class Hmis::ArelHelper
  include Singleton
  include Hmis::Concerns::HmisArelHelper
end
