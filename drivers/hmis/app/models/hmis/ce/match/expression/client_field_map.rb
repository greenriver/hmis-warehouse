# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # FieldMap implementation for GrdaWarehouse::Hud::Client fields
  # This class resolves fields that are columns on the `Client` table or one of its associations.
  class ClientFieldMap
    attr_reader :current_date

    def initialize(current_date: Date.current)
      @current_date = current_date
    end

    def client_query(clients, field)
      callback = all.dig(field.to_sym, :query)
      raise ArgumentError, "Field \"#{field}\" is not supported" unless callback

      callback.call(clients)
    end

    def arel_field(field)
      all.dig(field.to_sym, :arel_field)
    end

    def joins(field)
      all.dig(field.to_sym, :joins)
    end

    # Label for user-facing display of resolved field
    def label_for(field)
      field.humanize
    end

    # Value for user-facing display of resolved field
    def format_for_display(field, value)
      formatted = all.dig(field.to_sym, :format_for_display)&.call(value)
      return value if formatted.nil?

      formatted
    end

    protected

    def arel
      Hmis::ArelHelper
    end

    def all
      @all ||= {
        days_since_last_exit: days_since_last_exit_field,
        veteran_status: veteran_status_field,
        current_age: current_age_field,
        days_homeless: days_homeless_field,
        open_enrollment_project_types: open_enrollment_project_types_field,
        open_enrollment_project_types_excluding_incomplete: open_enrollment_project_types_excluding_incomplete_field,
        open_referral_project_types: open_referral_project_types_field,
      }
    end

    private

    def days_since_last_exit_field
      calculator = LastEnrolledDaysCalculator.new(@current_date)
      {
        query: ->(clients) { calculator.call(clients) },
        joins: [{ hmis_source_clients: { enrollments: :exit } }],
        arel_field: calculator.arel_expression,
        format_for_display: ->(days) { days.nil? ? nil : "#{days} #{'day'.pluralize(days)}" },
      }
    end

    def veteran_status_field
      {
        query: ->(clients) { clients.pluck(:id, :veteran_status).to_h },
        format_for_display: ->(v) { HudUtility2026.veteran_status(v) },
        arel_field: arel.c_t['VeteranStatus'],
      }
    end

    def current_age_field
      calculator = AgeCalculator.new(@current_date)
      {
        query: ->(clients) { calculator.call(clients) },
        arel_field: calculator.arel_expression,
      }
    end

    def days_homeless_field
      {
        query: ->(clients) { HomelessDaysCalculator.new(@current_date).call(clients) },
        format_for_display: ->(days) { days.nil? ? nil : "#{days} #{'day'.pluralize(days)}" },
      }
    end

    def open_enrollment_project_types_field
      {
        query: ->(clients) { project_types_query(clients, Hmis::Hud::Enrollment.open_including_wip, :project) },
        format_for_display: ->(project_type_ids) { project_type_ids.uniq.map { |t| HudUtility2026.project_type(t) } },
      }
    end

    def open_enrollment_project_types_excluding_incomplete_field
      {
        query: ->(clients) { project_types_query(clients, Hmis::Hud::Enrollment.open_excluding_wip, :project) },
        format_for_display: ->(project_type_ids) { project_type_ids.uniq.map { |t| HudUtility2026.project_type(t) } },
      }
    end

    def open_referral_project_types_field
      {
        query: ->(clients) { project_types_query(clients, Hmis::Ce::Referral.active, :target_project) },
        format_for_display: ->(project_type_ids) { project_type_ids.uniq.map { |t| HudUtility2026.project_type(t) } },
      }
    end

    def project_types_query(clients, scope, project_association)
      client_ids = clients.pluck(:id)
      values = scope.joins(client: :warehouse_client_source).
        where(warehouse_clients: { destination_id: client_ids }).
        joins(project_association).
        distinct.
        pluck(arel.wc_t[:destination_id], arel.p_t['ProjectType'])

      result = values.group_by(&:first).transform_values { |rows| rows.map(&:last) }
      client_ids.each { |client_id| result[client_id] ||= [] }
      result
    end
  end
end
