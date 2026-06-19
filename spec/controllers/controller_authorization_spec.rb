###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Controller Authorization', type: :controller do
  after(:each) do
    Rails.application.reload_routes!
  end

  let!(:user) { create :user }
  before(:each) do
    sign_in(user)
  end

  # We don't override handle_unauthorized_error, so the real failure path (redirect +
  # flash alert) is tested. A `root` route is drawn so my_root_path can resolve.
  #
  # Both contexts share the same controller and routes; the only difference is the
  # authorize_with config, passed in as a block. `guarded_action` is the action the
  # filter is expected to cover, `open_action` the one it is expected to skip.
  def setup_test_controller(&authorize_config)
    klass = Class.new(ApplicationControllerV2) do
      def root_action
        render plain: 'root'
      end

      def guarded_action
        render plain: 'guarded'
      end

      def open_action
        render plain: 'open'
      end

      protected

      def authorize_me?
        # overridden per-example
      end
    end
    klass.class_eval(&authorize_config)

    @controller = klass.new

    stub_const('TestAuthController', klass)
    Rails.application.routes.draw do
      root to: 'test_auth#root_action'
      get 'guarded_action' => 'test_auth#guarded_action'
      get 'open_action' => 'test_auth#open_action'
    end
  end

  context 'with authorize_with(only:)' do
    before(:each) do
      setup_test_controller { authorize_with(only: :guarded_action) { authorize_me? } }
    end

    it 'blocks the request and redirects with an alert when the authorization block returns false' do
      allow(@controller).to receive(:authorize_me?).and_return(false)
      get :guarded_action
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to be_present
      expect(response.body).not_to include('guarded')
    end

    it 'allows access and runs the action when the authorization block returns true' do
      allow(@controller).to receive(:authorize_me?).and_return(true)
      get :guarded_action
      expect(response).to have_http_status(:success)
      expect(response.body).to eq('guarded')
    end

    it 'raises when an action performs no authorization check' do
      expect { get :open_action }.to raise_error(AuthorizationNotPerformedError)
    end

    it 'does not have access to legacy authorization methods' do
      expect(@controller.respond_to?(:require_can_view_projects!)).to be false
    end
  end

  context 'with authorize_with(except:)' do
    before(:each) do
      setup_test_controller { authorize_with(except: :open_action) { authorize_me? } }
    end

    it 'runs the authorization block for actions that are not excepted' do
      allow(@controller).to receive(:authorize_me?).and_return(false)
      get :guarded_action
      # a redirect (rather than a fail-closed raise) proves the filter ran here
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to be_present
    end

    it 'skips the authorization block for excepted actions, tripping the fail-closed safety net' do
      # the excepted action runs no authorization, so the net must raise even though
      # the block would have authorized
      allow(@controller).to receive(:authorize_me?).and_return(true)
      expect { get :open_action }.to raise_error(AuthorizationNotPerformedError)
    end
  end
end
