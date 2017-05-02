window.GRB  ?= {}
GRB.scratch ?= {}  # scratch is a safe namespace to stow variables
window.GRB.headerNavCb = $.Callbacks()

# horizontalBehavior = ->
#   $document = $(document)
#   $content = $('#jNavDropdownContent')

#   closeOnClickOff = (event) ->
#     $e = $(event.target)
#     if $e.closest('.jNavDropdown, #jNavDropdownContent').length > 0
#       return
#     else
#       closeNav()

#   closeNav = ->
#     $('.gresb-navbar-nav-item').removeClass('active')
#     $document.off('click', closeOnClickOff)
#     $content.removeClass('open')

#   window.GRB.headerNavCb.add(closeNav)

#   openNav = (data) ->
#     $document.on('click', closeOnClickOff)
#     $content.find('.inner-content').html(data)
#     $content.addClass('open')

#   bsClassReplacements = [
#     ['row-fluid', 'row']
#     ['span4', 'col-sm-4']
#     ['span3', 'col-sm-3']
#   ]
#   isBootstrap2 = $content.is('.bs2')
#   $('.jNavDropdown').click (e) ->
#     e.preventDefault()
#     $el = $(this)
#     $li = $el.parents('.gresb-navbar-nav-item')
#     if $li.is('.active')
#       $li.removeClass('active')
#       closeNav()
#     else
#       closeNav()
#       $li.addClass('active')
#       data = $el.data('drop-down-content')
#       $node = $(JSON.parse(data))
#       if isBootstrap2
#         for [bs2, bs3] in bsClassReplacements
#           $node.find('.' + bs3).removeClass(bs3).addClass(bs2)
#       else
#         for [bs2, bs3] in bsClassReplacements
#           $node.find('.' + bs2).removeClass(bs2).addClass(bs3)
#       openNav($node)

verticalBehavior = ->

  $vsmContainer = $('#vsm-container')
  $toggle = $('.jToggleVsm')
  $document = $(document)
  $viewport = $(window)

  inboardBarWidth = 60
  maxBarWidth = 185
  shortPageHeight = 550
  maxContentWidth = 1200

  closeOnClickOff = (event) ->
    $e = $(event.target)
    if $e.closest('#vsm-container').length > 0
      return
    else
      closeNav()

  openNav = ->
    return if $vsmContainer.is('.open, .pinned')
    $vsmContainer.removeClass('closed')
    $vsmContainer.addClass('open')
    $document.on('click', closeOnClickOff)

  closeNav = ->
    $vsmContainer.addClass('closed')
    return if !$vsmContainer.is('.open')
    return if $vsmContainer.is('.pinned')
    $vsmContainer.removeClass('open')
    $document.off('click', closeOnClickOff)

  $toggle.click ->
    if $vsmContainer.is('.open')
      closeNav()
    else
      openNav()

  $headerNavHack = $('#cas-action-button-header-container')
  
  debounce = (func, threshold, execAsap) ->
    timeout = null
    (args...) ->
      obj = this
      delayed = ->
        func.apply(obj, args) unless execAsap
        timeout = null
      if timeout
        clearTimeout(timeout)
      else if (execAsap)
        func.apply(obj, args)
      timeout = setTimeout delayed, threshold || 100
  
  updateNav = ->
    $vsmContainer.removeClass('transitions')
    closeNav()

    pageWidth = $viewport.innerWidth()
    pageHeight = $viewport.innerHeight()
    doubleMaxBarWidth = 2*maxBarWidth
    $vsmContainer.toggleClass('short', pageHeight < shortPageHeight)

    if pageWidth >= (maxContentWidth + (2*inboardBarWidth))
      $vsmContainer.addClass('outboard')
      $vsmContainer.removeClass('inboard')
      $headerNavHack.css(right: 0)
      if pageWidth >= (maxContentWidth + (2*maxBarWidth))
        $vsmContainer.addClass('pinned')
      else
        $vsmContainer.removeClass('pinned')
    else
      $vsmContainer.removeClass('outboard')
      $vsmContainer.addClass('inboard')
      $vsmContainer.removeClass('pinned')
      $headerNavHack.css(right: inboardBarWidth)

    $vsmContainer.addClass('transitions')

  updateNav()
  $vsmContainer.show()
  $(window).resize(debounce(updateNav, 50))

$ ->
  # horizontalBehavior()
  verticalBehavior()
