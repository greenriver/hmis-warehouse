App.ViewableEntities = class {
  constructor() {
    this.registerEvents()
    this.initSelect2()
  }

  registerEvents() {
    const showHideEl = (event, relatedElement) => {
      event.preventDefault()
      const $container = $(event.currentTarget).closest('.j-column')
      const $element = $container.find('.j-column-actions-' + relatedElement)
      const $content = $container.find('.j-column-content')
      $element.siblings().addClass('hide')
      $element.toggleClass('hide')
      $content.toggleClass('active')
      let select2Action = 'open'
      let contentAction = 'addClass'
      if ($element.hasClass('hide')) {
        select2Action = 'close'
        contentAction = 'removeClass'
      }
      $content[contentAction]('inactive')
      $element.find('.jUserViewable').select2(select2Action)
    }

    $('.j-add').on('click', (event) => {
      const elements = showHideEl(event, 'add')
    })
    $('.j-remove-all').on('click', (event) => {
      const elements = showHideEl(event, 'remove')
    })
  }


  initSelect2() {
    $('.jClearSelect').on('click', function(event) {
      event.preventDefault()
      var select_class = $(event.currentTarget).data('input-class');
      $("select." + select_class).find('option:selected').prop("selected", false);
      return $("select." + select_class).trigger('change');
    })

    $('.jUserViewable').each(function() {
      var $t, i, values
      $t = $(this)
      values = function() {
        var j, len, ref, results
        ref = $t.find('option[selected]');
        results = [];
        for (j = 0, len = ref.length; j < len; j++) {
          i = ref[j];
          results.push($(i).val());
        }
        return results
      }

      return $(function() {
        $t.select2({
          minimumResultsForSearch: 10,
          placeholder: $t.attr('placeholder'),
          tags: true,
          multiple: true
        })
        return $t.val(values).trigger('change');
      })
    })
  }
}
