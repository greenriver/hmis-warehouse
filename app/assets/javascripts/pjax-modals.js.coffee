#= require jquery.pjax
#= require namespace

#############
# Ajax modals
#############

$ ->

  class PjaxModal
    constructor: ->
      @modal = $(".modal[data-pjax-modal]")
      @containerAttr = "[data-pjax-modal-container]"
      @container = @modal.find(@containerAttr)
      @linkTriggerAttr = '[data-loads-in-pjax-modal]'
      @linkTriggers = $(@linkTriggerAttr)
      @formTriggerAttr = '[data-submits-to-pjax-modal]'
      @formTriggers = $(@formTriggerAttr)
      @initialPath = window.location.pathname

    listen: ->
      @_registerLoadingIndicator()
      @_registerLinks()
      @_registerForms()
      @_registerClose()

    _registerLoadingIndicator: ->
      $(document).on 'pjax:send', (event) =>
        @reset()
      $(document).on 'pjax:complete', =>
        @modal.find("[data-pjax-modal-loading]").hide()

    _registerLinks: ->
      $(document).pjax @linkTriggerAttr, @containerAttr, timeout: false, push: false, scrollTo: false
      $(document).on 'click', @linkTriggerAttr, (e) =>
        @modal.find("[data-pjax-modal-body]").hide()
        @modal.find("[data-pjax-modal-footer]").hide()
        @open()
        history.pushState({}, 'Modal', $(e.target).attr("href"));

    _registerForms: ->
      $(document).on 'submit', @formTriggerAttr, (evt) =>
        @open()
        $.pjax.submit evt, @containerAttr, timeout: false, push: false, scrollTo: false

    _registerClose: ->
      $('body').on 'click', '[pjax-modal-close]', (e) =>
        history.pushState({}, 'Modal', @initialPath);
        @closeModal()

    closeModal: ->
      @modal.modal('hide')
      @reset()

    open: ->
      @modal.modal('show')

    reset: ->
      @modal.find("[data-pjax-modal-title]").html('')
      @modal.find("[data-pjax-modal-body]").html('')
      @modal.find("[data-pjax-modal-footer]").html('')
      @modal.find("[data-pjax-modal-loading]").show()

  (new PjaxModal).listen()
