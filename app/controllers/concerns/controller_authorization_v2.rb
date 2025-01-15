###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ControllerAuthorizationV2
  extend ActiveSupport::Concern

  included do
    after_action :ensure_authorized
  end

  class_methods do
    def authorize_with(only: nil, except: nil, &block)
      before_action only: only, except: except do |controller|
        controller.instance_variable_set(:@authorization_performed, true)
        controller.send(:not_authorized!) unless instance_exec(&block)
      end
    end
  end

  private

  def ensure_authorized
    raise AuthorizationNotPerformedError unless @authorization_performed
  end
end
