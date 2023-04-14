###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudConcerns::Client
  extend ActiveSupport::Concern
  included do
    def self.race_fields
      ::HudUtility.races.keys
    end

    # those race fields which are marked as pertinent to the client
    def race_fields
      self.class.race_fields.select { |f| send(f).to_i == 1 }
    end

    # those gender fields which are marked as pertinent to the client
    def gender_fields
      ::HudUtility.gender_fields.select { |f| send(f).to_i == 1 }
    end

    def adult?
      return nil unless age.present?

      age >= 18
    end

    def child?
      return nil unless age.present?

      age < 18
    end
  end
end
