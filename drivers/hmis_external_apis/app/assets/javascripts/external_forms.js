// es5 compatible JS for public-facing static pages

$(function () {
  var form = document.querySelector('form');
  var handleError = function () {
    $('#spinnerModal').modal('hide');
    $('#errorModal').modal('show');
  }
  var handleSuccess = function () {
    $('#spinnerModal').modal('hide');
    form.reset();
    document.querySelector('main').remove();
    $('#successModal').modal('show');
  }

  $('.reload-button').on('click', function () {
    window.location.reload();
  });

  var captchaKey = appConfig.recaptchaKey;
  var presignUrl = appConfig.presignUrl;

  if (!appConfig.presignUrl) {
    throw new Error('missing configuration')
  }

  var toJsonFile= function (formData) {
    const content = JSON.stringify(formData);
    // fixme - should support ie11
    return new Blob([content], { type: 'application/json' });
  }

  var submitWithPresign = function (captchaToken) {
    var formData = {};
    $(form).serializeArray().forEach(function (item) {
      formData[item.name] = item.value;
    });

    // Request a presigned URL
    $.ajax({
      url: presignUrl,
      type: 'GET',
      contentType: 'application/json',
      data: { captchaToken: captchaToken },
      dataType: 'json', // needed because the server responds with content-type text/plain instead of json
      success: function (data) {
        // Submit the JSON data to the presigned URL
        $.ajax({
          url: data.presignedUrl,
          type: 'PUT',
          headers: {
            'Content-Type': 'application/json',
          },
          processData: false,
          contentType: false,
          data: toJsonFile(Object.assign(formData, {captcha_score: data.captchaScore})),
          success: function () {
            handleSuccess();
          },
          error: function () {
            handleError();
          }
        });
      },
      error: function () {
        handleError();
      }
    });
  }

  var submitWithCaptcha = function () {
    $('#spinnerModal').modal('show');
    grecaptcha.ready(function () {
      try {
        grecaptcha.execute(captchaKey, { action: 'submit' }).then(function (token) {
          // resubmit
          submitWithPresign(token);
        });
      } catch (error){
        if (console && console.error) console.error(error)
        // recaptcha failure
        submitWithPresign(null);
      }
    });
  };

  $('#confirmSubmitModalButton').on('click', submitWithCaptcha);

  form.addEventListener('submit', function (event) {
    event.preventDefault(); // Prevent the default form submission
    event.stopPropagation();

    $('.needs-validation').find('input,select,textarea').each(function () {
      $(this).removeClass('is-valid is-invalid').addClass(this.checkValidity() ? 'is-valid' : 'is-invalid');
    });

    var invalid = $('.is-invalid');
    if (invalid.length) {
      // maybe we should show an alert here "please provide missing required values"
      // IE compat scroll
      const y = invalid.get(0).getBoundingClientRect().top + window.scrollY;
      window.scrollTo(0, y - 120);
    } else {
      $('#confirmSubmitModal').modal('show');
    }
  });

  $('.needs-validation').find('input,select,textarea').on('focusout', function () {
    // check element validity and change class
    $(this).removeClass('is-valid is-invalid').addClass(this.checkValidity() ? 'is-valid' : 'is-invalid');
  });
});

// conditions: [{input_name: 'name', input_value: 'value'}, ...]
// targetSelector: selector for the item that is conditionally shown
// enableBehavior: 'ANY' or 'ALL' conditions must be met to show the target selector
window.addDependentGroup = function (conditions, targetSelector, enableBehavior = 'ANY') {
  const target = $(targetSelector); // the item with enable_when on it
  const show = function () {
    target.addClass('visible');
    target.attr('aria-hidden', "false");
    target.find('input, select, textarea').prop('disabled', false);
  }
  const hide = function () {
    target.removeClass('visible');
    target.attr('aria-hidden', "true");
    target.find('input, select, textarea').prop('disabled', true);
  }

  // When *any* dependent item changes, this function will check all the conditions, and show/hide the target item accordingly.
  const onDependentItemChanged = function() {
    const evaluations = conditions.map(function ({ input_name, input_value }) {
      const el = $('[name="' + input_name + '"]')
      const input_type = el.prop('type');

      // If the dependent item is a radio button item, we need to look at all the radio buttons with the same name, and find the one that is checked.
      if (input_type === 'radio') {
        const checked_val = $('[name="' + input_name + '"]:checked').val()
        return checked_val === input_value;
      }

      const value = el.val()
      if (input_type === 'checkbox') {
        if (value === input_value) {
          return el.is(':checked')
        }
      } else {
        return value === input_value
      }
      return false
    });

    const meetsCondition = enableBehavior === 'ALL' ? evaluations.every(Boolean) : evaluations.some(Boolean)
    if (meetsCondition) {
      show();
    } else {
      hide();
    }
  }

  // add change listener to all dependent fields
  const dependentItemSelectors = conditions.map(c => `[name="${c.input_name}"]`)
  dependentItemSelectors.forEach(function (name) {
    $(name).on('change', onDependentItemChanged);
  });

  // hide conditional item initially
  hide();
}
