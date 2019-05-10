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
      @title = @modal.find("[data-pjax-modal-title]")
      @body = @modal.find("[data-pjax-modal-body]")
      @footer = @modal.find("[data-pjax-modal-footer]")
      @linkTriggerAttr = '[data-loads-in-pjax-modal]'
      @linkTriggers = $(@linkTriggerAttr)
      @formTriggerAttr = '[data-submits-to-pjax-modal]'
      @formTriggers = $(@formTriggerAttr)
      @loading = @modal.find("[data-pjax-modal-loading]")

    listen: ->
      @_registerLoadingIndicator()
      @_registerLinks()
      @_registerForms()
      @_registerClose()

    _registerLoadingIndicator: ->
      $(document).on 'pjax:send', (event) =>
        @loading.show()
      $(document).on 'pjax:complete', =>
        @loading.hide()

    _registerLinks: ->
      $(document).pjax @linkTriggerAttr, @containerAttr, timeout: false, push: false, scrollTo: false
      $(document).on 'click', @linkTriggerAttr, (e) =>
        @body.hide()
        @footer.hide()
        @open()

    _registerForms: ->
      $(document).on 'submit', @formTriggerAttr, (evt) =>
        @open()
        $.pjax.submit evt, @containerAttr, timeout: false, push: false

    _registerClose: ->
      $('body').on 'click', '[pjax-modal-close]', (e) =>
        @closeModal()

    closeModal: ->
      @modal.modal('hide')
      @reset()

    open: ->
      @modal.modal('show')

    reset: ->
      @title.html("")
      @body.html("")
      @footer.html("")
      @loading.show()

  (new PjaxModal).listen()
