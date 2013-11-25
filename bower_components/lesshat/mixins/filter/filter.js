/**
 * Filter mixin
 */

var filter = function filter(value) {
  value = value || 'none';

  if (/^[-a-zA-Z0-9().\/]*,/.test(value)) {
    value = value.replace(/(?:,)(?![^(]*\))/g, '');
  }

  return value;
};

/**
 * For which browsers is this mixin specified
 */

filter.vendors = ['webkit', 'moz', 'ms'];


/**
 * Export mixin
 */

module.exports = filter;
