###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context '2022 confidential setup', shared_context: :metadata do
  FactoryBot.reload
  let!(:data_source) { create :source_data_source, id: 2 }
  let!(:destination_data_source) { create :grda_warehouse_data_source }
  let!(:user) { create :user }
  let!(:clients) do
    [].tap do |c|
      5.times do |i|
        c << create(
          :hud_client,
          data_source_id: data_source.id,
          PersonalID: (i + 1).to_s,
        )
      end
    end
  end
  let!(:destination_clients) do
    clients.map do |client|
      attributes = client.attributes
      attributes['data_source_id'] = destination_data_source.id
      attributes['id'] = nil
      dest_client = GrdaWarehouse::Hud::Client.create(attributes)
      GrdaWarehouse::WarehouseClient.create(
        id_in_source: client.PersonalID,
        data_source_id: client.data_source_id,
        source_id: client.id,
        destination_id: dest_client.id,
      )
    end
  end

  let!(:organizations) do
    [].tap do |organization|
      5.times do |i|
        organization << create(
          :hud_organization,
          OrganizationID: (i + 1).to_s,
          OrganizationName: "Organization Name #{i + 1}",
          OrganizationCommonName: "Organization Common Name #{i + 1}",
          data_source_id: data_source.id,
        )
      end
    end
  end

  let!(:projects) do
    [].tap do |project|
      5.times do |i|
        project << create(
          :hud_project,
          ProjectID: (i + 1).to_s,
          ProjectName: "Project Name #{i + 1}",
          ProjectCommonName: "Project Common Name #{i + 1}",
          OrganizationID: (i + 1).to_s,
          data_source_id: data_source.id,
          ProjectType: 1,
          act_as_project_type: 13,
          computed_project_type: 13,
        )
      end
    end
  end
  let!(:project_cocs) do
    [].tap do |pc|
      5.times do |i|
        pc << create(
          :hud_project_coc,
          data_source_id: data_source.id,
          CoCCode: 'XX-500',
          ProjectID: (i + 1).to_s,
        )
      end
    end
  end
  let!(:inventories) do
    [].tap do |inventory|
      5.times do |i|
        inventory << create(
          :hud_inventory,
          data_source_id: data_source.id,
          CoCCode: 'XX-501',
          ProjectID: (i + 1).to_s,
        )
      end
    end
  end
  let!(:enrollments) do
    [].tap do |e|
      5.times do |i|
        e << create(
          :hud_enrollment,
          data_source_id: data_source.id,
          EntryDate: 2.weeks.ago,
          PersonalID: (i + 1).to_s,
          ProjectID: (i + 1).to_s,
          EnrollmentID: (i + 1).to_s,
        )
      end
    end
  end
  let!(:enrollment_cocs) do
    [].tap do |e|
      5.times do |i|
        e << create(
          :hud_enrollment_coc,
          data_source_id: data_source.id,
          InformationDate: 2.months.ago,
          CoCCode: 'XX-502',
          EnrollmentID: (i + 1).to_s,
          PersonalID: (i + 1).to_s,
          ProjectID: (i + 1).to_s,
        )
      end
    end
  end

  def csv_file_path(exporter, klass)
    File.join(exporter.file_path, klass.hud_csv_file_name)
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 confidential setup', include_shared: true
end
