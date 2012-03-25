/*
Mixins for Backbone Views
*/

$(function () {
  Ts.withAjax = function () {
    this.indicator = $(this.indicator)

    this.get = function (url, action, opts) {
      opts = opts || {}
      this.request(url, action, _.extend({type: 'GET'}, opts))
    }
    
    this.post = function (url, action, opts) {
      opts = opts || {}
      this.request(url, action, _.extend({type: 'POST'}, opts))
    }
    
    this.request = function (url, action, opts) {
      opts = opts || {}
      action = action || new Function
      this.indicator.css({display: ''}).addClass('loading')
      if (opts.data && opts.data instanceof Backbone.Model) {
        opts.data = opts.data.recursiveToJSON()
      }
      $.ajax(url, _.extend({
  			type: 'GET',
  			dataType: 'json',
  			context: this,
        success: function (data, textStatus, jqXHR) {
          action.call(this, data, textStatus, jqXHR)
        },
        error: function (jqXHR, textStatus, errorThrown) {
					switch(textStatus) {
						case 'error':
							try {
							  parsed = $.parseJSON(jqXHR.responseText)
							  if (parsed.exception) {
							    this.showErrors(parsed.exception.capitalize())
							  } else {
							    this.showErrors("Server error encountered: "+errorThrown)
						    }
							} catch (err) {
								this.showErrors("Server error encountered: "+errorThrown+"\n "+jqXHR.responseText)
							}
							break;
						default:
							this.showErrors("Client error encountered: "+errorThrown)
					}
				},
        complete: function () {
          if (this.indicator.hasClass('loading')) {
            this.indicator.css({display: 'none'})
          }
        }
      }, opts))
    }
    
    this.showErrors = function (errors) {
      console.log(errors)
      if (this.errorBlock instanceof jQuery && this.errorBlock.length > 0) { 
        this.showErrorBlock(errors)
		  } else {
		    var errorStr = (!errors || errors.constructor == String)
		      ? errors : 'The submitted data failed validation'
		    alert(errorStr)
		  }
    }
    
    this.showErrorBlock = function (errors) {
      errors = (errors instanceof String) ? [errors] : errors
      var iterateErrors = function (prefix, errors) {
        var array = []
				_.each(errors, function (error, field) {
					if (error.constructor == Array) {
						_.each(error, function (message) {
							errorObj = {}
              errorObj[field] = message
							array = array.concat( iterateErrors(prefix, errorObj) )
						})
					} else if (error.constructor == Object) {
						array = array.concat(iterateErrors((prefix && prefix + " -> ") + field.split('_').join(' ').titleize(), error))
					} else {
            field = (field) ? field.split('_').join(' ').titleize() : ''
            array.push((prefix && prefix + " -> ") + field.split('_').join(' ').titleize() + " " + error)
					}
				})
				return array
			}
			iterateErrors('', errors).forEach( function (error) {
        this.errorBlock.append($('<li />').text(error))
      })
			_.each(errors, function (value, field) {
				if (value.length > 0) this.$('[name='+field+']').addClass('field_error')
			})
			this.errorBlock.css({display: 'none'}).prependTo(this.el).slideDown(300)
			this.errorBlock.scrollTo(300, -10);
    }
    
    this.hideErrors = function () {
      if (this.errorBlock instanceof jQuery) this.errorBlock.css({display: 'none'})
      this.$('[name]').removeClass('field_error')
    }
  }
  
})