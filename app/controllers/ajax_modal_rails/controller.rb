module AjaxModalRails::Controller
  # This module sets up controllers to load their content in a modal
  # in response to ajax requests.  See ajax-modals.js.coffee for client side details
  #
  # calling render will render a template to the modal
  # and calling redirect_to will trigger a redirect on the underlying page
  #
  # note that inbound links should have `data-loads-in-ajax-modal` attributes
  # and forms should have `data-submits-to-pjax-modal`

  extend ActiveSupport::Concern
  HEADER = 'HTTP_X_AJAX_MODAL'.freeze

  included do
    layout ->(c) { ajax_modal_request? ? ajax_modal_layout : nil } # rubocop:disable Lint/UnusedBlockArgument

    def modal_size
      case @modal_size
      when :xl
        'modal-xl'
      when :lg
        'modal-lg'
      when :xxl
        'modal-xxl'
      else
        ''
      end
    end

    helper_method :modal_size

    def form_html_options
      {}.tap do |result|
        result['data-submits-to-ajax-modal'] = true if ajax_modal_request?
      end
    end

    helper_method :form_html_options

    def redirect_to_with_xhr_redirect(*args)
      if ajax_modal_request?
        flash.merge! args.last if args.length > 1
        render 'ajax_modal_rails/redirect_via_js', layout: ajax_modal_layout, locals: { redirect: url_for(args.first) }
      else
        redirect_to_without_xhr_redirect(*args)
      end
    end

    alias_method :redirect_to_without_xhr_redirect, :redirect_to
    alias_method :redirect_to, :redirect_to_with_xhr_redirect
  end

  def render_close_modal_and_reload_page
    render 'ajax_modal_rails/close_modal_and_reload_page', layout: ajax_modal_layout
  end

  private

  def ajax_modal_layout
    'ajax_modal_content'
  end

  def ajax_modal_request?
    request.env[HEADER].present?
  end
end
