###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientSearch
  extend ActiveSupport::Concern
  included do
    # Requires a block!
    def self.text_searcher(text, **_kwargs, &block)
      return none unless text.present?

      text.strip!
      sa = arel_table
      alpha_numeric = /[[[:alnum:]]-]+/.match(text).try(:[], 0) == text
      numeric = /[\d-]+/.match(text).try(:[], 0) == text
      date = /\d\d\/\d\d\/\d\d\d\d/.match(text).try(:[], 0) == text
      social = /\d\d\d-\d\d-\d\d\d\d/.match(text).try(:[], 0) == text

      if alpha_numeric && (text.size == 32 || text.size == 36)
        where = sa[:PersonalID].matches(text.gsub('-', ''))
      elsif social
        where = sa[:SSN].eq(text.gsub('-', ''))
      elsif date
        (month, day, year) = text.split('/')
        where = sa[:DOB].eq("#{year}-#{month}-#{day}")
      elsif numeric
        where = sa[:PersonalID].eq(text).or(sa[:id].eq(text))
      else
        matches_external_ids = false
        if alpha_numeric && respond_to?(:search_by_external_id) && RailsDrivers.loaded.include?(:hmis_external_apis)
          external_id_scope = HmisExternalApis::ExternalId.for_clients
            .where(eid_t[:value].eq(text))
            .select(:source_id)
          matches_external_ids = self.where(id: external_id_scope.select(:source_id)).any?
        end

        if matches_external_ids
          # dummy where to pass to OR. This method needs refactoring :(
          where = sa[:id] = -1
        else
          # this is a proper name search
          return ClientSearchUtil::NameSearch.perform(term: text, clients: self)
        end
      end

      where = search_by_external_id(where, text) if alpha_numeric && respond_to?(:search_by_external_id) && RailsDrivers.loaded.include?(:hmis_external_apis)

      begin
        # requires a block to calculate which client_ids are acceptable within the search context.
        # If you are searching custom names, you must include the join to the custom names association in the block
        client_ids = block.call(where)
      rescue RangeError
        return none
      end

      # WARNING: Any ids added to client_ids below here could be outside of the search scope
      if numeric
        source_client_ids = GrdaWarehouse::WarehouseClient.where(destination_id: text).pluck(:source_id)
        if source_client_ids.any?
          # append destination_id
          client_ids << text
          # append any source client ids for that destination
          client_ids += source_client_ids
        end
      end
      where(id: client_ids)
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

    # name_search(arel_t, :LastName, "#{term}%", **kwargs)
    def self.name_search(arel_t, field, text, custom_name_options: {})
      query = arel_t[field].lower.matches(text)
      return with_custom_name_search(query, field, text, **custom_name_options) if custom_name_options.present?

      query
    end

    # with_custom_name_search(
    #  "LastName like 'foo%'",
    #  :LastName,
    #  "foo",
    #  association: :names,
    #  klass: Hmis::Hud::CustomClientName
    # )
    def self.with_custom_name_search(where, field, text, association:, klass:, field_map: {})
      column = field_map[field] || field
      return where unless reflect_on_association(association)&.klass == klass

      where.or(klass.arel_table[column].lower.matches(text))
    end
  end
end
