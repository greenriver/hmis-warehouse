###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::CollectionPolicy
  include Memery
  attr_reader :user

  def initialize(user:, collection_id:)
    @user = user
    @collection_id = collection_id
  end

  Role.permissions.each do |permission|
    define_method("#{permission}?") do
      user.collections.where(id: @collection_id).joins(access_controls: :role).merge(Role.where(permission => true)).any?
    end
    memoize :"#{permission}?"
  end
end
