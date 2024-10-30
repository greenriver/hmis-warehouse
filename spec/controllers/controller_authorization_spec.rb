require 'rails_helper'

RSpec.describe 'Controller Authorization', type: :controller do
  after(:each) do
    Rails.application.reload_routes!
  end

  let!(:user) { create :user }
  before(:each) do
    sign_in(user)

    klass = Class.new(ApplicationControllerV2) do
      authorize_with(only: :authorized_action) { authorize_me? }

      def unauthorized_action
        render plain: 'unauthorized success'
      end

      def authorized_action
        render plain: 'authorized'
      end

      protected

      def authorize_me?
        # override in test
      end

      def handle_unauthorized_error(_error)
        head :forbidden
      end
    end

    @controller = klass.new

    stub_const('TestAuthController', klass)
    Rails.application.routes.draw do
      get 'unauthorized_action' => 'test_auth#unauthorized_action'
      get 'authorized_action' => 'test_auth#authorized_action'
    end
  end

  it 'enforces authorization' do
    allow(@controller).to receive(:authorize_me?).and_return(false)
    get :authorized_action
    expect(response).to have_http_status(:forbidden)
  end

  it 'allows access when authorized' do
    allow(@controller).to receive(:authorize_me?).and_return(true)
    get :authorized_action
    expect(response).to have_http_status(:success)
  end

  it 'raises when authorization is not performed' do
    expect { get :unauthorized_action }.to raise_error(AuthorizationNotPerformedError)
  end

  it 'does not have access to legacy authorization methods' do
    expect(@controller.respond_to?(:require_can_view_projects!)).to be false
  end
end
