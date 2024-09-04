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

    // If 'Family' selected, or we just submitted a non-HoH member to an existing household,
    // show the option to add another member in the Success modal.
    if (window.isFamilyHoH || window.isFamilyMember) {
      $('#addAnotherHouseholdMemberButton').show();
    }
    $('#successModal').modal('show');
  }

  $('.reload-button').on('click', function () {
    window.location = window.location.pathname; // drop hh_id param
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
    var formData = {};
    $(form).serializeArray().forEach(function (item) {
      formData[item.name] = item.value;
    });

    if (window.householdId) {
      // If form collects household information, add householdId and relationshipToHoH to submission
      formData['Enrollment.householdId'] = window.householdId;
      if (!formData['Enrollment.relationshipToHoH']) {
        formData['Enrollment.relationshipToHoH'] = window.isFamilyMember ? 'DATA_NOT_COLLECTED' : 'SELF_HEAD_OF_HOUSEHOLD';
      }
    }

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

window.addHouseholdTypeListener = function (individualOrFamilySelector) {
  // Generates a "household id" that is unlikely to have collisions among form submissions,
  // without using external library (uuid) or modern browser features (crypto)
  var generateHouseholdId = function () {
    var current = Date.now().toString(); // OK? https://caniuse.com/mdn-javascript_builtins_date_now
    var rand = Math.random().toString(16).substring(2)
    return String('HH' + current + rand).toUpperCase();
  }

  var setWindowHouseholdId = function () {
    var params = new URL(document.location.toString()).searchParams;
    var hh_id = params.get("hh_id");

    // If valid hh_id param exists, then we are adding a client to the same household
    // as the previous submission
    if (hh_id && hh_id.length === 28 && hh_id.substring(0, 2) === 'HH') {
      window.householdId = hh_id;
      window.isFamilyMember = true;
      window.isFamilyHoH = false;
      // Show alert indicating that the user is adding a new member to an existing household
      $('#householdWarning').show();
    } else {
      // Generate a new new household for this submission
      window.householdId = generateHouseholdId();
      window.isFamilyHoH = false; // don't know yet if this will be a family or individual
      window.isFamilyMember = false;
    }
  }
  // Set initial householdId on the window
  setWindowHouseholdId();

  // Listener for household type (Individual or Family)
  //
  // Expected item attributes:
  //
  // { "link_id": "individual_or_family",
  //   "type": "CHOICE",
  //   "pick_list_options": [{"code": "Individual"}, {"code": "Family"}]
  // }
  var $hhTypeEl = $(individualOrFamilySelector); // Selector for "Individual or Family" radio buttons
  if (window.isFamilyMember) {
    // Form is for an existing household (hh_id present), so set to 'Family' and disable.
    $(individualOrFamilySelector + '[value="Family"]').prop('checked', true); // default to Family
    $hhTypeEl.prop('disabled', true);
  } else {
    // Store Household type on the window so we have it after successful submission, to
    // decide whether to show the "Add another HHM" button.
    $hhTypeEl.on('change', function (event) {
      window.isFamilyHoH = event.target.value === 'Family' && !!event.target.checked;
    });
  }
}



// conditions: [{input_name: 'name', input_value: 'value'}, ...]
// targetSelector: selector for the item that is conditionally shown
// enableBehavior: 'ANY' or 'ALL' conditions must be met to show the target selector
window.addDependentGroup = function (conditions, targetSelector, enableBehavior = 'ANY') {
  var target = $(targetSelector); // the item with enable_when on it

  // note: special methods instead of using show() and hide() because
  // the .fade-effect class uses visibility:hidden
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
