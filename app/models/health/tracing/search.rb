###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health::Tracing
  class Search < ::ModelForm
    include ArelHelper
    attribute :query, String

    def results
      return [] unless query.present?

      existing_cases.preload(:contacts, client: :source_clients).limit(50).to_a + clients.limit(50).to_a
    end

    def names
      if query.include?(',')
        last, first = query.split(',').map(&:strip)
      elsif query.include?(' ')
        first, last = query.split(' ').map(&:strip)
      else
        last = first = query
      end
      OpenStruct.new(
        first: first,
        last: last
      )
    end

    # Prefer cases over clients
    def clients
      destination_client_scope.
        where(id: source_clients.select(wc_t[:destination_id])).
        where.not(id: existing_cases.pluck(:client_id))
    end

    def source_clients
      source_client_scope.where(
        c_t[:FirstName].lower.matches("#{names.first.downcase}%").
        or(c_t[:LastName].lower.matches("#{names.last.downcase}%"))
      )
    end

    def existing_cases
      case_source.
        where(health_emergency: GrdaWarehouse::Config.get(:health_emergency_tracing)).
        where(
          htca_t[:first_name].lower.matches("#{names.first.downcase}%").
          or(htca_t[:last_name].lower.matches("#{names.last.downcase}%"))
        ).
        or(case_source.where(id: case_contacts.select(:case_id)))
    end

    def case_contacts
      contact_source.where(
        htco_t[:first_name].lower.matches("#{names.first.downcase}%").
        or(htco_t[:last_name].lower.matches("#{names.last.downcase}%"))
      )
    end

    private def source_client_scope
      client_source.joins(:warehouse_client_source).searchable
    end

    private def destination_client_scope
      client_source.destination
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def case_source
      Health::Tracing::Case
    end

    def contact_source
      Health::Tracing::Contact
    end
  end
end

