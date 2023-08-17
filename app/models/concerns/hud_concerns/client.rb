###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudConcerns::Client
  extend ActiveSupport::Concern
  included do
    def self.race_fields
      ::HudUtility2024.races.keys
    end

    # those race fields which are marked as pertinent to the client
    def race_fields
      self.class.race_fields.select { |f| send(f).to_i == 1 }
    end

    # those gender fields which are marked as pertinent to the client
    def gender_fields
      ::HudUtility2024.gender_fields.select { |f| send(f).to_i == 1 }
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
      HudUtility2024.gender_id_to_field_name
      @gender_multi ||= [].tap do |gm|
        HudUtility2024.gender_id_to_field_name.each { |id, field| gm << id if send(field) == 1 }
        # Per the data standards, only look to GenderNone if we don't have a more specific response
        gm << self.GenderNone if gm.empty? && self.GenderNone.in?([8, 9, 99])
      end
    end

    scope :age_group, ->(start_age: 0, end_age: nil) do
      start_age = 0 unless start_age.is_a?(Integer)
      end_age   = nil unless end_age.is_a?(Integer)
      if end_age.present?
        where(DOB: end_age.years.ago..start_age.years.ago)
      else
        where(arel_table[:DOB].lteq(start_age.years.ago))
      end
    end

    scope :age_group_within_range, ->(start_age: 0, end_age: nil, start_date: Date.current, end_date: Date.current) do
      start_age = 0 unless start_age.is_a?(Integer)
      end_age   = nil unless end_age.is_a?(Integer)
      if end_age.present?
        where(DOB: (start_date - end_age.years)..(end_date - start_age.years))
      else
        where(arel_table[:DOB].lteq(start_date - start_age.years))
      end
    end

    scope :adults, -> { age_group(start_age: 18) }
  end
end
