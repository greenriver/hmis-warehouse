#############
# Ajax modals
#############
class window.AjaxModal
  constructor: ->
    @modal = $(".modal[data-ajax-modal]")
    @linkTriggersSelector = '[data-loads-in-ajax-modal], [data-loads-in-pjax-modal]'
    @formTriggersSelector = '[data-submits-to-ajax-modal], [data-submits-to-pjax-modal]'
    @closeSelector = '[data-ajax-modal-close], [data-pjax-modal-close], [pjax-modal-close]'
    @initialPath = window.location.toString()
    @loading = @modal.find("[data-ajax-modal-loading]")
    @title = @modal.find("[data-ajax-modal-title]")
    @content = @modal.find("[data-ajax-modal-content]")
    @footer = @modal.find("[data-ajax-modal-footer]")

    @listen()

  listen: ->
    @_registerLinks()
    @_registerForms()
    @_registerClose()
    @_registerOnHide()

  _registerLinks: ->
    $('body').on 'click', @linkTriggersSelector, (e) =>
      e.preventDefault()
      @open()
      history.replaceState({}, 'Modal', $(e.target).attr("href"))
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
      @closeModal()

  _registerOnHide: ->
    @modal.on "hidden.bs.modal", =>
      @reset()
      history.replaceState({}, 'Modal', @initialPath);

  open: ->
    @modal.modal 'show'

  close: ->
    @reset()
    @modal.modal('hide')

  closeModal: ->
    @close()

  reset: ->
    $("[data-ajax-modal-title]").html("Loading")
    $("[data-ajax-modal-body]").html("")
    $("[data-ajax-modal-footer]").html("")
    $("[data-ajax-modal-loading]").show()

  closeAndReload: ->
    @close
    if @initialPath
      history.pushState({}, 'Modal', @initialPath);
    window.location.reload()
