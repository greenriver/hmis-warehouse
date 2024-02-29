// es5 compatible JS for public-facing static pages

$(function () {
  var captchaKey = appConfig.captchaKey;
  var formId = appConfig.formId;
  var presignedUrl = appConfig.presignedUrl

  if (!appConfig.presignedUrl) {
    return
  }

  var form = document.getElementById(formId);
  if (!form || !captchaKey) return;

  var submitWithPresign = function (event) {
    event.preventDefault(); // Prevent the default form submission

    var formData = {};
    $(event.target).serializeArray().forEach(function (item) {
      formData[item.name] = item.value;
    });

    var jsonData = JSON.stringify(formData);
    // Request a presigned URL
    $.ajax({
      url: presignedUrl,
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
            console.log('Submission successful');
          },
          error: function () {
            console.error('Submission failed');
          }
        });
      },
      error: function () {
        console.error('Error requesting presigned URL');
      }
    });
  }

  form.addEventListener('submit', function (event) {
    event.preventDefault(); // Prevent the default form submission
    grecaptcha.ready(function () {
      grecaptcha.execute(captchaKey, { action: 'submit' }).then(function (token) {
        // Append the token to the form
        var recaptchaResponse = document.createElement('input');
        recaptchaResponse.type = 'hidden';
        recaptchaResponse.name = 'recaptcha_response';
        recaptchaResponse.value = token;
        form.appendChild(recaptchaResponse);

        // resubmit
        submitWithPresign(event);
      });
    });
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
