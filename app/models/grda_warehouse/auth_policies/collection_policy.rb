###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::CollectionPolicy
  include Memery
  attr_reader :user

  def initialize(user:, collection_ids:)
    @user = user
    @collection_ids = collection_ids
  end

  Role.permissions.each do |permission|
    define_method("#{permission}?") do
      user.access_controls.joins(:role).where(collection_id: @collection_ids).merge(Role.where(permission => true)).any?
    end
    memoize :"#{permission}?"
  end
end
