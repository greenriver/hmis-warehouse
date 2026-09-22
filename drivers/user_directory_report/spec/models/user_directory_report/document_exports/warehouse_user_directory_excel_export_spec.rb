###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'roo'

# The xlsx download behind the Warehouse User Directory report: one sheet of active
# warehouse users and one of inactive, with the same columns the html listing shows.
#
RSpec.describe UserDirectoryReport::DocumentExports::WarehouseUserDirectoryExcelExport, type: :model do
  let(:reader) { create(:acl_user, first_name: 'Report', last_name: 'Reader') }
  let(:collection) { create(:collection) }

  # The user whose row the column assertions read. Named distinctly so the row can be
  # found by name, and so a name assertion cannot match some other user's row.
  let!(:listed_user) { create(:acl_user, first_name: 'Directory', last_name: 'Listing') }

  # The row that must stay blank in the HMIS column. Without it, "no check for a user
  # without access" would pass even if the column were filled in unconditionally.
  let!(:no_access_user) { create(:acl_user, first_name: 'NoHmis', last_name: 'Access') }

  let(:export) { described_class.new(user_id: reader.id) }

  # Wires up the user_group -> access_control -> collection -> data source chain that
  # Hmis::User.accessible_hmis_data_source_ids_by_user_id walks. Mirrors the helper in
  # the request spec for this report.
  def grant_hmis_access(target_user, data_source)
    hmis_user_group = create(:hmis_user_group)
    hmis_user_group.add(target_user.related_hmis_user(data_source))
    create(
      :hmis_access_control,
      role: create(:hmis_role),
      user_group: hmis_user_group,
      access_group: create(:hmis_access_group, with_entities: [data_source]),
    )
  end

  # Generates the spreadsheet and reads it back, so every assertion below is made against
  # the bytes a user would download rather than against the column definitions.
  def workbook
    @workbook ||= begin
      export.perform
      file = Tempfile.new(['warehouse_user_directory', '.xlsx'])
      begin
        file.binmode
        file.write(export.file_data)
        file.close
        Roo::Excelx.new(file.path)
      ensure
        file.unlink
      end
    end
  end

  def headers(sheet_name)
    workbook.sheet(sheet_name).row(1)
  end

  # The row for one user, as { column title => cell }. Cells are compared as strings so
  # an empty cell reads as '' whether the writer stored '' or nothing at all.
  def row_for(sheet_name, user_name)
    sheet = workbook.sheet(sheet_name)
    titles = sheet.row(1)
    row = (2..sheet.last_row).map { |number| sheet.row(number) }.detect { |cells| cells.first == user_name }
    return nil unless row

    titles.each_with_index.to_h { |title, index| [title, row[index].to_s] }
  end

  def user_names(sheet_name)
    sheet = workbook.sheet(sheet_name)
    (2..sheet.last_row).map { |number| sheet.row(number).first }
  end

  describe '#authorized?' do
    it 'is true for a reader who can view reports' do
      setup_access_control(reader, create(:role, can_view_assigned_reports: true), collection)

      expect(export.authorized?).to eq(true)
    end

    it 'is false for a reader with no report permission' do
      setup_access_control(reader, create(:role, can_view_clients: true), collection)

      expect(export.authorized?).to eq(false)
    end
  end

  describe '#perform' do
    it 'writes both sheets, splitting users by active status' do
      inactive_user = create(:acl_user, first_name: 'Retired', last_name: 'Person', active: false)

      aggregate_failures do
        expect(user_names('Active Warehouse Users')).to include('Directory Listing')
        expect(user_names('Active Warehouse Users')).not_to include('Retired Person')
        expect(user_names('Inactive Warehouse Users')).to contain_exactly('Retired Person')
        expect(inactive_user.reload.active).to eq(false)
      end
    end

    it 'labels the status column per sheet' do
      create(:acl_user, first_name: 'Retired', last_name: 'Person', active: false)

      aggregate_failures do
        expect(row_for('Active Warehouse Users', 'Directory Listing')['Status']).to eq('Active')
        expect(row_for('Inactive Warehouse Users', 'Retired Person')['Status']).to eq('Inactive')
      end
    end

    it 'fills each column of a user row' do
      # Pins the header-to-cell mapping: every column reads from the user it names. A
      # column inserted or reordered without updating the row builder moves these values.
      agency = create(:agency, name: 'Housing Partners')
      listed_user.update!(agency: agency, phone: '555-0100')
      setup_access_control(listed_user, create(:role, name: 'Directory Role'), collection)

      row = row_for('Active Warehouse Users', 'Directory Listing')

      aggregate_failures do
        expect(row['Name']).to eq('Directory Listing')
        expect(row['Email']).to eq(listed_user.email)
        expect(row['Phone']).to eq('555-0100')
        expect(row['Agency']).to eq('Housing Partners')
        expect(row['Roles']).to eq('Directory Role')
      end
    end

    it 'omits the phone of a user who keeps it out of the directory' do
      listed_user.update!(phone: '555-0100', exclude_phone_from_directory: true)

      expect(row_for('Active Warehouse Users', 'Directory Listing')['Phone']).to eq('')
    end
  end

  describe 'the HMIS access column' do
    # ENABLE_HMIS_API is set for the spec container, so both halves of the gate are
    # stubbed rather than left to the environment -- otherwise these two examples would
    # pass or fail depending on where they run.
    it 'is absent when HMIS is not enabled' do
      # An HMIS data source with a grant on it exists, so the column's absence is
      # attributable to the enabled check rather than to there being nothing to report.
      data_source = create(:hmis_data_source, name: 'Solo Data Source')
      grant_hmis_access(listed_user, data_source)
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(false)

      aggregate_failures do
        expect(headers('Active Warehouse Users')).
          to eq(['Name', 'Email', 'Phone', 'Agency', 'Roles', 'Status', 'Last Login'])
        expect(workbook.sheet('Active Warehouse Users').row(2)).not_to include('Yes')
      end
    end

    it 'is absent when HMIS is enabled but no HMIS data source is configured' do
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)

      expect(headers('Active Warehouse Users')).
        to eq(['Name', 'Email', 'Phone', 'Agency', 'Roles', 'Status', 'Last Login'])
    end

    describe 'with a single HMIS data source' do
      before { allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true) }

      let!(:hmis_data_source) { create(:hmis_data_source, name: 'Solo Data Source') }

      it 'says Yes for a user with access, and nothing for one without' do
        grant_hmis_access(listed_user, hmis_data_source)

        aggregate_failures do
          expect(row_for('Active Warehouse Users', 'Directory Listing')['HMIS Access']).to eq('Yes')
          expect(row_for('Active Warehouse Users', 'NoHmis Access')['HMIS Access']).to eq('')
        end
      end

      it 'reports the access of an inactive user too' do
        inactive_user = create(:acl_user, first_name: 'Retired', last_name: 'Person', active: false)
        grant_hmis_access(inactive_user, hmis_data_source)

        expect(row_for('Inactive Warehouse Users', 'Retired Person')['HMIS Access']).to eq('Yes')
      end
    end

    describe 'with several HMIS data sources' do
      before { allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true) }

      let!(:first_data_source) { create(:hmis_data_source, name: 'First HMIS') }
      let!(:second_data_source) { create(:hmis_data_source, name: 'Second HMIS') }

      it 'names only the data sources the user can reach' do
        grant_hmis_access(listed_user, second_data_source)

        aggregate_failures do
          expect(row_for('Active Warehouse Users', 'Directory Listing')['HMIS Access']).to eq('Second HMIS')
          expect(row_for('Active Warehouse Users', 'NoHmis Access')['HMIS Access']).to eq('')
        end
      end

      it 'names every data source a user can reach' do
        grant_hmis_access(listed_user, first_data_source)
        grant_hmis_access(listed_user, second_data_source)

        expect(row_for('Active Warehouse Users', 'Directory Listing')['HMIS Access'].split('; ')).
          to contain_exactly('First HMIS', 'Second HMIS')
      end
    end
  end
end
