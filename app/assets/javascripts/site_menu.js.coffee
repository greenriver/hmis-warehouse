$ ->
  # Toggle menu (move on/off canvas) on small screens
  $('.js-toggle-menu').on 'click', (event) ->
    event.preventDefault()
    $('body').toggleClass('menu-open')
    $('.js-menu').toggleClass('off-canvas on-canvas')

  $('.js-back-to-top').on 'click', (event) ->
    event.preventDefault()
    $('body,html').animate { scrollTop: 0 }, 500

  lastPoint = 0
  $(window).scroll ->
    action  = 'removeClass'
    scrollY = @scrollY
    if scrollY > (@innerHeight / 4) && lastPoint > scrollY
      action  = 'addClass'

    $('.js-back-to-top')[action]('active')
    lastPoint = scrollY
