###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientSearch
  extend ActiveSupport::Concern
  included do
    # Requires a block!
    def self.text_searcher(text, **kwargs, &block)
      return none unless text.present?

      text.strip!
      sa = arel_table
      alpha_numeric = /[[[:alnum:]]-]+/.match(text).try(:[], 0) == text
      numeric = /[\d-]+/.match(text).try(:[], 0) == text
      date = /\d\d\/\d\d\/\d\d\d\d/.match(text).try(:[], 0) == text
      social = /\d\d\d-\d\d-\d\d\d\d/.match(text).try(:[], 0) == text
      # TODO: perform all name searches against CustomClientNames

      # Explicitly search for only last, first if there's a comma in the search
      if text.include?(',')
        last, first = text.split(',').map(&:strip)
        where = name_search(sa, :LastName, "#{last.downcase}%", **kwargs) if last.present?
        if last.present? && first.present?
          where = where.and(name_search(sa, :FirstName, "#{first.downcase}%", **kwargs))
        elsif first.present?
          where = name_search(sa, :FirstName, "#{first.downcase}%", **kwargs)
        end
        # Explicitly search for "first last"
      elsif text.include?(' ')
        first, last = text.split(' ').map(&:strip)
        where = name_search(sa, :FirstName, "#{first.downcase}%", **kwargs).
          and(name_search(sa, :LastName, "#{last.downcase}%", **kwargs))
        # Explicitly search for a PersonalID
      elsif alpha_numeric && (text.size == 32 || text.size == 36)
        where = sa[:PersonalID].matches(text.gsub('-', ''))
      elsif social
        where = sa[:SSN].eq(text.gsub('-', ''))
      elsif date
        (month, day, year) = text.split('/')
        where = sa[:DOB].eq("#{year}-#{month}-#{day}")
      elsif numeric
        where = sa[:PersonalID].eq(text).or(sa[:id].eq(text))
      else
        query = "%#{text.downcase}%"
        where = name_search(sa, :FirstName, query, **kwargs).
          or(name_search(sa, :LastName, query, **kwargs))

        where = nickname_search(where, text)
        where = metaphone_search(where, :FirstName, text)
        where = metaphone_search(where, :LastName, text)
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

    def self.name_search(arel_t, field, text, custom_name_options: {})
      query = arel_t[field].lower.matches(text)
      return with_custom_name_search(query, field, text, **custom_name_options) if  custom_name_options.present?

      query
    end

    def self.with_custom_name_search(where, field, text, association:, klass:, field_map: {})
      column = field_map[field] || field
      return where unless reflect_on_association(association)&.klass == klass

      where.or(klass.arel_table[column].lower.matches(text))
    end
  end
end
