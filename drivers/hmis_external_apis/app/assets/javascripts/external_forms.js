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

    // If HH Size > 1, or we just submitted a non-HoH member, show the option to add another member in the Success modal
    if (window.householdSize > 1 || window.existingHousehold) {
      $('#addAnotherHouseholdMemberButton').show();
    }
    $('#successModal').modal('show');
  }

  // MAYBE TODO: move all this JS to addHouseholdSizeListener or another function so it's only conditionally
  // loaded if this form deals with household submissions. (Again, inferred from household_size presence, or Enrollment mappings?👀)

  // Generates a "household id" that is unlikely to have collisions among form submissions,
  // without using external library (uuid) or modern browser features (crypto)
  var generateHouseholdId = function () {
    var current = Date.now().toString(); // OK? https://caniuse.com/mdn-javascript_builtins_date_now
    var rand = Math.random().toString(16).substring(2)
    return String('HH' + current + rand).toUpperCase();
  }

  var isValidHouseholdId = function (id) {
    // safe? will it ever be a different length due to browser differences?
    return id.length === 28 && id.substring(0, 2) === 'HH';
  }

  var setHouseholdId = function () {
    var params = new URL(document.location.toString()).searchParams;
    var householdIdParam = params.get("hh_id");

    if (householdIdParam && isValidHouseholdId(householdIdParam)) {
      // Form will add a client to the same household as the previous submission (hh_id)
      window.householdId = householdIdParam;
      window.existingHousehold = true;
      console.log('Using Household ID param:', window.householdId);
      $('#household_warning').show();
    } else {
      // Form will create a new household for this submission
      window.householdId = generateHouseholdId();
      window.existingHousehold = false;
      console.log('Created new Household ID:', window.householdId);
    }
  }
  
  setHouseholdId();

  $('.reload-button').on('click', function () {
    // drop hh_id param
    window.location = window.location.pathname;
  });

  $('#addAnotherHouseholdMemberButton').on('click', function () {
    window.location = window.location.pathname + '?hh_id=' + window.householdId;
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
    var formData = { householdId: window.householdId };
    $(form).serializeArray().forEach(function (item) {
      formData[item.name] = item.value;
    });
    console.log("submitting", formData);
    return handleSuccess(); // just for testing

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
    return submitWithPresign(null); // just for testing
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

window.addHouseholdSizeListener = function (targetSelector) {
  var $hhSizeEl = $(targetSelector);
  if (window.existingHousehold) {
    // Form is for an existing household, so hide the household size question
    $hhSizeEl.removeClass('visible');
    $hhSizeEl.attr('aria-hidden', "true");
    $hhSizeEl.find('input, select, textarea').prop('disabled', true);
  } else {
    // Store Household Size on the window so we have it after successful submission, to
    // decide whether to show the "Add another HHM" button.
    $hhSizeEl.on('change', function () {
      //TODO: do something better/safer than parseInt. also trim. should this field be required?
      var hhSize = parseInt($(this).val());
      console.log("hh size", hhSize);
      window.householdSize = hhSize || 0;
    });
  }
}

// conditions: [{input_name: 'name', input_value: 'value'}, ...]
// targetSelector: selector for the item that is conditionally shown
// enableBehavior: 'ANY' or 'ALL' conditions must be met to show the target selector
window.addDependentGroup = function (conditions, targetSelector, enableBehavior = 'ANY') {
  var target = $(targetSelector); // the item with enable_when on it
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

  // When *any* dependent item changes, this function will check all the conditions, and show/hide the target item accordingly.
  var onDependentItemChanged = function() {
    var evaluations = conditions.map(function (condition) {
      var $el = $('[name="' + condition.input_name + '"]')

      // If the dependent item is a radio button item, we need to look at all the radio buttons with the same name, and find the one that is checked.
      if ($el.is(':radio')) {
        return $('[name="' + condition.input_name + '"]:checked').val() === condition.input_value;
      }
      if ($el.is(':checkbox')) {
        return $el.is(':checked') && $el.val() === condition.input_value;
      }
      return $el.val() === condition.input_value;
    });

    var meetsCondition = enableBehavior === 'ALL' ? evaluations.every(Boolean) : evaluations.some(Boolean)
    meetsCondition ? show() : hide();
  }

  // add change listener to all dependent fields
  conditions.forEach(function (condition) {
    $('[name="' + condition.input_name+ '"]').on('change', onDependentItemChanged);
  });

  // hide conditional item initially
  hide();
}
