# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Project, 'project CSV driver extensions' do
  let(:data_source) { create(:source_data_source) }
  let(:organization) { create(:hud_organization, data_source: data_source) }
  let(:project) { create(:hud_project, data_source: data_source, organization: organization) }
  let(:importer_log) { create(:hmis_csv_importer_log, data_source: data_source) }

  describe 'hmis_csv_twenty_twenty extension' do
    it 'exposes FY2020 import and loader associations' do
      aggregate_failures do
        expect(project).to respond_to(:imported_items_2020)
        expect(project).to respond_to(:loaded_items_2020)
        expect(project.association(:imported_items_2020).klass).to eq(HmisCsvTwentyTwenty::Importer::Project)
        expect(project.association(:loaded_items_2020).klass).to eq(HmisCsvTwentyTwenty::Loader::Project)
      end
    end

    it 'resolves imported_item_type to 2020 when FY2020 staging rows exist' do
      HmisCsvTwentyTwenty::Importer::Project.create!(
        staging_attributes(project, importer_log),
      )

      expect(project.imported_item_type(importer_log.id)).to eq('2020')
      expect(project.imported_items_2020.where(importer_log_id: importer_log.id)).to exist
    end
  end

  describe 'convert_to_aggregated!' do
    let(:client) { create(:grda_warehouse_hud_client, data_source: data_source) }
    let!(:enrollment) do
      create(
        :hud_enrollment,
        data_source: data_source,
        ProjectID: project.ProjectID,
        PersonalID: client.PersonalID,
      )
    end
    let!(:exit_record) do
      create(
        :hud_exit,
        data_source: data_source,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
      )
    end

    it 'is defined by the hmis_csv_importer extension, not the FY2020 extension' do
      file, = project.method(:convert_to_aggregated!).source_location

      aggregate_failures do
        expect(file).to end_with('hmis_csv_importer/extensions/grda_warehouse/hud/project_extension.rb')
        expect(
          HmisCsvTwentyTwenty::GrdaWarehouse::Hud::ProjectExtension.instance_methods(false),
        ).not_to include(:convert_to_aggregated!)
      end
    end

    it 'configures unversioned aggregated enrollment import on the data source' do
      project.convert_to_aggregated!

      aggregate_failures do
        expect(project.reload.combine_enrollments).to be true
        expect(data_source.reload.import_aggregators).to eq(
          'Enrollment' => ['HmisCsvImporter::Aggregated::CombineEnrollments'],
        )
      end
    end

    it 'copies warehouse enrollments and exits into unversioned aggregate tables' do
      expect do
        project.convert_to_aggregated!
      end.to change(HmisCsvImporter::Aggregated::Enrollment, :count).by(1).
        and change(HmisCsvImporter::Aggregated::Exit, :count).by(1).
        and not_change(HmisCsvTwentyTwenty::Aggregated::Enrollment, :count).
        and not_change(HmisCsvTwentyTwenty::Aggregated::Exit, :count)

      aggregate = HmisCsvImporter::Aggregated::Enrollment.last
      expect(aggregate.source_type).to eq(enrollment.class.name)
      expect(aggregate.source_id).to eq(enrollment.id)
    end

    it 'uses HudHelper.current_version when slicing HUD attributes for aggregates' do
      version = '2099' # sentinel — not tied to a real FY
      allow(HudHelper).to receive(:current_version).and_return(version)
      allow(GrdaWarehouse::Hud::Enrollment).to receive(:hmis_structure).
        with(version: version).
        and_return(GrdaWarehouse::Hud::Enrollment.hmis_structure)
      allow(GrdaWarehouse::Hud::Exit).to receive(:hmis_structure).
        with(version: version).
        and_return(GrdaWarehouse::Hud::Exit.hmis_structure)

      project.convert_to_aggregated!

      aggregate_failures do
        expect(GrdaWarehouse::Hud::Enrollment).to have_received(:hmis_structure).with(version: version)
        expect(GrdaWarehouse::Hud::Exit).to have_received(:hmis_structure).with(version: version)
        expect(GrdaWarehouse::Hud::Enrollment).not_to have_received(:hmis_structure).with(version: '2020')
        expect(GrdaWarehouse::Hud::Exit).not_to have_received(:hmis_structure).with(version: '2020')
      end
    end

    it 'cannot be run twice for the same project' do
      project.convert_to_aggregated!

      expect { project.convert_to_aggregated! }.to raise_error(/can only be run once/)
    end
  end

  def staging_attributes(project, importer_log)
    {
      ProjectID: project.ProjectID,
      OrganizationID: project.OrganizationID,
      ProjectName: project.ProjectName,
      data_source_id: project.data_source_id,
      importer_log_id: importer_log.id,
      pre_processed_at: Time.current,
      source_id: project.id,
      source_type: project.class.name,
    }
  end
end
