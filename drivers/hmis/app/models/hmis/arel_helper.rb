###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# contain our arel-helper methods, reduce name space pollution
class Hmis::ArelHelper
  include Singleton
  include Hmis::Concerns::HmisArelHelper
end
