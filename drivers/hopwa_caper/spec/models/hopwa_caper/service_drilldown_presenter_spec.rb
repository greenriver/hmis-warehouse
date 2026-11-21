###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../generators/fy2026/hopwa_caper_shared_context'

RSpec.describe HopwaCaper::ServiceDrilldownPresenter, type: :model do
  include_context 'HOPWA CAPER shared context'

  let(:strmu_funder) { hud_code(:funding_sources, 'HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance') }
  let(:project) { create_hopwa_project(funder: strmu_funder) }
  let(:report) { create_report([project]) }
  let(:client) { create_client_with_warehouse_link(first_name: 'Sam', last_name: 'Served') }
  let(:identifier_fields) { ['personal_id', 'hmis_enrollment_id', 'destination_client_id', 'service_id'] }

  let(:service_record) do
    enrollment = create_hiv_positive_enrollment(
      client: client,
      project: project,
      entry_date: report_start_date,
      household_id: Hmis::Hud::Base.generate_uuid,
      relationship_to_ho_h: 1,
    )
    create(
      :hud_service,
      enrollment: enrollment,
      record_type: hopwa_financial_assistance,
      type_provided: rental_assistance,
      fa_amount: 125,
      date_provided: report_start_date,
      data_source: data_source,
    )
    run_report(report)
    report.hopwa_caper_services.first
  end

  before do
    grant_project_access(user, create(:role, can_view_hiv_status: true, can_view_client_name: true), [project], mode: :acl)
  end

  context 'with a restricted client' do
    before do
      service_record
      Hmis::Hud::Client.find(client.id).mark_as_restricted!(user: create(:hmis_user, data_source: data_source))
    end

    [:html, :excel].each do |fmt|
      it "redacts every client identifier in #{fmt}" do
        presenter = described_class.new([service_record], report, user, format: fmt)

        expect(presenter.client_restricted?(service_record)).to be(true)
        identifier_fields.each do |field|
          expect(presenter.display_value(service_record, field)).to eq(GrdaWarehouse::PiiProvider::REDACTED)
        end
      end

      it "leaves non-identifying fields unchanged in #{fmt}" do
        presenter = described_class.new([service_record], report, user, format: fmt)

        expect(presenter.display_value(service_record, 'fa_amount')).to eq(service_record.fa_amount)
        expect(presenter.display_value(service_record, 'date_provided')).to eq(service_record.date_provided)
      end
    end
  end

  context 'with an unrestricted client' do
    it 'shows the real identifiers' do
      presenter = described_class.new([service_record], report, user, format: :excel)

      expect(presenter.client_restricted?(service_record)).to be(false)
      identifier_fields.each do |field|
        expect(presenter.display_value(service_record, field)).to eq(service_record.public_send(field))
      end
      expect(service_record.service_id).to be_present
    end
  end
end
