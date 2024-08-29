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
window.addMultiDependentGroup = function (conditions, targetSelector, enableBehavior = 'ANY') {
  console.log("conditions", conditions)
  var target = $(targetSelector); // item with enable_when on it. assumes "ANY"
  var show = function () {
    target.addClass('visible');
    target.attr('aria-hidden', "false");
    target.find('input, select, textarea').prop('disabled', false);
  }
  var hide = function () {
    target.removeClass('visible');
    target.attr('aria-hidden', "true");
    target.find('input, select, textarea').prop('disabled', true);
  }

  var watcher = function(event) {
    var evaluations = conditions.map(function ({ input_name, input_value }) {
      var el = $('[name="' + input_name + '"]')
      var input_type = el.prop('type');

      // If the dependent item is a radio button item, we need to look at ALL the radio buttons with the same name, and find the one that is checked.
      if (input_type === 'radio') {
        var checked_val = $('[name="' + input_name + '"]:checked').val()
        return checked_val === input_value;
      }

      var value = el.val()
      if (input_type === 'checkbox') {
        if (value === input_value) {
          return el.is(':checked')
        }
      } else {
        return value === input_value
      }
      return false
    });

    var meetsCondition = enableBehavior === 'ALL' ? evaluations.every(Boolean) : evaluations.some(Boolean)
    if (meetsCondition) {
      show();
    } else {
      hide();
    }
  }

  var fieldNames = conditions.map(c => `[name="${c.input_name}"]`);
  fieldNames.forEach(function (name) {
    $(name).on('change', watcher);
  });
  // console.log("fieldNames", fieldNames)
  // $("form").on('change', fieldNames, watcher);

  hide();
}

// window.addDependentGroup = function (inputName, condValue, targetSelector) {
//   var target = $(targetSelector);
//   var show = function () {
//     target.addClass('visible');
//     target.attr('aria-hidden', "false");
//     target.find('input, select, textarea').prop('disabled', false);
//   }
//   var hide = function () {
//     target.removeClass('visible');
//     target.attr('aria-hidden', "true");
//     target.find('input, select, textarea').prop('disabled', true);
//   }

//   $('[name="' + inputName + '"]').on('change', function () {
//     var el = $(this)
//     var value = el.val();
//     if (el.prop('type') === 'checkbox') {
//       if (value === condValue) {
//         el.is(':checked') ? show() : hide();
//       }
//     } else {
//       value === condValue ? show() : hide();
//     }
//   });
//   hide();
// }
