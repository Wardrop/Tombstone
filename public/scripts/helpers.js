Ts = {};

// Backbone helpers
_.extend(Backbone.Model.prototype, {
  recursiveToJSON: function () {
    var json = this.toJSON()
    _.each(json, function (value, key) {
      if(value) {
        if(_.isFunction(value.recursiveToJSON)) {
          json[key] = value.recursiveToJSON()
        }
      }
    })
    return json;
  }
});


// jQuery helpers
(function ($) {
  $.fn.serializeJSON = function() {
    var json = {};
    jQuery.map($(this).serializeArray(), function(n, i){
      json[n['name']] = n['value'];
    });
    return json;
  };
  
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
  };
  
  $.fn.serializeObject = function() {
    var o = {}
    var a = this.serializeArray()
    $.each(a, function() {
      if (o[this.name] !== undefined) {
        if (!o[this.name].push) {
            o[this.name] = [o[this.name]]
        }
        o[this.name].push(this.value || '')
      } else {
        o[this.name] = this.value || ''
      }
    })
    return o
  };
})(jQuery);

function capitalize(string)
{
    return string.charAt(0).toUpperCase() + string.slice(1);
}