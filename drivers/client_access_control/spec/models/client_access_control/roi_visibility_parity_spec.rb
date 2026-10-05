###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Every ACL check that can expose a client through an ROI must agree for the same fixtures, except the
# dashboard gate (Client#show_demographics_to?): it needs the ROI permission on any project, not on one
# where the client is enrolled.
RSpec.describe 'ROI visibility parity', type: :model do
  let(:data_source) { create :source_data_source }
  let(:project) { create :grda_warehouse_hud_project, data_source: data_source }
  let!(:source_client) { create :hud_client, data_source: data_source }
  let!(:enrollment) { create :hud_enrollment, data_source: data_source, client: source_client, project: project }
  let(:destination_data_source) { create :destination_data_source }
  let!(:destination_client) { create :hud_client, data_source: destination_data_source }
  let!(:warehouse_client) { create :warehouse_client, source_id: source_client.id, destination_id: destination_client.id }

  let(:user) { create :acl_user }
  let(:roi_role) { create :role, can_search_clients_with_roi: true, can_view_client_enrollments_with_roi: true }
  let(:collection) { create :collection }
  let(:user_coc) { create :lookup_coc, coc_code: 'XX-500' }
  let(:config_attributes) { {} }

  before do
    GrdaWarehouse::Config.delete_all
    create(config_factory, **config_attributes)
    GrdaWarehouse::Config.invalidate_cache
    collection.set_viewables({ projects: [project.id], coc_codes: [user_coc.id] })
    setup_access_control(user, roi_role, collection)
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  # update_columns skips the sync hooks, so build the row the way the nightly task does
  def set_release!(status, coc_codes: [])
    destination_client.update_columns(housing_release_status: status, consented_coc_codes: coc_codes)
    GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.new._perform(client_ids: [destination_client.id])
  end

  # A fresh user per call: User#policy_for and the client access arbiter are memoized on the instance
  def visibility(as: user)
    viewer = User.find(as.id)
    {
      search: GrdaWarehouse::Hud::Client.searchable_to(viewer).where(id: source_client.id).exists?,
      detail_scope: GrdaWarehouse::Hud::Client.source_visible_to(viewer).where(id: source_client.id).exists?,
      enrollments: GrdaWarehouse::Hud::Enrollment.visible_to(viewer).where(id: enrollment.id).exists?,
      policy: viewer.policy_for(source_client).can_view?,
      demographics: destination_client.reload.show_demographics_to?(viewer),
    }
  end

  def on_every_path(value)
    { search: value, detail_scope: value, enrollments: value, policy: value, demographics: value }
  end

  shared_examples 'shared ROI rules' do
    it 'exposes the client on every path with a full release' do
      set_release!(GrdaWarehouse::Hud::Client.full_release_string)
      expect(visibility).to eq(on_every_path(true))
    end

    it 'reads the ROI row, not the client columns, on every path' do
      create(:client_roi_authorization, destination_client: destination_client, status: 'full')
      expect(destination_client.reload.housing_release_status).to be_nil
      expect(visibility).to eq(on_every_path(true))
    end

    it 'hides the client on every path when only the client columns record a release' do
      destination_client.update_columns(housing_release_status: GrdaWarehouse::Hud::Client.full_release_string, consented_coc_codes: [])
      expect(GrdaWarehouse::ClientRoiAuthorization.where(destination_client_id: destination_client.id)).to be_empty
      expect(visibility).to eq(on_every_path(false))
    end

    it 'exposes the client on every path when the release is limited to a CoC the user holds' do
      set_release!(GrdaWarehouse::Hud::Client.full_release_string, coc_codes: ['XX-500'])
      expect(User.find(user.id).coc_codes).to eq(['XX-500'])
      expect(visibility).to eq(on_every_path(true))
    end

    it 'hides the client on every path when the release is limited to a CoC the user lacks' do
      set_release!(GrdaWarehouse::Hud::Client.full_release_string, coc_codes: ['ZZ-999'])
      expect(GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: destination_client.id).coc_codes).to eq(['ZZ-999'])
      expect(User.find(user.id).coc_codes).to eq(['XX-500'])
      expect(visibility).to eq(on_every_path(false))
    end

    it 'hides the client on every path when the source data source does not obey consent' do
      set_release!(GrdaWarehouse::Hud::Client.full_release_string)
      data_source.update!(obey_consent: false)
      expect(visibility).to eq(on_every_path(false))
    end

    it 'hides the client on every path after its consent form is revoked, including after the nightly rebuild' do
      consent_tag = create :available_file_tag, consent_form: true, name: 'Consent Form', full_release: true
      file = create :client_file, client: destination_client, tags: [consent_tag], effective_date: 5.days.ago
      file.confirm_consent!
      expect(visibility).to eq(on_every_path(true))

      # Same order as Clients::FilesController#update
      destination_client.invalidate_consent!(hr_status: GrdaWarehouse::Config.active_consent_class.revoked_consent_string)
      file.update!(consent_revoked_at: Time.current)
      expect(visibility).to eq(on_every_path(false))

      GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.new._perform(client_ids: [destination_client.id])
      expect(visibility).to eq(on_every_path(false))
    end

    context 'with a second source client in a data source that does not obey consent' do
      let(:other_data_source) { create :source_data_source, obey_consent: false }
      let(:other_project) { create :grda_warehouse_hud_project, data_source: other_data_source }
      let!(:other_source_client) { create :hud_client, data_source: other_data_source }
      let!(:other_enrollment) { create :hud_enrollment, data_source: other_data_source, client: other_source_client, project: other_project }
      let!(:other_warehouse_client) { create :warehouse_client, source_id: other_source_client.id, destination_id: destination_client.id }

      before { collection.set_viewables({ projects: [project.id, other_project.id] }) }

      it 'exposes only the source client and enrollment from the data source that obeys consent' do
        set_release!(GrdaWarehouse::Hud::Client.full_release_string)
        expect(GrdaWarehouse::Hud::Enrollment.visible_to(user).where(id: [enrollment.id, other_enrollment.id]).pluck(:id)).to contain_exactly(enrollment.id)
        expect(GrdaWarehouse::Hud::Client.searchable_to(user).where(id: [source_client.id, other_source_client.id]).pluck(:id)).to contain_exactly(source_client.id)
        expect(user.policy_for(other_source_client).can_view?).to be false
      end
    end

    context 'with direct can_view_clients access to a data source that does not obey consent' do
      let(:view_role) { create :role, can_view_clients: true, can_search_own_clients: true }

      it 'still exposes the client without any release' do
        data_source.update!(obey_consent: false)
        setup_access_control(user, view_role, collection)
        expect(visibility.except(:demographics)).to eq(on_every_path(true).except(:demographics))
      end
    end

    context 'with users who each hold only one of the two ROI permissions' do
      let(:search_user) { create :acl_user }
      let(:view_user) { create :acl_user }

      before do
        setup_access_control(search_user, create(:role, name: 'ROI search only', can_search_clients_with_roi: true), collection)
        setup_access_control(view_user, create(:role, name: 'ROI view only', can_view_client_enrollments_with_roi: true), collection)
        set_release!(GrdaWarehouse::Hud::Client.full_release_string)
      end

      it 'finds the client only in search for the user with can_search_clients_with_roi' do
        expect(visibility(as: search_user)).to eq(on_every_path(false).merge(search: true))
      end

      it 'exposes every path but search to the user with can_view_client_enrollments_with_roi' do
        expect(visibility(as: view_user)).to eq(on_every_path(true).merge(search: false))
      end
    end

    context 'when the user holds the ROI role only on a project where the client has no enrollment' do
      let(:unrelated_project) { create :grda_warehouse_hud_project, data_source: data_source }

      before { collection.set_viewables({ projects: [unrelated_project.id] }) }

      it 'opens only the dashboard, which is not limited to the projects the ROI role covers' do
        set_release!(GrdaWarehouse::Hud::Client.full_release_string)
        expect(visibility).to eq(on_every_path(false).merge(demographics: true))
      end
    end
  end

  context 'with Consent::Default' do
    let(:config_factory) { :config_b }

    include_examples 'shared ROI rules'

    it 'hides the client on every path with a partial (CAS-only) release' do
      set_release!(Consent::Default.partial_release_string)
      expect(GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: destination_client.id).status).to eq('partial')
      expect(visibility).to eq(on_every_path(false))
    end
  end

  context 'with Consent::Implied' do
    let(:config_factory) { :config_va }

    include_examples 'shared ROI rules'
  end

  # What each kind of release exposes, by consent class and release duration.
  # :all is every path, :except_dashboard every path but Client#show_demographics_to?, :none no path.
  describe 'release duration matrix' do
    # A fixed date, so a year-based expiration date is never shifted by Feb 29
    around { |example| travel_to(Date.new(2026, 10, 5)) { example.run } }

    def apply_release!(scenario)
      consent_class = GrdaWarehouse::Config.active_consent_class
      full = { housing_release_status: consent_class.full_release_string }
      attributes = {
        implied_only: { housing_release_status: consent_class.no_release_string },
        full: full.merge(consent_form_signed_on: Date.current, consent_expires_on: 1.year.from_now.to_date),
        full_without_signature: full.merge(consent_expires_on: 1.year.from_now.to_date),
        full_without_expiration: full.merge(consent_form_signed_on: Date.current),
        full_expired: full.merge(consent_form_signed_on: 3.years.ago.to_date, consent_expires_on: Date.yesterday, consent_form_id: 1),
        expires_today: full.merge(consent_form_signed_on: 1.year.ago.to_date, consent_expires_on: Date.current, consent_form_id: 1),
        signed_18_months_ago: full.merge(consent_form_signed_on: 18.months.ago.to_date, consent_expires_on: 1.year.from_now.to_date, consent_form_id: 1),
        # ETO consent has no consent_form_id, and _perform only invalidates expired releases that have one.
        # The expired full row stays until revoke_expired_consent clears the columns and a later rebuild
        # runs, so the client is hidden on every path, even under Consent::Implied.
        full_expired_without_form: full.merge(consent_form_signed_on: 3.years.ago.to_date, consent_expires_on: Date.yesterday),
      }.fetch(scenario)
      destination_client.update_columns(consented_coc_codes: [], **attributes)
      GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.new._perform(client_ids: [destination_client.id])
    end

    def expected_visibility(outcome)
      {
        all: on_every_path(true),
        except_dashboard: on_every_path(true).merge(demographics: false),
        none: on_every_path(false),
      }.fetch(outcome)
    end

    scenarios = [
      :implied_only, :full, :full_without_signature, :full_without_expiration, :full_expired,
      :expires_today, :signed_18_months_ago, :full_expired_without_form
    ]
    {
      ['Consent::Default', :config_b] => {
        'Indefinite' => [:none, :all, :all, :all, :all, :all, :all, :all],
        'Use Expiration Date' => [:none, :all, :all, :none, :none, :all, :all, :none],
        'One Year' => [:none, :all, :none, :all, :none, :all, :none, :none],
        'Two Years' => [:none, :all, :none, :all, :none, :all, :all, :none],
      },
      ['Consent::Implied', :config_va] => {
        'Indefinite' => [:except_dashboard, :all, :all, :all, :all, :all, :all, :all],
        'Use Expiration Date' => [:except_dashboard, :all, :all, :except_dashboard, :except_dashboard, :all, :all, :none],
        'One Year' => [:except_dashboard, :all, :except_dashboard, :all, :except_dashboard, :all, :except_dashboard, :none],
        'Two Years' => [:except_dashboard, :all, :except_dashboard, :all, :except_dashboard, :all, :all, :none],
      },
    }.each do |(consent_class_name, factory), durations|
      context "with #{consent_class_name}" do
        let(:config_factory) { factory }

        durations.each do |release_duration, outcomes|
          context "with a #{release_duration} release duration" do
            let(:config_attributes) { { release_duration: release_duration } }

            scenarios.zip(outcomes).each do |scenario, outcome|
              it "#{scenario.to_s.tr('_', ' ')}: #{outcome.to_s.tr('_', ' ')}" do
                apply_release!(scenario)
                expect(visibility).to eq(expected_visibility(outcome))
              end
            end
          end
        end
      end
    end
  end
end
