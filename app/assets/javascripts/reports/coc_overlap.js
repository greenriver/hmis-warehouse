//= require ./namespace

App.Reports.cocOverlap = ({ resultsSelector, mapProps, formSelector }) => {
  const map = new App.Maps.MapWithShapes(mapProps);
  const $form = $(formSelector);
  const $submitButton = $('.j-submit-button');
  const $prompt = $('.j-submit-button-prompt');
  const $loading = $('.j-submit-button-loading');
  const $errorContainer = $('.j-submit-button-error');

  $('#compare_coc1').on('select2:select', (evt) => {
    const { value } = evt.currentTarget;
    $submitButton.prop('disabled', !value);
    $prompt.toggleClass('d-none', !!value);
  });

  const indicateLoading = (loading, error=null) => {
    let opacity = 1;
    let pointerEvents = 'all';
    if (loading) {
      opacity = 0.4;
      pointerEvents = 'none';
    }
    $loading.toggleClass('d-none', !loading);
    const loaderClass = 'j-loading-indicator';
    const $container = $(resultsSelector).css({ opacity, pointerEvents });
    $errorContainer.text('').addClass('hide');
    if (loading) {
      $container.prepend(
        `<div class="${loaderClass} c-spinner c-spinner--lg c-spinner--center"></div>`,
      );
    } else {
      $container.find(`.${loaderClass}`).remove();
      if (error) {
        $errorContainer.text(error).removeClass('hide');
      }
    }
    $submitButton.prop('disabled', loading);
  };

  const displayResults = (data) => {
    $('.coc1-name').html(data.coc1 || `<span class="text-muted">Primary CoC not selected</span>`);
    $('.coc2-name').html(data.coc2 || `<span class="text-muted">Secondary CoC not selected</span>`);
    if (data.title) {
      $('.j-title')
        .html(data.title)
        .removeClass('d-none')
    }
    $('.j-subtitle').html(data.subtitle);
    $(resultsSelector).html(data.html);
    map.updateShapes({ shapes: data.map, primaryId: data.coc1_id, secondaryId: data.coc2_id });
  };

  const postForm = (evt) => {
    if (evt) {
      evt.preventDefault();
    }
    if (!$form.get(0).checkValidity()) {
      return;
    }
    const formData = $form.serialize();
    const newUrl = `${window.location.href.split('?')[0]}?${formData}`;
    window.history.pushState({}, 'FormSubmit', newUrl);
    indicateLoading(true);
    $.ajax({
      type: 'GET',
      url: $form.attr('action'),
      data: formData,
    })
      .done((data) => {
        indicateLoading(false, data.error);
        displayResults(data);
      })
      .fail((xhr) => {
        indicateLoading(false);
        alert('An error occured while processing your request');
      });
  };
  $form.on('submit', postForm);
  $submitButton.on('click', () => $form.submit());
  postForm();
};
