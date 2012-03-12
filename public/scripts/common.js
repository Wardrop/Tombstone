Ts = {};

/**** Common Page Behaviours ****/

$( function () {
  // Enable jQuery datepicker on all date and datetime fields.
  $('input[type=date]').livequery( function () {
    $(this).datepicker({ dateFormat: 'dd/mm/yy', showOn: 'button', changeYear: true, yearRange: "1900:" })
  })
  $('input[type=datetime]').livequery( function () {
    $(this).datetimepicker({ dateFormat: 'dd/mm/yy', showOn: 'button', changeYear: true, yearRange: "1900:", ampm: true, timeFormat: 'h:mmtt' })
  })
  
  // Control for adding an arbitary number of values for a field.
  $(document).on('blur keyup', '.multiinput_control input', function (e) {
    isLast = $(this).parents('.multiinput_control').find('input:last')[0] == this
    if (isLast) {
      if ((e.keyCode == 13 || e.keyCode == undefined) && !$(this).val().match(/^ *$/)) {
        clone = $(this).clone()
        clone.val('')
        $(this).parent().after($('<div />').append(clone))
        clone.focus()
      }
    } else {
      if ((e.keyCode == 13 || e.keyCode == undefined) && $(this).val().match(/^ *$/)) {
        try {
          $(this).parent().remove()
        } catch(e) {}
      }
    }
    if (e.type == "keyup") return false
  })
})

/**** Backbone helpers ****/

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


/**** jQuery helpers ****/

(function ($) {
  $.fn.parseJSON = function () {
    return $.parseJSON(this.html())
  }
  
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
	
	$.fn.scrollTo = function(duration, offset) {
		offset = offset || 0
		$('html, body').animate({
			scrollTop: (this.offset().top + offset)
		}, duration)
  };

})(jQuery)


/**** Prototype Extensions ****/

String.prototype.capitalize = function () {
  return this.charAt(0).toUpperCase() + this.slice(1);
};

/* 
 * To Title Case 2.0.1 – http://individed.com/code/to-title-case/
 * Copyright © 2008–2012 David Gouch. Licensed under the MIT License. 
 */
String.prototype.titleize = function () {
  var smallWords = /^(a|an|and|as|at|but|by|en|for|if|in|of|on|or|the|to|vs?\.?|via)$/i;

  return this.replace(/([^\W_]+[^\s-]*) */g, function (match, p1, index, title) {
    if (index > 0 && index + p1.length !== title.length &&
      p1.search(smallWords) > -1 && title.charAt(index - 2) !== ":" && 
      title.charAt(index - 1).search(/[^\s-]/) < 0) {
      return match.toLowerCase();
    }

    if (p1.substr(1).search(/[A-Z]|\../) > -1) {
      return match;
    }

    return match.charAt(0).toUpperCase() + match.substr(1);
  });
};

String.prototype.demodulize = function () {
  return this.replace(/_/g, ' ');
};

// Modify the built-in encodeURIComponent function to return an empty string for null and undefined values.
// It may be a little presumptive of me, but I figure there'd be few circumstances where a "null" or "undefined"
// string would be a desireable return value.
(function () {
	original = encodeURIComponent;
	window.encodeURIComponent = function (v) {
		return (v == null) ? '' : original(v);
	};
})()
