#= require jquery.pjax
#= require namespace

#############
# Ajax modals
#############

$ ->

  class PjaxModal
    constructor: ->
      @modal = $(".modal[data-pjax-modal]")
      @container = @modal.find("[data-pjax-modal-container]")
      @title = @modal.find("[data-pjax-modal-title]")
      @body = @modal.find("[data-pjax-modal-body]")
      @footer = @modal.find("[data-pjax-modal-footer]")
      @linkTriggers = $('[data-loads-in-pjax-modal]')
      @formTriggers = $('[data-submits-to-pjax-modal]')
      @loading = @modal.find("[data-pjax-modal-loading]")

    listen: ->
      @_registerLoadingIndicator()
      @_registerLinks()
      @_registerForms()
      @_registerClose()

    _registerLoadingIndicator: ->
      $(document).on 'pjax:send', =>
        @loading.show()
      $(document).on 'pjax:complete', =>
        @loading.hide()

    _registerLinks: ->
      $(document).pjax @linkTriggers.selector, @container.selector, timeout: false, push: false
      $(document).on 'click', @linkTriggers.selector, (e) =>
        @body.hide()
        @footer.hide()
        @open()

    _registerForms: ->
      $(document).on 'submit', @formTriggers.selector, (evt) =>
        @open()
        $.pjax.submit evt, @container.selector, timeout: false, push: false

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
