###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

      candidates.each_value do |candidate|
        candidate[:lc_first_name] = candidate[:first_name]&.downcase&.strip&.gsub(/[^a-z0-9]/i, '')
        candidate[:lc_last_name] = candidate[:last_name]&.downcase&.strip&.gsub(/[^a-z0-9]/i, '')
        candidate[:ssn] = candidate[:ssn]&.strip&.gsub(/[^0-9]/, '')
      end

      by_first_name = candidates.reject { |_, h| h[:lc_first_name].blank? }.group_by { |_, h| h[:lc_first_name] }.transform_values { |c| c.flatten.first }
      by_last_name = candidates.reject { |_, h| h[:lc_last_name].blank? }.group_by { |_, h| h[:lc_last_name] }.transform_values { |c| c.flatten.first }
      by_dob = candidates.reject { |_, h| h[:date_of_birth].blank? }.group_by { |_, h| h[:date_of_birth] }.transform_values { |c| c.flatten.first }
      by_ssn = candidates.reject { |_, h| h[:ssn].blank? || !valid_social?(h[:ssn]) }.group_by { |_, h| h[:ssn] }.transform_values { |c| c.flatten.first }

      first_name_matches = {}
      client_source.where(c_t[:FirstName].lower.in(by_first_name.keys)).
        pluck(c_t[:FirstName].lower, :id).each do |first_name, id|
        first_name_matches[first_name] ||= []
        first_name_matches[first_name] << id
      end
      last_name_matches = {}
      client_source.where(c_t[:LastName].lower.in(by_last_name.keys)).
        pluck(c_t[:LastName].lower, :id).each do |last_name, id|
        last_name_matches[last_name] ||= []
        last_name_matches[last_name] << id
      end
      db_names = client_source.where(id: (first_name_matches.values + last_name_matches.values).flatten).
        pluck(:id, :FirstName, :LastName).
        map { |id, fn, ln| [id, "#{fn} #{ln}"] }.
        to_h
      dob_matches = {}
      client_source.where(DOB: by_dob.keys).
        pluck(:DOB, :id).each do |dob, id|
        dob_matches[dob] ||= []
        dob_matches[dob] << id
      end
      ssn_matches = {}
      client_source.where(SSN: by_ssn.keys).
        pluck(:SSN, :id).each do |ssn, id|
        ssn_matches[ssn] ||= []
        ssn_matches[ssn] << id
      end

      OpenStruct.new(
        candidates: candidates,
        first_name_matches: first_name_matches,
        last_name_matches: last_name_matches,
        dob_matches: dob_matches,
        ssn_matches: ssn_matches,
        db_names: db_names,
      )
    end

    # An "obvious match" from IdentifyDuplicates
    def self.exact_match(candidate, matches)
      ssn_matches = []
      ssn_matches += matches.ssn_matches[candidate[:ssn]] || [] if valid_social?(candidate[:ssn])
      birthdate_matches = []
      birthdate_matches += matches.dob_matches[candidate[:date_of_birth]] || [] if candidate[:date_of_birth].present?
      name_matches = []
      name_matches += (matches.first_name_matches[candidate[:lc_first_name]] || []) & (matches.last_name_matches[candidate[:lc_last_name]] || [])

      all_matches = ssn_matches + birthdate_matches + name_matches
      exact_matches = all_matches.uniq.select { |i| all_matches.count(i) > 1 }.compact

      exact_matches.first
    end

    MATCH_TYPES = [
      [:first_name_matches, :lc_first_name],
      [:last_name_matches, :lc_last_name],
      [:dob_matches, :date_of_birth],
    ].freeze

    # SSN or 2 of first, last, DOB...
    def self.partial_matches(candidate, matches)
      partial_matches = matches.ssn_matches[candidate[:ssn]] || []
      MATCH_TYPES.each do |first_type, first_column|
        MATCH_TYPES.each do |second_type, second_column|
          next if first_type == second_type

          col_one = matches.send(first_type)[candidate[first_column]] || []
          col_two = matches.send(second_type)[candidate[second_column]] || []
          partial_matches += col_one & col_two
        rescue TypeError
          next
        end
      end
      partial_matches.uniq[...7]
    end

    def self.find_exact_matches
      unassigned.find_in_batches do |batch|
        matches = find_matches(batch)

        new_warehouse_ids = []
        matches.candidates.each do |id, candidate|
          exact_match_id = exact_match(candidate, matches)
          next unless exact_match_id.present?

          new_warehouse_ids << {
            id: id,
            warehouse_client_id: exact_match_id,
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

    def self.valid_social?(ssn)
      ::HUD.valid_social?(ssn)
    end
  end
end
