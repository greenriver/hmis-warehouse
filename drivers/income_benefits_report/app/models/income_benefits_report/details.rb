###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  IncomeBenefitsReport::Details
  extend ActiveSupport::Concern
  included do
    def detail_link_base
      "#{section_subpath}details"
    end

    def section_subpath
      "#{self.class.url}/"
    end

    def detail_path_array
      [:details] + report_path_array
    end

    def detail_hash
      {}.merge(hero_counts_data).
        merge(stayer_households_data).
        merge(leaver_households_data).
        merge(stayer_income_sources_data).
        merge(stayer_non_cash_sources_data).
        merge(stayer_insurance_sources_data).
        merge(leaver_income_sources_data).
        merge(leaver_non_cash_sources_data).
        merge(leaver_insurance_sources_data)
    end

    def detail_scope_from_key(key)
      return report_scope.none unless key

      detail = detail_hash[key]
      return report_scope.none unless detail

      # detail[:scope].call.distinct
    end

    def support_title(key)
      detail = detail_hash[key]
      return '' unless detail

      detail[:title] || key
    end

    def header_for(_key)
      headers
    end

    def columns_for(key)
      detail = detail_hash[key]
      return '' unless detail

      detail_data(detail[:scope], detail[:income_relation]).sort_by(&:first)
    end

    private def headers
      client_columns.map { |_, data| data[:title] } +
      income_columns.map { |_, data| data[:title] }
    end

    private def detail_data(scope, income_relation)
      [].tap do |rows|
        scope.preload(income_relation).find_each do |client|
          row = []
          client_columns.each do |column, data|
            row << data[:transformation].call(client.send(column))
          end
          income_columns.each do |column, data|
            row << data[:transformation].call(client&.send(income_relation)&.send(column))
          end
          rows << row
        end
      end
    end

    private def client_columns
      {
        client_id: {
          title: 'Client ID',
          transformation: ->(v) { v },
        },
        first_name: {
          title: 'First Name',
          transformation: ->(v) { v },
        },
        last_name: {
          title: 'Last Name',
          transformation: ->(v) { v },
        },
        dob: {
          title: 'DOB',
          transformation: ->(v) { v },
        },
        age: {
          title: 'Age',
          transformation: ->(v) { v },
        },
        race: {
          title: 'Race',
          transformation: ->(v) { v },
        },
        ethnicity: {
          title: 'Ethnicity',
          transformation: ->(v) { "#{HUD.ethnicity(v)} (#{v})" },
        },
        entry_date: {
          title: 'Entry Date',
          transformation: ->(v) { v },
        },
        move_in_date: {
          title: 'Move-in Date',
          transformation: ->(v) { v },
        },
        exit_date: {
          title: 'Exit Date',
          transformation: ->(v) { v },
        },
        project_name: {
          title: 'Project Name',
          transformation: ->(v) { v },
        },
        household_id: {
          title: 'Household ID',
          transformation: ->(v) { v },
        },
        head_of_household: {
          title: 'Head of Household',
          transformation: ->(v) { yn(v) },
        },
      }
    end

    def income_columns
      cols = []
      cols += [
        [
          :stage,
          {
            title: 'Reporting Stage',
            transformation: ->(v) { v&.titleize || 'No Income Record' },
          },
        ],
        [
          :InformationDate,
          {
            title: 'Information Date',
            transformation: ->(v) { v },
          },
        ],
        [
          :DataCollectionStage,
          {
            title: 'Data Collection Stage',
            transformation: ->(v) { ::HUD.data_collection_stage(v) },
          },
        ],
      ]
      (
        [:IncomeFromAnySource, :TotalMonthlyIncome] +
        ::GrdaWarehouse::Hud::IncomeBenefit::SOURCES.to_a.flatten +
        ::GrdaWarehouse::Hud::IncomeBenefit::NON_CASH_BENEFIT_TYPES +
        ::GrdaWarehouse::Hud::IncomeBenefit::INSURANCE_TYPES
      ).each do |k|
        cols << [
          k,
          {
            title: k,
            transformation: ->(v) { v },
          },
        ]
      end
      cols.to_h
    end
  end
end
