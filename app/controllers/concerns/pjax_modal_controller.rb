###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PjaxModalController
  extend ActiveSupport::Concern

  included do
    layout ->(c) { pjax_request? ? pjax_layout : nil }
    after_action :set_pjax_url, if: :pjax_request?

    def modal_size
      case @modal_size
      when :xl
        'modal-xl'
      when :lg
        'modal-lg'
      else
        ''
      end
    end
    helper_method :modal_size

    def form_html_options
      Hash.new.tap do |result|
        result['data-submits-to-pjax-modal'] = true if pjax_request?
      end
    end
    helper_method :form_html_options

    def redirect_to_with_xhr_redirect(*args)
      if pjax_request?
        Rails.logger.debug args.inspect
        url_args = {}
        if args.first != '/'
          url_args[:controller] = args.first
        end
        url_args.merge(*args.drop(1))
        Rails.logger.debug url_args.inspect
        @redirect = url_for(url_args)
        render "redirect_via_js", layout: "pjax_modal_content"
      else
        redirect_to_without_xhr_redirect(*args)
      end
    end
    alias_method :redirect_to_without_xhr_redirect, :redirect_to
    alias_method :redirect_to, :redirect_to_with_xhr_redirect

    helper_method :pjax_request?
  end

  private

    def pjax_layout
      'pjax_modal_content'
    end

    def pjax_request?
      request.env['HTTP_X_PJAX'].present?
    end

    def set_pjax_url
      response.headers['X-PJAX-URL'] = pjax_url
    end

    def pjax_url
      request.url
    end


end