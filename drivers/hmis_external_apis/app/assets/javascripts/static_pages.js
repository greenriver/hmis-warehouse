// es5 compatible JS for public-facing static pages

$(function () {
  var form = document.querySelector('form');
  var handleError = function() {
    $('#spinnerModal').modal('hide');
    $('#errorModal').modal('show');
  }
  var handleSuccess = function() {
    $('#spinnerModal').modal('hide');
    form.reset();
    document.querySelector('main').remove();
    $('#successModal').modal('show');
  }

  $('.reload-button').on('click', function() {
    window.location.reload();
  });

  var captchaKey = appConfig.recaptchaKey;
  var presignUrl = appConfig.presignUrl

  if (!appConfig.presignUrl) {
    throw new Error('missing configuration')
  }

  var submitWithPresign = function () {
    var formData = {};
    $(form).serializeArray().forEach(function (item) {
      formData[item.name] = item.value;
    });

    var jsonData = JSON.stringify(formData);
    // Request a presigned URL
    $.ajax({
      url: presignUrl,
      type: 'POST',
      contentType: 'application/json',
      data: JSON.stringify({
        fileName: 'formData.json',
        fileType: 'application/json'
      }),
      success: function (data) {
        // Submit the JSON data to the presigned URL
        $.ajax({
          url: data.url,
          type: 'PUT',
          contentType: 'application/json',
          data: jsonData,
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

  var submitWithCaptcha = function() {
    $('#spinnerModal').modal('show');
    grecaptcha.ready(function () {
      grecaptcha.execute(captchaKey, { action: 'submit' }).then(function (token) {
        // Append the token to the form
        var recaptchaResponse = document.createElement('input');
        recaptchaResponse.type = 'hidden';
        recaptchaResponse.name = 'recaptcha_response';
        recaptchaResponse.value = token;
        form.appendChild(recaptchaResponse);

        // resubmit
        submitWithPresign();
      });
    });
  };

  $('#confirmSubmitModalButton').on('click', submitWithCaptcha);

  form.addEventListener('submit', function (event) {
    event.preventDefault(); // Prevent the default form submission
    $('#confirmSubmitModal').modal('show');
  });
});

window.addDependentGroup = function (inputName, condValue, targetSelector) {
  var target = $(targetSelector);
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

  $('[name="' + inputName + '"]').change(function () {
    var el = $(this)
    var value = el.val();
    console.info('hi', inputName, value, condValue, el.attr('type'), el.is(':checked'))
    if (el.prop('type') === 'checkbox') {
      if (value === condValue) {
        el.is(':checked') ? show() : hide();
      }
    } else {
      value === condValue ? show() : hide();
    }
  });
  hide();
}
