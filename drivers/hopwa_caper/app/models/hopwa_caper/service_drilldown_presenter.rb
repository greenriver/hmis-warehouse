# frozen_string_literal: true

module HopwaCaper
  class ServiceDrilldownPresenter
    Field = Struct.new(:name, :label, :transform, :not_collected, keyword_init: true)

    def initialize(records, report, user, format: :html)
      @records = records
      @report = report
      @user = user
      @format = format
      @services_by_client = {}
      @field_map = service_fields
    end

    def headers
      @field_map.values.map { |f| [f.name, f.label || f.name.humanize] }.to_h
    end

    def display_value(record, field_name)
      field = @field_map[field_name.to_s]
      return record.send(field_name).humanize if field.nil? # Fallback for unexpected fields

      value = record.send(field.name)
      value = record[field.name] if value.nil? && record.respond_to?(:[]) && record.class.column_names.include?(field.name.to_s)

      pii_policy = pii_policy_for(record)

      if value.is_a?(Array)
        items = value.map { |v| transform_value(field, v, record, pii_policy) }
        return items.join("\n") unless html?

        return helpers.content_tag(:ul, class: 'list-unstyled mb-0') do
          items.map { |v| helpers.content_tag(:li, v) }.join.html_safe
        end
      end

      return Reports::ModelApplicationHelper.new.yes_no(value, include_content_tag: html?) if value.in?([true, false])

      transform_value(field, value, record, pii_policy)
    end

    private

    def service_fields
      @service_fields ||= [
        Field.new(name: 'personal_id', label: 'HMIS Personal ID'),
        Field.new(name: 'hmis_enrollment_id', label: 'HMIS Enrollment ID'),
        Field.new(name: 'first_name', transform: ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_name(v, policy: poly) }),
        Field.new(name: 'last_name', transform: ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_name(v, policy: poly) }),
        Field.new(name: 'destination_client_id', label: 'Warehouse Client ID'),
        Field.new(name: 'service_id', label: 'HMIS Service ID'),
        Field.new(name: 'date_provided', label: 'Date Provided'),
        Field.new(name: 'fa_amount', label: 'FA Amount'),
        # Field.new(name: 'service_source', label: 'Service Source'),
        Field.new(name: 'service_category_name', label: 'Service Category'),
        Field.new(name: 'service_type_name', label: 'Service Type'),
      ].index_by(&:name).freeze
    end

    def transform_value(field, value, _record, pii_policy)
      # Treat nil as 99 (Data not collected) for HUD fields that support it
      value = 99 if value.nil? && field.not_collected

      if field.transform.respond_to?(:call)
        field.transform.call(value, pii_policy)
      else
        value
      end
    end

    def pii_policy_for(record)
      @user.reporting_policy_for_project(
        project_id: record.project_id,
        mode: html? ? :browse : :download,
      )
    end

    def html?
      @format == :html
    end

    def helpers
      ActionController::Base.helpers
    end

    def hud_helper
      @hud_helper ||= HudHelper.util('2026')
    end
  end
end
