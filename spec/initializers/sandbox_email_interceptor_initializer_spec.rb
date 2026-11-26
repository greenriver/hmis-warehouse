###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'config/initializers/sandbox_email_interceptor.rb' do
  let(:initializer_path) { Rails.root.join('config/initializers/sandbox_email_interceptor.rb').to_s }

  # Loads the initializer with to_prepare captured, then runs the captured block.
  def run_initializer
    prepare_block = nil
    allow(Rails.application.config).to receive(:to_prepare) { |&block| prepare_block = block }
    load initializer_path
    prepare_block.call
  end

  def registered_interceptors
    Mail.class_variable_get(:@@delivery_interceptors)
  end

  before { ActionMailer::Base.unregister_interceptor(SandboxEmailInterceptor) }
  after { ActionMailer::Base.unregister_interceptor(SandboxEmailInterceptor) }

  it 'registers the interceptor when it is enabled' do
    allow(SandboxEmailInterceptor).to receive(:enabled?).and_return(true)

    expect { run_initializer }.to change { registered_interceptors.include?(SandboxEmailInterceptor) }.from(false).to(true)
  end

  it 'does not register the interceptor when it is not enabled' do
    allow(SandboxEmailInterceptor).to receive(:enabled?).and_return(false)

    run_initializer

    expect(registered_interceptors).not_to include(SandboxEmailInterceptor)
  end
end
