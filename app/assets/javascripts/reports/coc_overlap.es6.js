//= require ./namespace

App.Reports.cocOverlap = ({ resultsSelector, mapProps, formSelector }) => {
  const map = new App.Maps.MapWithShapes(mapProps, (value) => {
    console.info(value);
  });
  const $form = $(formSelector);
  const $submitButton = $('.j-submit-button');
  const $prompt = $('.j-submit-button-prompt');

  //const displayPrompt = () => {
  //  $('.j-submit-button-prompt').toggleClass('d-none', !!value);
  //  const { value } = evt.currentTarget;
  //  $submitButton.prop('disabled', !value);
  //  $('.j-submit-button-prompt').toggleClass('d-none', !!value);
  //}

  $('#compare_coc1').on('select2:select', (evt) => {
    const { value } = evt.currentTarget;
    $submitButton.prop('disabled', !value);
    $('.j-submit-button-prompt').toggleClass('d-none', !!value);
  });

  const indicateLoading = (loading) => {
    let opacity = 1;
    let pointerEvents = 'all';
    if (loading) {
      opacity = 0.4;
      pointerEvents = 'none';
    }
    const loaderClass = 'j-loading-indicator';
    const $container = $(resultsSelector).css({ opacity, pointerEvents });
    if (loading) {
      $container.prepend(
        `<div class="${loaderClass} c-spinner c-spinner--lg c-spinner--center"></div>`,
      );
    } else {
      $container.find(`.${loaderClass}`).remove();
    }
    $submitButton.prop('disabled', loading);
  };

  const displayResults = (data) => {
    $('.coc1-name').html(data.coc1);
    $('.coc2-name').html(data.coc2);
    $('.j-title').html(data.title);
    $('.j-subtitle').html(data.subtitle);
    $(resultsSelector).html(data.html);
    map.updateData(data.map, []);
    const chosenPrimary = $('#compare_coc1').val();
    if (chosenPrimary) {
    }
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
        indicateLoading(false);
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
