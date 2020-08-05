###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv'
require 'soundex'
module Export::HmisTwentyTwenty::Shared
  extend ActiveSupport::Concern
  included do
    include NotifierConfig
    include ArelHelper

    # Date::DATE_FORMATS[:default] = "%Y-%m-%d"
    # Time::DATE_FORMATS[:default] = "%Y-%m-%d %H:%M:%S"
    # DateTime::DATE_FORMATS[:default] = "%Y-%m-%d %H:%M:%S"

    attr_accessor :file_path

    after_initialize do
      setup_notifier('HMIS Exporter 2020')
    end
  end

  def export_to_path(export_scope:, path:, export:)
    reset_lookups
    export_path = File.join(path, self.class.file_name)
    export_id = export.export_id
    CSV.open(export_path, 'wb', force_quotes: true) do |csv|
      csv << clean_headers(hud_csv_headers)
      export_scope = export_scope.with_deleted if paranoid? && export.include_deleted

      columns = columns_to_pluck

      # Find all of the primary ids
      # It is much faster to do the complicated query with correlated sub-queries once
      # and pluck the ids to conserve memory, and then go back and pull the correct records
      # by id, than it is to loop over batches that each have to re-calculate the sub-queries
      ids = ids_to_export(export_scope: export_scope)
      ids.in_groups_of(100_000, false) do |id_group|
        batch = self.class.where(id: id_group).pluck(*columns)
        # export_scope.pluck_in_batches(*columns, batch_size: 100_000) do |batch|
        batch.map do |row|
          data_source_id = row.last
          row = Hash[hud_csv_headers.zip(row)]
          row[:ExportID] = export_id
          csv << clean_row(row: row, export: export, data_source_id: data_source_id).values
        end
      end
    end

    # Do any appropriate cleanup, currently only implemented for clients
    post_process_export_file(export_path)
  end

  def ids_to_export(export_scope:)
    export_scope.distinct.pluck(:id)
  end

  def reset_lookups
    @enrollment_lookup = nil
    @project_lookup = nil
    @organization_lookup = nil
    @user_lookup = nil
    @client_lookup = nil
    @dest_client_lookup = nil
    @project_type_overridden_to_psh = nil
  end

  # Override as necessary
  def clean_headers(headers)
    headers
  end

  # Override as necessary
  def apply_overrides(row, data_source_id:) # rubocop:disable Lint/UnusedMethodArgument
    row
  end

  # Override as necessary
  def post_process_export_file(export_path)
  end

  # Override as necessary
  def clean_row(row:, export:, data_source_id:)
    # allow each class to cleanup it's own data
    row = apply_overrides(row, data_source_id: data_source_id)

    # Override source IDs with WarehouseIDs where they come from other tables

    # EnrollmentID needs to go before PersonalID because it
    # needs access to the source client
    row[:EnrollmentID] = enrollment_export_id(row[:EnrollmentID], row[:PersonalID], data_source_id) if row[:EnrollmentID].present?
    row[:PersonalID] = client_export_id(row[:PersonalID], data_source_id) if row[:PersonalID].present?
    row[:ProjectID] = project_export_id(row[:ProjectID], data_source_id) if row[:ProjectID].present?
    row[:OrganizationID] = organization_export_id(row[:OrganizationID], data_source_id) if row[:OrganizationID].present?
    if row[:UserID].present?
      row[:UserID] = user_export_id(row[:UserID], data_source_id)
      note_user_id(export: export, user_id: row[:UserID])
    end

    if export.faked_pii
      export.fake_data.fake_patterns.each_key do |k|
        row[k] = export.fake_data.fetch(field_name: k, real_value: row[k]) if row[k].present?
      end
      row # rubocop:disable Style/IdenticalConditionalBranches
    elsif export.hash_status == 4
      row[:FirstName] = Digest::SHA256.hexdigest(Soundex.new(row[:FirstName]).soundex) if row[:FirstName].present?
      row[:LastName] = Digest::SHA256.hexdigest(Soundex.new(row[:LastName]).soundex) if row[:LastName].present?
      row[:MiddleName] = Digest::SHA256.hexdigest(Soundex.new(row[:MiddleName]).soundex) if row[:MiddleName].present?
      if row[:SSN].present?
        padded_ssn = row[:SSN].rjust(9, 'x')
        last_four =  padded_ssn.last(4)
        digested_ssn = Digest::SHA256.hexdigest(padded_ssn)
        row[:SSN] = "#{last_four}#{digested_ssn}"
      end
      row # rubocop:disable Style/IdenticalConditionalBranches
    else
      row # rubocop:disable Style/IdenticalConditionalBranches
    end
    row
  end

  # All HUD Keys will need to be replaced with our IDs to make them unique across data sources.
  def columns_to_pluck
    @columns_to_pluck ||= begin
      columns = hud_csv_headers.map do |k|
        case k
        when self.class.hud_key.to_sym
          Arel.sql(self.class.arel_table[:id].as(self.class.connection.quote_column_name(self.class.hud_key)).to_sql)
        else
          Arel.sql(self.class.arel_table[k].as("#{k}_".to_s).to_sql)
        end
      end
      columns << :data_source_id
      columns
    end
  end

  def export_enrollment_related!(enrollment_scope:, project_scope:, path:, export:) # rubocop:disable Lint/UnusedMethodArgument
    case export.period_type
    when 3
      export_scope = self.class.where(enrollment_exists_for_model(enrollment_scope))
      export_scope = export_scope.where(self.class.arel_table[:DateProvided].lteq(export.end_date)) if self.class.column_names.include?('DateProvided')
      export_scope = export_scope.where(self.class.arel_table[:InformationDate].lteq(export.end_date)) if self.class.column_names.include?('InformationDate')
    when 1
      export_scope = self.class.where(enrollment_exists_for_model(enrollment_scope)).modified_within_range(range: (export.start_date..export.end_date))
    end

    if export.include_deleted || export.period_type == 1
      join_tables = { enrollment_with_deleted: [{ client_with_deleted: :warehouse_client_source }] }
    else
      join_tables = { enrollment: [:project, { client: :warehouse_client_source }] }
    end

    if self.class.column_names.include?('ProjectID')
      if export.include_deleted || export.period_type == 1
        join_tables[:enrollment_with_deleted] << :project_with_deleted
      else
        join_tables[:enrollment] << :project
      end
    end
    export_scope = export_scope.joins(join_tables)

    export_to_path(
      export_scope: export_scope,
      path: path,
      export: export,
    )
  end

  def export_project_related!(project_scope:, path:, export:)
    case export.period_type
    when 3
      export_scope = self.class.where(project_exits_for_model(project_scope))
    when 1
      export_scope = self.class.where(project_exits_for_model(project_scope)).modified_within_range(range: (export.start_date..export.end_date))
    end
    export_to_path(
      export_scope: export_scope,
      path: path,
      export: export,
    )
  end

  def note_user_id(export:, user_id:)
    export.user_ids ||= Set.new
    export.user_ids << user_id
  end

  # Load some lookup tables so we don't have
  # to join when exporting, that can be very slow
  def enrollment_export_id(project_entry_id, personal_id, data_source_id)
    return project_entry_id if is_a? GrdaWarehouse::Hud::Enrollment

    @enrollment_lookup ||= GrdaWarehouse::Hud::Enrollment.pluck(:EnrollmentID, :PersonalID, :data_source_id, :id).
      map do |e_id, pers_id, ds_id, id|
        [[e_id, pers_id, ds_id], id]
      end.to_h
    @enrollment_lookup[[project_entry_id, personal_id, data_source_id]]
  end

  def project_export_id(project_id, data_source_id)
    return project_id if is_a? GrdaWarehouse::Hud::Project

    @project_lookup ||= GrdaWarehouse::Hud::Project.
      pluck(:ProjectID, :data_source_id, :id).
      map do |p_id, ds_id, id|
        [[p_id, ds_id], id]
      end.to_h
    @project_lookup[[project_id, data_source_id]]
  end

  def project_type_overridden_to_psh?(project_id, data_source_id)
    @psh_types ||= GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
    return project_type_overridden_as_ph? if is_a? GrdaWarehouse::Hud::Project

    @project_type_overridden_to_psh ||= GrdaWarehouse::Hud::Project.all.
      map do |project|
        [
          [project.ProjectID, project.data_source_id],
          project.project_type_overridden_as_ph?,
        ]
      end.to_h
    @project_type_overridden_to_psh[[project_id, data_source_id]]
  end

  # We can only safely override if the project only has one CoCCode
  def enrollment_coc_from_project_coc(project_id, data_source_id)
    available_overrides = project_cocs_for_project(project_id, data_source_id)
    return available_overrides.first if available_overrides.count == 1

    nil
  end

  def project_cocs_for_project(project_id, data_source_id)
    @project_cocs_for_project ||= begin
      cocs = {}
      GrdaWarehouse::Hud::ProjectCoc.
        pluck(:ProjectID, :CoCCode, :hud_coc_code, :data_source_id).
        each do |p_id, coc_code, hud_coc_code, ds_id|
        cocs[[p_id, ds_id]] ||= []
        # use the override if set
        cocs[[p_id, ds_id]] << hud_coc_code || coc_code
      end
      cocs
    end
    # Return the unique set of possible CoCCodes
    @project_cocs_for_project[[project_id, data_source_id]].uniq
  end

  def organization_export_id(organization_id, data_source_id)
    return organization_id if is_a? GrdaWarehouse::Hud::Organization

    @organization_lookup ||= GrdaWarehouse::Hud::Organization.pluck(:OrganizationID, :data_source_id, :id).
      map do |o_id, ds_id, id|
        [[o_id, ds_id], id]
      end.to_h
    @organization_lookup[[organization_id, data_source_id]]
  end

  def user_export_id(user_id, data_source_id)
    return user_id if is_a? GrdaWarehouse::Hud::User

    @user_lookup ||= GrdaWarehouse::Hud::User.pluck(:UserID, :data_source_id, :id).
      map do |u_id, ds_id, id|
        [[u_id, ds_id], id]
      end.to_h
    # UserID cannot be null, so we'll  return the string we have
    # even if we can't find a use record
    @user_lookup[[user_id, data_source_id]] || user_id
  end

  def client_export_id(personal_id, data_source_id)
    # lookup by warehouse client connection
    if is_a? GrdaWarehouse::Hud::Client
      @dest_client_lookup ||= begin
        GrdaWarehouse::WarehouseClient.
          pluck(:source_id, :destination_id, :data_source_id).
          map do |source_id, destination_id, ds_id|
          [[source_id.to_s, ds_id], destination_id.to_s]
        end.to_h
      end
      return @dest_client_lookup[[personal_id, data_source_id]]
    else
      # lookup by personal id
      @client_lookup ||= begin
        GrdaWarehouse::Hud::Client.source.
          joins(:warehouse_client_source).
          pluck(:PersonalID, Arel.sql(wc_t[:destination_id].to_sql), Arel.sql(wc_t[:data_source_id].to_sql)).
          map do |source_id, destination_id, ds_id|
            [[source_id.to_s, ds_id], destination_id.to_s]
          end.to_h
      end
    end
    @client_lookup[[personal_id, data_source_id]]
  end

  def project_exits_for_model(project_scope)
    project_scope.where(
      p_t[:ProjectID].eq(self.class.arel_table[:ProjectID]).
      and(p_t[:data_source_id].eq(self.class.arel_table[:data_source_id])),
    ).arel.exists
  end

  def enrollment_exists_for_model(enrollment_scope)
    enrollment_scope.where(
      e_t[:PersonalID].eq(self.class.arel_table[:PersonalID]).
      and(e_t[:EnrollmentID].eq(self.class.arel_table[:EnrollmentID])).
      and(e_t[:data_source_id].eq(self.class.arel_table[:data_source_id])),
    ).arel.exists
  end
end
