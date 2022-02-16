###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# These should be removed as these are moved to their own drivers
Rails.application.config.hud_reports['ReportGenerators::Pit::Fy2018::Base'] = {
  title: 'Point in Time Count',
  helper: 'hud_reports_pits_path',
}
Rails.application.config.hud_reports['Reports::Lsa::Fy2021::Base'] = {
  title: 'Longitudinal System Analysis',
  helper: 'hud_reports_lsas_path',
}

class Report < ApplicationRecord
  require 'csv'
  include Rails.application.routes.url_helpers

  self.table_name = :reports

  belongs_to :report_results_summary, optional: true
  has_many :report_results

  scope :active, -> do
    where enabled: true
  end

  scope :inactive, -> do
    where enabled: false
  end

  scope :for_type, ->(query) do
    where(arel_table[:type].matches("%::#{sanitize_sql_like(query)}::%"))
  end

  def model_name
    ActiveModel::Name.new self, nil, 'report'
  end

  def last_result(user)
    @last_result ||= ReportResult.viewable_by(user).where(report: self).order(created_at: :desc).limit(1).first
  end

  # Build a two dimensional array of values from the results, return as a csv string
  def as_csv(results, user) # rubocop:disable Lint/UnusedMethodArgument
    csvs = results.keys.group_by { |m| "#{m.to_s.split('_')[0]}_".to_sym }
    c = ''
    csvs.each do |k, v|
      these_results = results.select { |measure, _set| v.include? measure }.map { |key, val| [key.to_s.gsub(k.to_s, '').to_sym, val] }.to_h
      c += individual_as_csv(these_results)
    end
    return c
  end

  def as_xml
    raise 'Abstract method'
  end

  # override as necessary, default takes format
  # {
  #   a1: {title: 'Title', value: 2},
  #   a2: {title: 'Title 2', value: 5},
  #   b1: {title: 'Title 3', value: 3},
  #   b2: {title: 'Title 4', value: 4}
  # }
  # and converts it to a csv in format
  # 2,5
  # 3,4
  def individual_as_csv results
    return unless results.present?

    c = []
    csv = ''
    results.each do |k, v|
      # calculate the column and row
      matches = /([[:lower:]])([[:digit:]])/.match(k)
      raise ReportResultFormatBroken unless matches[2].present?

      column = matches[1].ord - 'a'.ord
      row = matches[2].to_i - 1
      c[row] = [] unless c[row].present?
      c[row][column] = v['value']
    end
    # fill any empty rows with an appropriate array
    len = c.max_by { |r| if r.present? then r.count else 0 end }.count
    c.map! { |row| if row.nil? then Array.new(len) else row end }
    # Generate a useful csv format
    c.each do |row|
      csv += CSV.generate_line(row)
    end
    csv
  end

  # override as necessary, default takes format
  # {
  #   a1: {title: 'Title', value: 2},
  #   a2: {title: 'Title 2', value: 5},
  #   b1: {title: 'Title 3', value: 3},
  #   b2: {title: 'Title 4', value: 4}
  # }
  # and converts it to a csv in format
  #
  # 3,4
  def as_html results
  end

  def has_options? # rubocop:disable Naming/PredicateName
    false
  end

  def has_custom_form? # rubocop:disable Naming/PredicateName
    false
  end

  def title_for_options
    nil
  end

  def results_path
    report_report_results_path self
  end

  def has_project_option? # rubocop:disable Naming/PredicateName
    false
  end

  def has_project_id_option? # rubocop:disable Naming/PredicateName
    false
  end

  def has_data_source_option? # rubocop:disable Naming/PredicateName
    false
  end

  def has_pit_options? # rubocop:disable Naming/PredicateName
    false
  end

  def has_date_range_options? # rubocop:disable Naming/PredicateName
    false
  end

  def has_coc_codes_option? # rubocop:disable Naming/PredicateName
    false
  end

  def has_race_options? # rubocop:disable Naming/PredicateName
    false
  end
end

class ReportDatabaseStructureMissing < StandardError; end

class ReportResultFormatBroken < StandardError; end
