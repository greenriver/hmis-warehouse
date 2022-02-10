###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::RelationshipCalculations
  extend ActiveSupport::Concern
  included do
    def relationship_detail_hash
      {}.tap do |hashes|
        ::HUD.relationships_to_hoh.each do |key, title|
          hashes["relationship_#{key}"] = {
            title: "Relationship #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client).where(client_id: client_ids_in_relationship(key)).distinct },
          }
        end
      end
    end

    def relationship_count(type)
      relationship_breakdowns[type]&.count&.presence || 0
    end

    def relationship_percentage(type)
      total_count = client_relationships.count
      return 0 if total_count.zero?

      of_type = relationship_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def relationship_data_for_export(rows)
      rows['_Relationship to Head of Household Break'] ||= []
      rows['*Relationship to Head of Household'] ||= []
      rows['*Relationship to Head of Household'] += ['Relationship', 'Count', 'Percentage', nil, nil]
      ::HUD.relationships_to_hoh.each do |id, title|
        rows["_Relationship_data_#{title}"] ||= []
        rows["_Relationship_data_#{title}"] += [
          title,
          relationship_count(id),
          relationship_percentage(id) / 100,
          nil,
        ]
      end
      rows
    end

    private def relationship_breakdowns
      @relationship_breakdowns ||= client_relationships.group_by do |_, v|
        v
      end
    end

    private def client_ids_in_relationship(key)
      relationship_breakdowns[key]&.map(&:first)
    end

    private def client_relationships
      @client_relationships ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          report_scope.joins(:enrollment).order(first_date_in_program: :desc).
            distinct.
            pluck(:client_id, e_t[:RelationshipToHoH], :first_date_in_program).
            each do |client_id, relationship, _|
              clients[client_id] ||= relationship
            end
        end
      end
    end
  end
end
