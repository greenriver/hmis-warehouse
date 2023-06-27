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

    def adult?(on_date = Date.current)
      return nil unless dob.present?

      age(on_date) >= 18
    end

    def child?(on_date = Date.current)
      return nil unless dob.present?

      age(on_date) < 18
    end

    # This can be used to retrieve numeric representations of the client gender, useful for HUD reporting
    def gender_multi
      @gender_multi ||= [].tap do |gm|
        gm << 0 if self.Female == 1
        gm << 1 if self.Male == 1
        gm << 4 if self.NoSingleGender == 1
        gm << 5 if self.Transgender == 1
        gm << 6 if self.Questioning == 1
        # Per the data standards, only look to GenderNone if we don't have a more specific response
        gm << self.GenderNone if gm.empty? && self.GenderNone.in?([8, 9, 99])
      end
    end
  end
end
