###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Active Record Preload API', type: :model do
  let!(:warehouse) { create :destination_data_source }
  let!(:source_ds) { create :source_data_source }
  let!(:warehouse_client) { create :fixed_warehouse_client }
  let!(:client_with_enrollments) { warehouse_client.source }

  let!(:enrollments) do
    create_list(
      :grda_warehouse_hud_enrollment,
      2,
      PersonalID: client_with_enrollments.PersonalID,
      data_source_id: client_with_enrollments.data_source_id,
    )
  end
  let!(:services) do
    build_list(
      :hud_service,
      4,
      PersonalID: client_with_enrollments.PersonalID,
      EnrollmentID: enrollments.first.EnrollmentID,
      data_source_id: client_with_enrollments.data_source_id,
    ) do |record, i|
      record.DateProvided = '2022-01-01'.to_date + (i * 5.days)
      record.save!
    end
  end

  describe 'preloads work as expected' do
    it '4 services are created' do
      expect(GrdaWarehouse::Hud::Service.count).to eq(4)
    end
    it '2 services are between 2022-01-02 and 2022-01-15' do
      expect(GrdaWarehouse::Hud::Service.where(DateProvided: '2022-01-02'.to_date .. '2022-01-15'.to_date).count).to eq(2)
    end
    it 'when preloading, one enrollment has 4 services' do
      expect(GrdaWarehouse::Hud::Enrollment.preload(:services).first.services.count).to eq(4)
    end
    it 'when using includes/references with a scope, only two services are included' do
      s_t = GrdaWarehouse::Hud::Service.arel_table
      scope = s_t[:DateProvided].eq(nil).or(s_t[:DateProvided].between('2022-01-02'.to_date .. '2022-01-15'.to_date))
      enrollments = GrdaWarehouse::Hud::Enrollment.includes(:services).references(:services).where(scope).to_a
      expect(enrollments.first.services.to_a.count).to eq(2)
    end
    # NOTE: it is expected this API will change in Rails 7, this is a canary test meant to catch that
    it 'when poisoning the preload with a scope, only two services are included' do
      scope = GrdaWarehouse::Hud::Service.where(DateProvided: '2022-01-02'.to_date .. '2022-01-15'.to_date)
      enrollments = GrdaWarehouse::Hud::Enrollment.all
      ::ActiveRecord::Associations::Preloader.new.preload(enrollments, :services, scope)
      enrollments.each { |record| record.public_send(:services) }
      expect(enrollments.first.services.to_a.count).to eq(2)
    end
  end
end
