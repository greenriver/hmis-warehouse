###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Decision Tree
# If the HouseholdID is blank, consider it an individual enrollment, ensure RelationshipToHoH is 1
# If the household only has one person, ensure RelationshipToHoH is 1
# If the household has more than one person, and there is a female 18 or older,
# set the oldest female to RelationshipToHoH = 1 and set any other RelationshipToHoH == 1 to 99
# If the household has more than one person, but no female 18 or older, and someone in the household is 18 or older, set the oldest person to RelationshipToHoH = 1 and set any other RelationshipToHoH == 1 to 99
# If everyone in the household is 17 or younger, and there is a person 10 or younger, set the oldest person to RelationshipToHoH = 1 and set any other RelationshipToHoH == 1 to 99
# If the household only contains clients between the age of 11 and 17 inclusive, break up the household and set everyone as RelationshipToHoH = 1

module HmisCsvTwentyTwenty::HmisCsvCleanup
  class EnforceRelationshipToHoh < Base
    def cleanup!
      # Set anyone with a blank HouseholdID to RelationshipToHoH = 1
      # These clients are not in households
      enrollment_scope.where(HouseholdID: nil).
        where.not(RelationshipToHoH: 1).
        update_all(RelationshipToHoH: 1)

      # Figure out HouseholdID and PersonalID for HoH for each household
      individual_household_ids = [] # don't need to track HoH because everyone is
      multi_person_to_fix = {}
      multi_person_with_no_child_under_11 = [] # all of these will need new HouseholdIDs
      households.each do |hh_id, rows|
        if rows.count == 1
          individual_household_ids << hh_id
        else
          female_adult = rows.select { |m| m[:female] && m[:adult] }.max_by { |m| m[:age] }
          oldest_adult = rows.select { |m| m[:adult] }.max_by { |m| m[:age] }
          child_under_11 = rows.any? { |m| m[:age] >= 0 }
          oldest_client = rows.max_by { |m| m[:age] }
          if female_adult.present?
            multi_person_to_fix[hh_id] = female_adult[:row_id]
          elsif oldest_adult.present?
            multi_person_to_fix[hh_id] = oldest_adult[:row_id]
          elsif child_under_11
            multi_person_to_fix[hh_id] = oldest_client[:row_id]
          else
            multi_person_with_no_child_under_11 << hh_id
          end
        end
      end

      enrollment_scope.where(HouseholdID: individual_household_ids).
        where.not(RelationshipToHoH: 1).
        update_all(RelationshipToHoH: 1)

      enrollment_scope.where(HouseholdID: multi_person_to_fix.keys).
        where(RelationshipToHoH: 1).
        update_all(RelationshipToHoH: 99)
      enrollment_source.import(
        [:id, :RelationshipToHoH],
        multi_person_to_fix.values.map { |id| [id, 1] },
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: [:RelationshipToHoH],
        },
      )
    end

    def households
      ic_t = HmisCsvTwentyTwenty::Importer::Client.arel_table
      @households ||= {}.tap do |hh|
        enrollment_scope.joins(:client).
          where.not(HouseholdID: nil).
          pluck(
            :EnrollmentID,
            :ProjectID,
            :HouseholdID,
            :PersonalID,
            ic_t[:DOB],
            ic_t[:Gender],
            :RelationshipToHoH,
            :id,
          ).
          each do |en_id, project_id, hh_id, personal_id, dob, gender, relationship, id|
            hh[hh_id] ||= []
            age = GrdaWarehouse::Hud::Client.age(date: Date.current, dob: dob)
            hh[hh_id] << {
              row_id: id,
              personal_id: personal_id,
              hoh: relationship == 1,
              age: age || -1,
              female: gender == 0, # rubocop:disable Style/NumericPredicate
              adult: age.present? && age >= 18,
              enrollment_id: en_id,
              project_id: project_id,
            }
          end
        # Ignore any households where there is already only one HoH
        hh.delete_if { |_, rows| rows.one? { |m| m[:hoh] } }
      end
    end

    def enrollment_scope
      enrollment_source.
        joins(:project).
        where(importer_log_id: @importer_log.id)
    end

    def enrollment_source
      HmisCsvTwentyTwenty::Importer::Enrollment
    end

    def self.description
      'Enforce only one Head of Household per household using a decision tree.'
    end

    def self.enable
      {
        import_cleanups: {
          'Enrollment': ['HmisCsvTwentyTwenty::HmisCsvCleanup::EnforceRelationshipToHoh'],
        },
      }
    end
  end
end
