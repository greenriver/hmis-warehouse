###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::Tracing
  class Search < ::ModelForm
    include ArelHelper
    attribute :query, String

    def results
      return [] unless query.present?

      existing_cases.preload(:contacts, client: :source_clients).limit(50).to_a.uniq + clients.limit(50).to_a
    end

    def names
      @names ||= begin
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
    end

    # Prefer cases over clients
    def clients
      destination_client_scope.
        where(id: source_clients.select(wc_t[:destination_id])).
        where.not(id: existing_cases.pluck(:client_id))
    end

    def source_clients
      if names.first == names.last
        source_client_scope.where(
          c_t[:FirstName].lower.matches("#{names.first.downcase}%").
          or(c_t[:LastName].lower.matches("#{names.last.downcase}%"))
        )
      else
        source_client_scope.where(
          c_t[:FirstName].lower.matches("#{names.first.downcase}%").
          and(c_t[:LastName].lower.matches("#{names.last.downcase}%"))
        )
      end
    end

    def existing_cases
      query = case_source.
        where(health_emergency: GrdaWarehouse::Config.get(:health_emergency_tracing))
      if names.first == names.last
        query = query.where(
          htca_t[:id].in(Arel.sql(case_contacts.select(:case_id).to_sql)).
          or(htca_t[:first_name].lower.matches("#{names.first.downcase}%")).
          or(htca_t[:last_name].lower.matches("#{names.last.downcase}%")).
          or(htca_t[:aliases].lower.matches("%#{names.last.downcase}%"))
        )
      else
        query = query.where(
          htca_t[:id].in(Arel.sql(case_contacts.select(:case_id).to_sql)).
          or(
            htca_t[:first_name].lower.matches("#{names.first.downcase}%").
            and(htca_t[:last_name].lower.matches("#{names.last.downcase}%"))
          ).
          or(
            htca_t[:aliases].lower.matches("%#{names.first.downcase}%").
            or(htca_t[:aliases].lower.matches("%#{names.last.downcase}%"))
          )
        )
      end
      query
    end

    def case_contacts
      if names.first == names.last
        contact_source.where(
          htco_t[:first_name].lower.matches("#{names.first.downcase}%").
          or(htco_t[:last_name].lower.matches("#{names.last.downcase}%")).
          or(htco_t[:aliases].lower.matches("%#{names.last.downcase}%"))
        )
      else
        contact_source.where(
          htco_t[:first_name].lower.matches("#{names.first.downcase}%").
          and(htco_t[:last_name].lower.matches("#{names.last.downcase}%")).
          or(htco_t[:aliases].lower.matches("%#{names.first.downcase}%")).
          or(htco_t[:aliases].lower.matches("%#{names.last.downcase}%"))
        )
      end
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
