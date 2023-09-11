###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

      max_pk = 2_147_483_648 # PK is a 4 byte signed INT (2 ** ((4 * 8) - 1))
      term_is_possibly_pk = numeric ? text.to_i < max_pk : false

      if alpha_numeric && (text.size == 32 || text.size == 36)
        where = sa[:PersonalID].matches(text.gsub('-', ''))
      elsif social
        where = sa[:SSN].eq(text.gsub('-', ''))
      elsif date
        (month, day, year) = text.split('/')
        where = sa[:DOB].eq("#{year}-#{month}-#{day}")
      elsif numeric
        where = sa[:PersonalID].eq(text)
        where = where.or(sa[:id].eq(text)) if term_is_possibly_pk
      else
        matches_external_ids = false
        if alpha_numeric && respond_to?(:search_by_external_id) && RailsDrivers.loaded.include?(:hmis_external_apis)
          eid_t = HmisExternalApis::ExternalId.arel_table
          external_id_scope = HmisExternalApis::ExternalId.for_clients
            .where(eid_t[:value].eq(text))
            .select(:source_id)
          matches_external_ids = self.where(id: external_id_scope.select(:source_id)).any?
        end
        unless matches_external_ids
          # short circuit the rest of search as this seems to be free text
          return ClientSearchUtil::NameSearch.perform_as_joinable_query(term: text, clients: self) if resolve_for_join_query

          return ClientSearchUtil::NameSearch.perform(term: text, clients: self, sorted: sorted)
        end
      end

      # dummy condition to start the OR chain. This method needs refactoring
      where ||= sa[:id].eq(nil) # should never match
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
      results = results.select(Arel.sql('"Client"."id" AS client_id'), Arel.sql('NULL AS score')) if resolve_for_join_query
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
