###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrPaperTrail
  class Version < ActiveRecord::Base
    include PaperTrail::VersionConcern
    include GrPaperTrailConcern

    scope :successful_authentications, -> {
      devise_keys = [
        'sign_in_count',
        'current_sign_in_at',
        'last_sign_in_at',
        'updated_at',
      ]

      versions = arel_table
      conditions = devise_keys.map do |key|
        versions[:object_changes].matches("%#{key}:%", nil, true)
      end

      conditions << versions[:whodunnit].in(['unauthenticated', nil])

      devise_condition = conditions.inject do |condition, pattern|
        condition.and(pattern)
      end

      where(devise_condition)
    }
    scope :failed_authentications, -> {
      devise_keys = [
        'sign_in_count',
        'current_sign_in_at',
        'last_sign_in_at',
        'updated_at',
      ]

      versions = arel_table
      conditions = devise_keys.map do |key|
        versions[:object_changes].matches("%#{key}:%", nil, true)
      end

      conditions << versions[:whodunnit].eq(nil)

      devise_condition = conditions.inject do |condition, pattern|
        condition.and(pattern)
      end

      where(devise_condition)
    }
  end
end
