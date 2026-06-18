###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

Rails.application.reloader.to_prepare do
  # This is a way to have assets in the asset pipeline that are different per environment
  SerializedAsset.init
end
