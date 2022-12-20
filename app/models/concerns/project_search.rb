###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectSearch
  extend ActiveSupport::Concern
  included do
    # Requires a block!
    def self.text_searcher(text, &block)
      return none unless text.present?

      text.strip!
      sa = arel_table
      alpha_numeric = /[[[:alnum:]]-]+/.match(text).try(:[], 0) == text
      numeric = /[\d-]+/.match(text).try(:[], 0) == text

      # Search with OR if there's a comma or space in the search
      if text.include?(',') || text.include?(' ')
        project_texts = text.split(',').map(&:strip).map { |str| str.split(' ').map(&:strip) }.flatten
        where = none

        project_texts.each_with_index do |project_text, i|
          scope = sa[:ProjectName].lower.matches("%#{project_text.downcase}%")
          where = i.zero? ? scope : where.or(scope)
        end
        # Explicitly search for a PersonalID
      elsif alpha_numeric && (text.size == 32 || text.size == 36)
        where = sa[:ProjectID].matches(text.gsub('-', ''))
      elsif numeric
        where = sa[:ProjectID].eq(text).or(sa[:id].eq(text))
      else
        query = "%#{text}%"
        where = sa[:ProjectName].matches(query)
      end

      begin
        # requires a block to calculate which project_ids are acceptable within
        # the search context
        project_ids = block.call(where)
      rescue RangeError
        return none
      end

      where(id: project_ids)
    end
  end
end
