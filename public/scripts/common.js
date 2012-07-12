
if (typeof console == 'undefined') {
  window.console = {log: function () {}}
}

Ts = function () {
  var date = $('<input type="date" />')[0]
  var datetime = $('<input type="datetime" />')[0]
  return {
    FormViews: {},
    supportsDateInput: date.type == 'date' && (date.value = 'invalid date') && !(date.value == 'invalid date'),
    supportsDateTimeInput: datetime.type == 'datetime' && (datetime.value = 'invalid datetime') && !(datetime.value == 'invalid datetime'),
    getParameterByName: function (name) {
      var match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search)
      return match && decodeURIComponent(match[1].replace(/\+/g, ' '))
    },
    elementInDocument: function(element) {
      if (element instanceof jQuery) element = element[0]
      while (element) {
        if (element == document) return true;
        element = element.parentNode;
      }
      return false;
    }
  }
}()

/**** Common Page Behaviours ****/

$( function () {
  $('[autofocus]').focus()
  
  // Enable jQuery datepicker on all date and datetime fields.
  if (!Ts.supportsDateInput) {
    $('input[type=date]').livequery( function () {
      $(this).datepicker({ dateFormat: 'dd/mm/yy', showOn: 'button', changeYear: true, yearRange: "1900:" })
    })
  }
  if (!Ts.supportsDateTimeInput) {
    $('input[type=datetime]').livequery( function () {
      $(this).datetimepicker({ dateFormat: 'dd/mm/yy', showOn: 'button', changeYear: true, yearRange: "1900:", ampm: true, timeFormat: 'h:mmtt' })
    })
  }
  
  $('input.tooltip').livequery( function () {
    var gravity = $(this).data('gravity')
    if(!gravity) gravity = 'w'
    $(this).tipsy({trigger: 'focus', opacity: 1, gravity: gravity});
  })
  $('input[placeholder]').livequery( function () {
    $(this).placeholder();
  })
  
  $(document).on('click', 'section > h2.underline', function () {
    $(this).next().slideToggle(150);
  }).on('mouseover', 'section > h2.underline', function () {
    $(this).css({cursor: 'pointer'}).attr('title', 'Click to show/hide')
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
});

/**** Backbone/Underscore helpers and overrides ****/

// _super taken from https://gist.github.com/1542120
(function(Backbone) {
  // The super method takes two parameters: a method name
  // and an array of arguments to pass to the overridden method.
  // This is to optimize for the common case of passing 'arguments'.
  function _super(methodName, args) {

    // Keep track of how far up the prototype chain we have traversed,
    // in order to handle nested calls to _super.
    this._superCallObjects || (this._superCallObjects = {});
    var currentObject = this._superCallObjects[methodName] || this,
        parentObject  = findSuper(methodName, currentObject);
    this._superCallObjects[methodName] = parentObject;

    var result = parentObject[methodName].apply(this, args || []);
    delete this._superCallObjects[methodName];
    return result;
  }

  // Find the next object up the prototype chain that has a
  // different implementation of the method.
  function findSuper(methodName, childObject) {
    var object = childObject;
    while (object[methodName] === childObject[methodName]) {
      object = object.constructor.__super__;
    }
    return object;
  }

  _.each(["Model", "Collection", "View", "Router"], function(klass) {
    Backbone[klass].prototype._super = _super;
  });

})(Backbone);

_.templateSettings.escape = /<\?-([\s\S]+?)\?>/g
_.templateSettings.evaluate = /<\?([\s\S]+?)\?>/g
_.templateSettings.interpolate = /<\?=([\s\S]+?)\?>/g

escape: /<%-([\s\S]+?)%>/g
evaluate: /<%([\s\S]+?)%>/g
interpolate: /<%=([\s\S]+?)%>/g

Backbone.Model.prototype.recursiveToJSON = function () {
  var json = this.toJSON()
  _.each(json, function (value, key) {
    if(value) {
      if(_.isFunction(value.recursiveToJSON)) {
        json[key] = value.recursiveToJSON()
      }
    }
  })
  return json;
};


/**** jQuery helpers ****/

(function ($) {
  $.fn.parseJSON = function () {
    return $.parseJSON(this.html())
  }
  
  $.fn.serializeJSON = function() {
    var json = {};
    jQuery.map($(this).serializeArray(), function(n, i){
      json[n.name] = n.value;
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
  
  $.fn.inDOM = function () {
    return Ts.elementInDocument.call(this, this)
  }

})(jQuery)


/**** Helpers and Prototype Extensions ****/

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
// string would be a desireable return value, especially in the context of converting javascript types to JSON.
(function () {
	original = encodeURIComponent;
	window.encodeURIComponent = function (v) {
		return (v == null) ? '' : original(v);
	};
})()

function resizeIframe(obj) {
 var height = obj.contentWindow.document.body.scrollHeight;
 if (height < 350) { height = 325; }
 obj.style.height = height + 'px';
 obj.style.width = obj.contentWindow.document.body.scrollWidth + 'px';
}
  
