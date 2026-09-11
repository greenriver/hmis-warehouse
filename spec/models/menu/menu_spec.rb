###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Menu::Menu, type: :model do
  let(:context) { double('context') }
  let!(:analytics_report) { create(:op_analytics_report) }
  let(:menu) { described_class.new(user: user, context: context) }

  before do
    allow(Superset).to receive(:available?).and_return(true)
  end

  subject { menu.op_analytics_menu }

  describe '#op_analytics_menu' do
    let(:visibility_check) { subject.visible }

    context 'with an ACL user' do
      let(:user) { create(:acl_user) }

      context 'when user has can_view_all_reports permission' do
        let(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true) }
        let!(:collection) { create(:collection) }

        context 'and is not assigned the superset report' do
          before do
            setup_access_control(user, role, collection)
          end

          it 'cannot see the menu item' do
            expect(visibility_check.call(user)).to be_falsey
          end
        end

        context 'and is assigned the superset report' do
          before do
            collection.set_viewables({ reports: [analytics_report.id] })
            setup_access_control(user, role, collection)
          end

          it 'can see the menu item' do
            expect(visibility_check.call(user)).to be_truthy
          end
        end
      end

      context 'when user has can_view_assigned_reports permission' do
        let(:role) { create(:role, can_view_assigned_reports: true) }
        let!(:collection) { create(:collection) }

        context 'and is not assigned the superset report' do
          before do
            setup_access_control(user, role, collection)
          end

          it 'cannot see the menu item' do
            expect(visibility_check.call(user)).to be_falsey
          end
        end

        context 'and is assigned the superset report' do
          before do
            collection.set_viewables({ reports: [analytics_report.id] })
            setup_access_control(user, role, collection)
          end

          it 'can see the menu item' do
            expect(visibility_check.call(user)).to be_truthy
          end
        end
      end
    end

    context 'with a legacy user' do
      let(:user) { create(:user) }
      let!(:access_group) { create(:access_group) }

      context 'when user has can_view_all_reports permission' do
        let(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true) }

        context 'and is not assigned the superset report' do
          before do
            user.legacy_roles = [role]
          end

          it 'cannot see the menu item' do
            expect(visibility_check.call(user)).to be_falsey
          end
        end

        context 'and is assigned the superset report' do
          before do
            user.legacy_roles = [role]
            access_group.reports << analytics_report
            user.access_groups << access_group
          end

          it 'can see the menu item' do
            expect(visibility_check.call(user)).to be_truthy
          end
        end
      end

      context 'when user has can_view_assigned_reports permission' do
        let(:role) { create(:role, can_view_assigned_reports: true) }

        context 'and is not assigned the superset report' do
          before do
            user.legacy_roles = [role]
          end

          it 'cannot see the menu item' do
            expect(visibility_check.call(user)).to be_falsey
          end
        end

        context 'and is assigned the superset report' do
          before do
            user.legacy_roles = [role]
            access_group.reports << analytics_report
            user.access_groups << access_group
          end

          it 'can see the menu item' do
            expect(visibility_check.call(user)).to be_truthy
          end
        end
      end
    end
  end

  describe '#hmis_menu' do
    let(:user) { create(:acl_user) }
    let!(:hmis_ds) { create(:source_data_source, hmis: 'hmis.example.test', authoritative: true) }

    it 'points at the HMIS host', :devise_only do
      expect(menu.hmis_menu.first.path).to eq('https://hmis.example.test/')
    end

    it "routes through HMIS's own oauth2-proxy sign-in endpoint with the user's connector_id, so Dex skips its connector picker", :jwt_only do
      user.update_column(:last_connector_id, 'keycloak')

      expect(menu.hmis_menu.first.path).to eq('https://hmis.example.test/oauth2/sign_in?connector_id=keycloak&rd=%2F')
    end
  end

  describe '#site_menu' do
    let(:user) { create(:acl_user) }
    let(:context) do
      double(
        'context',
        access_captured_for_setup?: false,
        hmis_admin_visible?: false,
        help_for_path: nil,
        controller_path: 'clients',
        action_name: 'index',
      )
    end

    # Building the tree alone already invokes `visible` for every child item
    # (Item#add_child checks Item#show?, which calls visible.call(user) before
    # adding), but a root-level item pushed straight into the array returned by
    # site_menu -- rather than passed through add_child -- never has its own
    # `visible` invoked just by building the tree. That gap is exactly what let
    # a broken lazy `visible` proc referencing removed health methods slip
    # through, so recurse and call every item's `visible` explicitly.
    def call_every_visible(items, user)
      items.each do |item|
        item.visible&.call(user)
        call_every_visible(item.children.to_a, user) if item.children?
      end
    end

    def collect_titles(items)
      items.flat_map { |item| [item.title] + collect_titles(item.children.to_a) }
    end

    it 'builds the menu tree for a normal ACL user and invokes every visible lambda without raising' do
      tree = menu.site_menu

      expect { call_every_visible(tree, user) }.not_to raise_error
    end

    it 'does not include a Care Hub menu item anywhere in the tree' do
      tree = menu.site_menu

      expect(collect_titles(tree)).not_to include('Care Hub')
    end
  end
end
