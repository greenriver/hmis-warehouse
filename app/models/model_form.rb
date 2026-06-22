###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# for making arbitrary "models" for use in forms which may or may not actually be tied to
# any database table (pattern borrowed from Theron)
class ModelForm
  include Virtus.model
  include ActiveModel::Model
  extend  ActiveModel::Naming
end
