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
  #
  # implicit_action and template_only_action render test_auth/*.html.erb from a temp view
  # path. layout false because the app layout calls route helpers the test routes lack.
  def setup_test_controller(&authorize_config)
    klass = Class.new(ApplicationControllerV2) do
      layout false

      def root_action
        render plain: 'root'
      end

      def guarded_action
        render plain: 'guarded'
      end

      def open_action
        render plain: 'open'
      end

      def mutating_action
        record_side_effect
        render plain: 'mutated'
      end

      def implicit_action
      end

      protected

      def record_side_effect
        # spied on per-example
      end

      def authorize_me?
        # overridden per-example
      end
    end
    klass.class_eval(&authorize_config)
    klass.prepend_view_path(view_dir)

    @controller = klass.new

    stub_const('TestAuthController', klass)
    Rails.application.routes.draw do
      root to: 'test_auth#root_action'
      get 'guarded_action' => 'test_auth#guarded_action'
      get 'open_action' => 'test_auth#open_action'
      post 'mutating_action' => 'test_auth#mutating_action'
      get 'implicit_action' => 'test_auth#implicit_action'
      get 'template_only_action' => 'test_auth#template_only_action'
    end
  end

  let(:view_dir) do
    Dir.mktmpdir.tap do |dir|
      FileUtils.mkdir_p(File.join(dir, 'test_auth'))
      File.write(File.join(dir, 'test_auth', 'implicit_action.html.erb'), 'implicit')
      File.write(File.join(dir, 'test_auth', 'template_only_action.html.erb'), 'template only')
    end
  end
  after(:each) { FileUtils.remove_entry(view_dir) }

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

  context 'with an action no authorize_with covers' do
    before(:each) do
      setup_test_controller { authorize_with(only: :guarded_action) { authorize_me? } }
    end

    it 'raises before the action body runs' do
      allow(@controller).to receive(:record_side_effect)
      expect { post :mutating_action }.to raise_error(AuthorizationNotPerformedError)
      expect(@controller).not_to have_received(:record_side_effect)
    end
  end

  context 'with an uncovered action whose before_action chain halts early' do
    # e.g. a login redirect. send_action is never reached, so the fail-closed check must
    # not raise: the request already ended without running the action.
    it 'does not raise when an earlier before_action redirects' do
      setup_test_controller do
        before_action { redirect_to '/elsewhere' }
        authorize_with(only: :guarded_action) { authorize_me? }
      end
      allow(@controller).to receive(:record_side_effect)
      expect { post :mutating_action }.not_to raise_error
      expect(response).to redirect_to('/elsewhere')
      expect(@controller).not_to have_received(:record_side_effect)
    end

    it 'does not raise when an earlier before_action renders' do
      setup_test_controller do
        before_action { render plain: 'halted', status: :forbidden }
        authorize_with(only: :guarded_action) { authorize_me? }
      end
      allow(@controller).to receive(:record_side_effect)
      expect { post :mutating_action }.not_to raise_error
      expect(response).to have_http_status(:forbidden)
      expect(response.body).to eq('halted')
      expect(@controller).not_to have_received(:record_side_effect)
    end
  end

  context 'with covered actions that have no explicit render' do
    before(:each) do
      setup_test_controller { authorize_with(only: [:implicit_action, :template_only_action]) { authorize_me? } }
      allow(@controller).to receive(:authorize_me?).and_return(true)
    end

    it 'renders an action that renders implicitly' do
      get :implicit_action
      expect(response).to have_http_status(:success)
      expect(response.body).to eq('implicit')
    end

    it 'renders an action that has a template but no method' do
      get :template_only_action
      expect(response).to have_http_status(:success)
      expect(response.body).to eq('template only')
    end
  end

  context 'when several authorize_with rules cover the same action' do
    def setup_and_spy(&authorize_config)
      setup_test_controller(&authorize_config)
      allow(@controller).to receive(:record_side_effect)
    end

    it 'runs the action when every rule authorizes' do
      setup_and_spy do
        authorize_with { true }
        authorize_with(only: :mutating_action) { true }
      end
      post :mutating_action
      expect(response.body).to eq('mutated')
      # positive control: proves the side-effect spy is wired, so the
      # not_to have_received assertions elsewhere are not vacuous
      expect(@controller).to have_received(:record_side_effect)
    end

    it 'denies when a later rule fails after an earlier one authorized' do
      setup_and_spy do
        authorize_with { true }
        authorize_with(only: :mutating_action) { false }
      end
      post :mutating_action
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to be_present
      expect(@controller).not_to have_received(:record_side_effect)
    end

    it 'denies when an earlier rule fails before a later one would authorize' do
      setup_and_spy do
        authorize_with(only: :mutating_action) { false }
        authorize_with { true }
      end
      post :mutating_action
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to be_present
      expect(@controller).not_to have_received(:record_side_effect)
    end
  end

  context 'when the authorization block returns something other than a boolean' do
    before(:each) do
      setup_test_controller { authorize_with { authorize_me? } }
      allow(@controller).to receive(:record_side_effect)
    end

    it 'does not authorize an arbitrary object' do
      allow(@controller).to receive(:authorize_me?).and_return(Object.new)
      expect { post :mutating_action }.to raise_error(TypeError, /must return true or false, got Object/)
      expect(@controller).not_to have_received(:record_side_effect)
    end

    it 'does not authorize nil' do
      allow(@controller).to receive(:authorize_me?).and_return(nil)
      expect { post :mutating_action }.to raise_error(TypeError, /got NilClass/)
      expect(@controller).not_to have_received(:record_side_effect)
    end
  end

  context 'when only:/except: names something that is not an action' do
    it 'raises for a misspelled only: name, before the action body runs' do
      setup_test_controller do
        authorize_with { authorize_me? }
        authorize_with(only: :nonexistent_action) { authorize_me? }
      end
      allow(@controller).to receive(:authorize_me?).and_return(true)
      allow(@controller).to receive(:record_side_effect)
      expect { post :mutating_action }.to raise_error(ArgumentError, /nonexistent_action action could not be found for the authorize_with callback on TestAuthController, but it is listed in its :only option/)
      expect(@controller).not_to have_received(:record_side_effect)
    end

    it 'raises for a misspelled except: name' do
      setup_test_controller { authorize_with(except: :nonexistent_action) { authorize_me? } }
      allow(@controller).to receive(:authorize_me?).and_return(true)
      expect { get :guarded_action }.to raise_error(ArgumentError, /listed in its :except option/)
    end
  end
end
