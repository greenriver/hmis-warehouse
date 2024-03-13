###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientSearch
  extend ActiveSupport::Concern
  included do
    # @param text [String] search term
    # @param sorted [Boolean] will attempt ordering against search term it seems to be free-text
    # @param resolve_for_join_query [Boolean] return results as sub query of (client_id, score) suitable for joins
    def self.text_searcher(text, sorted:, resolve_for_join_query: false)
      return none unless text.present?

      text.strip!
      sa = arel_table
      alpha_numeric = /[[[:alnum:]]-]+/.match(text).try(:[], 0) == text
      numeric = /[\d-]+/.match(text).try(:[], 0) == text
      date = /\d\d\/\d\d\/\d\d\d\d/.match(text).try(:[], 0) == text
      social = /\d\d\d-\d\d-\d\d\d\d/.match(text).try(:[], 0) == text

      # should never match
      never_cond = sa[:id].eq(nil)

      max_pk = 2_147_483_648 # PK is a 4 byte signed INT (2 ** ((4 * 8) - 1))
      term_is_possibly_pk = numeric ? text.to_i < max_pk : false

      # If alphanumeric search term matches a Scan Card code, return immediately
      if alpha_numeric && HmisEnforcement.hmis_enabled?
        matching_scan_card = Hmis::ScanCardCode.active.find_by(value: text)
        return where(sa[:id].eq(matching_scan_card.client_id)) if matching_scan_card
      end

      if alpha_numeric && (text.size == 32 || text.size == 36)
        where = sa[:PersonalID].matches(text.gsub('-', ''))
      elsif social
        where = sa[:SSN].eq(text.gsub('-', ''))
      elsif date
        (month, day, year) = text.split('/')
        where = sa[:DOB].eq("#{year}-#{month}-#{day}")
      elsif numeric
        where = sa[:PersonalID].eq(text)
        if term_is_possibly_pk
          conditions = [where, sa[:id].eq(text)]

          # Match against deleted/merged ids
          cmh_t = Hmis::ClientMergeHistory.arel_table
          conditions.push(
            sa[:id].in(cmh_t.project(:retained_client_id).where(cmh_t[:deleted_client_id].eq(text))),
          )
          where = conditions.reduce(:or)
        end
      elsif text =~ /\Ahousehold:\s?([-[:alnum:]]+)\z/
        household_id = Regexp.last_match[1].gsub('-', '')
        client_ids = GrdaWarehouse::Hud::Enrollment.where(HouseholdID: household_id).joins(:client).pluck(sa[:id])
        where = sa[:id].in(client_ids)
      elsif text =~ /\Aenrollment:\s?([\d]+)\z/
        enrollment_id = Regexp.last_match[1]
        client_ids = GrdaWarehouse::Hud::Enrollment.where(id: enrollment_id).joins(:client).pluck(sa[:id])
        where = sa[:id].in(client_ids)
      else
        # NOTE: per discussion with Gig, only numeric IDs are in use at this time, commenting this out for now
        ## At this point, term could be an alpha-numeric ID or a human name. To avoid having to combine fuzzy name
        ## search with these other conditions, first check if the term matches external ids. If no matches are
        ## found, we do an early return with name-search results.
        # matches_external_ids = where(search_by_external_id(never_cond, text)).any? if ENV['ALPHANUMERIC_HMIS_EXTERNAL_IDS'] && alpha_numeric && respond_to?(:search_by_external_id) && RailsDrivers.loaded.include?(:hmis_external_apis)
        matches_external_ids = false
        unless matches_external_ids
          # short circuit the rest of search. Since no external IDS are found, this seems to be free text and we can just return
          # name search results
          return ClientSearchUtil::NameSearch.perform_as_joinable_query(term: text, clients: self) if resolve_for_join_query

          return ClientSearchUtil::NameSearch.perform(term: text, clients: self, sorted: sorted)
        end
      end

      # dummy condition to start the OR chain. This method needs refactoring
      where ||= never_cond
      where = search_by_external_id(where, text) if alpha_numeric && respond_to?(:search_by_external_id) && RailsDrivers.loaded.include?(:hmis_external_apis) && HmisExternalApis::AcHmis::Mci.enabled?

      results = nil
      if numeric && term_is_possibly_pk
        client_ids = self.where(where).pluck(:id)
        source_client_ids = GrdaWarehouse::WarehouseClient.where(destination_id: text).pluck(:source_id)
        if source_client_ids.any?
          # append destination_id
          client_ids << text
          # append any source client ids for that destination
          client_ids += source_client_ids
          results = where(id: client_ids)
        else
          results = where(where)
        end
      else
        results = where(where)
      end

      # we aren't dealing with a fuzzy string search here so we can't really rank the results
      # return NULL as score as match is binary (either it matches an ID or it doesn't)
      results = results.select(c_t[:id].as('client_id'), Arel.sql('NULL AS score')) if resolve_for_join_query
      results
    end

    def self.nickname_search(where, text)
      nicks = Nickname.for(text).map(&:name)
      where = where.or(nf('LOWER', [arel_table[:FirstName]]).in(nicks)) if nicks.any?

      where
    end

    def self.metaphone_search(where, field, text)
      alt_names = UniqueName.where(double_metaphone: Text::Metaphone.double_metaphone(text).to_s).map(&:name)
      where = where.or(nf('LOWER', [arel_table[field]]).in(alt_names)) if alt_names.present?

      where
    end
  end
end
