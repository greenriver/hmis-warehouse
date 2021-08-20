###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Cas
  class NonHmisClient < CasBase
    include ArelHelper
    self.inheritance_column = :_type_disabled # disable STI

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', foreign_key: :warehouse_client_id, optional: true

    # Although default_scope is generally discouraged, one of the reasons CAS is a separate DB, is to keep
    # Deidentified clients out of the warehouse...
    default_scope { where(identified: true) }

    scope :unassigned, -> do
      where(warehouse_client_id: nil)
    end

    MATCH_COLUMNS = [:first_name, :last_name, :date_of_birth, :ssn].freeze

    def self.find_matches(batch)
      candidates = batch.pluck(:id, *MATCH_COLUMNS).
        map { |id, *rest| [id, MATCH_COLUMNS.zip(rest).to_h] }.
        to_h

      candidates.each do |_, candidate|
        candidate[:first_name] = candidate[:first_name].downcase.strip.gsub(/[^a-z0-9]/i, '')
        candidate[:last_name] = candidate[:last_name].downcase.strip.gsub(/[^a-z0-9]/i, '')
        candidate[:ssn] = candidate[:ssn].strip.gsub(/[^0-9]/, '')
      end

      by_first_name = candidates.reject { |_, h| h[:first_name].blank? }.group_by { |_, h| h[:first_name] }.transform_values { |c| c.flatten.first }
      by_last_name = candidates.reject { |_, h| h[:last_name].blank? }.group_by { |_, h| h[:last_name] }.transform_values { |c| c.flatten.first }
      by_dob = candidates.reject { |_, h| h[:date_of_birth].blank? }.group_by { |_, h| h[:date_of_birth] }.transform_values { |c| c.flatten.first }
      by_ssn = candidates.reject { |_, h| h[:ssn].blank? }.group_by { |_, h| h[:ssn] }.transform_values { |c| c.flatten.first }

      first_name_matches = client_source.where(c_t[:FirstName].lower.in(by_first_name.keys)).
        pluck(c_t[:FirstName].lower, :id).
        group_by(&:first).
        transform_values { |v| v.map(&:last) }
      last_name_matches = client_source.where(c_t[:LastName].lower.in(by_last_name.keys)).
        pluck(c_t[:LastName].lower, :id).
        group_by(&:first).
        transform_values { |v| v.map(&:last) }
      dob_matches = client_source.where(DOB: by_dob.keys).
        pluck(:DOB, :id).
        group_by(&:first).
        transform_values { |v| v.map(&:last) }
      ssn_matches = client_source.where(SSN: by_ssn.keys).
        pluck(:SSN, :id).
        group_by(&:first).
        transform_values { |v| v.map(&:last) }

      OpenStruct.new(
        candidates: candidates,
        first_name_matches: first_name_matches,
        last_name_matches: last_name_matches,
        dob_matches: dob_matches,
        ssn_matches: ssn_matches,
      )
    end

    def self.exact_match?(candidate, matches)
      name_matches = (matches.first_name_matches[candidate[:first_name]] || []) & (matches.last_name_matches[candidate[:last_name]] || [])
      name_matches.present? && (matches.dob_matches[candidate[:date_of_birth]].present? || matches.ssn_matches[candidate[:ssn]].present?)
    end

    MATCH_TYPES = [
      [:first_name_matches, :first_name],
      [:last_name_matches, :last_name],
      [:dob_matches, :date_of_birth],
      [:ssn_matches, :ssn],
    ].freeze

    def self.partial_matches(candidate, matches)
      partial_matches = []
      MATCH_TYPES.each do |first_type, first_column|
        MATCH_TYPES.each do |second_type, second_column|
          next if first_type == second_type

          partial_matches += matches.send(first_type)[candidate[first_column]] & matches.send(second_type)[candidate[second_column]]
        rescue TypeError
          next
        end
      end
      partial_matches.uniq
    end

    def self.find_exact_matches
      unassigned.find_in_batches do |batch|
        matches = find_matches(batch)

        new_warehouse_ids = []
        matches.candidates.each do |id, candidate|
          next unless exact_match?(candidate, matches)

          new_warehouse_ids << {
            id: id,
            warehouse_client_id: name_matches.first,
          }
        end

        import(
          new_warehouse_ids,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: [:warehouse_client_id],
          },
        )
      end
    end

    def self.client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end
