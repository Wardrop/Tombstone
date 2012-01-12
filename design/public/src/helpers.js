// jQuery helpers

(function($) {
  $.fn.serializeJSON = function() {
    var json = {};
    jQuery.map($(this).serializeArray(), function(n, i){
      json[n['name']] = n['value'];
    });
    return json;
  }
  
  $.fn.fieldValue = function (value) {
    if (this.is('[type=radio], [type=checkbox]')) {
      this.each( function (index, element) {
        if($(element).is('[value='+value+']')) {
          $(element).prop('checked', true)
        } else {
          $(element).prop('checked', false)
        }
      })
    } else {
      this.val(value)
    }
  }
})(jQuery);

