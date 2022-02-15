###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# for making arbitrary "models" for use in forms which may or may not actually be tied to
# any database table (pattern borrowed from Theron)
class ModelForm
  include Virtus.model
  include ActiveModel::Model
  extend  ActiveModel::Naming
end
