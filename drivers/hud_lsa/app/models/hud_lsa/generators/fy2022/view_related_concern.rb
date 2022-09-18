###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa::Generators::Fy2022::ViewRelatedConcern
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  class_methods do
    def file_prefix
      "#{short_name} #{fiscal_year}"
    end

    def title
      "#{generic_title} - #{fiscal_year}"
    end

    def report_year_slug
      fiscal_year.downcase.delete(' ').to_sym
    end

    def generic_title
      'Longitudinal System Analysis'
    end

    def report_filename
      "#{generic_title} #{filter.coc_code}"
    end

    def short_name
      'LSA'
    end

    def fiscal_year
      'FY 2022'
    end

    def questions
      { 'LSA' => self }
    end

    def allowed_options
      [
        :project_ids,
        :project_group_ids,
        :data_source_ids,
        :coc_code,
        :lsa_scope,
        :start,
        :end,
      ]
    end

    def table_descriptions
      {}.tap do |descriptions|
        questions.each_value do |klass|
          descriptions.merge!(klass.table_descriptions)
        end
      end
    end

    def describe_table(table_name)
      table_descriptions[table_name]
    end

    def table_descriptions
      {
        'LSA' => 'All LSA Data',
      }.freeze
    end
  end

  def url
    hud_reports_lsa_url(self, { host: ENV['FQDN'], protocol: 'https' })
  end
end
