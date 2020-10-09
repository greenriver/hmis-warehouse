#############
# Ajax modals
#############
class window.AjaxModal
  constructor: ->
    @modal = $(".modal[data-ajax-modal]")
    @linkTriggersSelector = '[data-loads-in-ajax-modal], [data-loads-in-pjax-modal]'
    @formTriggersSelector = '[data-submits-to-ajax-modal], [data-submits-to-pjax-modal]'
    @closeSelector = '[data-ajax-modal-close], [data-pjax-modal-close], [pjax-modal-close]'
    @initialPath = window.location.pathname
    @loading = @modal.find("[data-ajax-modal-loading]")
    @title = @modal.find("[data-ajax-modal-title]")
    @content = @modal.find("[data-ajax-modal-content]")
    @footer = @modal.find("[data-ajax-modal-footer]")

    @listen()

  listen: ->
    @_registerLinks()
    @_registerForms()
    @_registerClose()

  _registerLinks: ->
    $('body').on 'click', @linkTriggersSelector, (e) =>
      e.preventDefault()
      @reset()
      @open()
      history.pushState({}, 'Modal', $(e.target).attr("href"))
      $.ajax
        url: e.currentTarget.getAttribute("href"),
        dataType: 'html',
        headers: {
          'X-AJAX-MODAL': true
        },
        complete: (xhr, status) =>
          @loading.hide()
          @content.html xhr.responseText
          @open

  _registerForms: ->
    # scope.find(@formTriggersSelector).attr('data-remote', true)
    $('body').on 'submit', @formTriggersSelector, (event) =>
      form = event.currentTarget
      event.preventDefault()
      @open()
      $.ajax
        url: form.getAttribute('action')
        type: form.getAttribute('method')
        dataType: 'html',
        data: $(form).serialize(),
        headers: {
          'X-AJAX-MODAL': true
        },
        complete: (xhr, status) =>
          @loading.hide()
          @content.html xhr.responseText
          @open
      return false

      
  # maybe don't need this for bootstrap
  _registerClose: ->
    @modal.on 'click', @closeSelector, =>
      history.pushState({}, 'Modal', @initialPath);
      @closeModal()

  open: ->
    @modal.modal 'show'

  closeModal: ->
    @modal.modal('hide')
    @reset()

  reset: ->
    @title.html("")
    @content.html("")
    @footer.html("")
    @loading.show()