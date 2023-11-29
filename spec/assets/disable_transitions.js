
// http://joshfrankel.me/blog/lessons-learned-from-using-capybara-for-feature-testing/

var disableAnimationStyles = '-webkit-transition: none !important;' +
                             '-moz-transition: none !important;' +
                             '-ms-transition: none !important;' +
                             '-o-transition: none !important;' +
                             'transition: none !important;' +
                             '-webkit-animation: none !important;' +
                             '-moz-animation: none !important;' +
                             '-ms-animation: none !important;' +
                             '-o-animation: none !important;' +
                             'animation: none !important;'

window.disableAnimations = function() {
  var animationStyles = document.createElement('style');
  animationStyles.setAttribute('id', 'j-test-transitions-disabled')
  animationStyles.type = 'text/css';
  animationStyles.innerHTML = '* {' + disableAnimationStyles + '}';
  document.head.appendChild(animationStyles);
}

window.enableAnimations = function() {
  document.querySelector('#j-test-transitions-disabled').remove();
}

window.onload = function() {
  window.disableAnimations()
};
