###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# A column whose name looks like PII must be declared with pii_attr on a model
# for its table, or be allow-listed here with a reason. Covers the warehouse,
# reporting and app databases. Tables without a model are not checked.
RSpec.describe 'PII attribute catalog' do
  # Matched against the column name split into snake_case words (FirstName -> first_name).
  PII_COLUMN_PATTERN = /(\A|_)(first_name|last_name|middle_name|ssn|dob|date_of_birth|birth_date|birthdate|emails?|phones?|street\d*|zip(code)?\d*|postal)(_|\z)/

  # Columns that match the pattern but hold a flag, count, code, or secret instead of a value.
  NON_VALUE_PATTERN = Regexp.union(
    /(dob|ssn)_(data_)?(quality|complete|missing|not_collected|partial|refused|after_entry_date|error_count|error_rate)/, # data-quality measures
    /(to|from|previous|in)_street|street_(essh|es_sh|outreach|last_night)/, # homelessness history, not an address
    /_iv\z/, # encryption initialization vectors
    /zip_(file|password)|encrypted_zip/, # archive files and their passwords
    /\Acan_view_|show_partial_ssn|dob_selection_method|email_(type|schedule)|default_lms_email|exclude_phone/, # settings and permissions
  )

  # Allowed by column name on any table.
  ALLOWED_COLUMNS = {
    'ZIP' => 'project site address, not client data',
    'Zip' => 'project site address, not client data',
    'deleted_zip_override' => 'project site address override',
    'EmailSocialMedia' => 'integer HUD follow-up code',
    'SourceContactEmail' => 'data source contact person, not a client',
    'SourceContactPhone' => 'data source contact person, not a client',
  }.freeze

  # Allowed by [table, column].
  ALLOWED = {
    ['client_searchable_names', 'last_name'] => 'view over Client; scrubbed with it',
    ['eccovia_case_managers', 'first_name'] => 'staff directory',
    ['eccovia_case_managers', 'last_name'] => 'staff directory',
    ['eccovia_case_managers', 'email'] => 'staff directory',
    ['eccovia_case_managers', 'phone'] => 'staff directory',
    ['eto_api_configs', 'email'] => 'integration account',
    ['external_reporting_cohort_permissions', 'email'] => 'user access grant',
    ['external_reporting_project_permissions', 'email'] => 'user access grant',
    ['configs', 'support_contact_email'] => 'system configuration',
    ['financial_providers', 'zip_code'] => 'vendor address',
    ['hud_report_hic_project_cocs', 'Zip'] => 'project site address',
    ['hud_report_instances', 'zip_file'] => 'attached report file, not scrubbed (level 4)',
    ['import_logs', 'zip'] => 'import file reference',
    ['account_requests', 'email'] => 'prospective staff user',
    ['account_requests', 'first_name'] => 'prospective staff user',
    ['account_requests', 'last_name'] => 'prospective staff user',
    ['account_requests', 'phone'] => 'prospective staff user',
    ['youth_intakes', 'owns_cell_phone'] => 'boolean flag',
    ['users', 'talent_lms_email'] => 'staff account; the users table is excluded from scrubbing',
  }.freeze

  def self.tokenized(column)
    column.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
  end

  def self.pii_named?(column)
    words = tokenized(column)
    PII_COLUMN_PATTERN.match?(words) && !NON_VALUE_PATTERN.match?(words)
  end

  def declared_columns(model)
    model.pii_attributes_config.keys.map { |name| (model.attribute_aliases[name.to_s] || name).to_s }
  end

  it 'has pii_attr or an allow-list reason for every PII-named column on a modeled table' do
    Rails.application.eager_load! unless Rails.application.config.eager_load

    violations = [GrdaWarehouseBase, ReportingBase, ApplicationRecord].flat_map do |base|
      db_name = base.connection_db_config.name
      models = ActiveRecord::Base.descendants.select do |model|
        !model.abstract_class? &&
          model.name&.safe_constantize == model &&
          model.connection_db_config.name == db_name &&
          model.table_exists?
      end

      models.group_by(&:table_name).flat_map do |table, table_models|
        declared = table_models.flat_map { |model| model.try(:stores_pii?) ? declared_columns(model) : [] }
        table_models.first.column_names.filter_map do |column|
          next unless self.class.pii_named?(column)
          next if declared.include?(column) || ALLOWED.key?([table, column]) || ALLOWED_COLUMNS.key?(column)

          "#{db_name}: #{table}.#{column}"
        end
      end

    end

    expect(violations.sort).to eq([])
  end
end
