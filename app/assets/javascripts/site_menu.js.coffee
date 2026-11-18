$ ->
  # Toggle menu (move on/off canvas) on small screens
  menuOpen = -> $('body').hasClass('menu-open')

  setMenuOpen = (open) ->
    if open
      headerBottom = $('.o-header--page')[0]?.getBoundingClientRect().bottom ? 0
      drawerTop = Math.max(0, headerBottom)
      $('.js-menu').each -> @style.setProperty('--o-menu-drawer-top', "#{drawerTop}px")
    $('body').toggleClass('menu-open', open)
    $('.js-menu').toggleClass('on-canvas', open).toggleClass('off-canvas', !open)
    $('.js-toggle-menu').attr('aria-expanded', open)

  $('.js-toggle-menu').on 'click', (event) ->
    event.preventDefault()
    setMenuOpen(!menuOpen())

  $(document).on 'keydown', (event) ->
    return unless event.key == 'Escape' && menuOpen()
    setMenuOpen(false)
    $('.js-toggle-menu').first().trigger('focus')

  $(document).on 'mousedown', (event) ->
    return unless menuOpen()
    return if $(event.target).closest('.js-menu, .js-toggle-menu').length
    setMenuOpen(false)

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
