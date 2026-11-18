$ ->
  # Toggle menu (move on/off canvas) on small screens
  $('.js-toggle-menu').on 'click', (event) ->
    event.preventDefault()
    $('body').toggleClass('menu-open')
    if $('body').hasClass('menu-open')
      headerBottom = $('.o-header--page')[0]?.getBoundingClientRect().bottom ? 0
      drawerTop = Math.max(0, headerBottom)
      $('.js-menu').each -> @style.setProperty('--o-menu-drawer-top', "#{drawerTop}px")
    $('.js-menu').toggleClass('off-canvas on-canvas')
    $('.js-toggle-menu').attr('aria-expanded', $('body').hasClass('menu-open'))

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
