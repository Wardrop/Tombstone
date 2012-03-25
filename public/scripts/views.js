$( function () {
  Ts.View = Backbone.View.extend({
    template: function (obj) {
      this.template = _.template($('#'+this.templateId.replace(/([:.])/g, '\\$1')).html())
      return this.template(obj)
    },
    initialize: function () {
      this.indicator = this.options.indicator || $('<div class="indicator" style="display: none" />')
      this.errorBlock = this.options.errorBlock || $('<ul class="error_block" style="display: none" />')
      
      var errorHandler = function (method, model, jqXHR, textStatus, errorThrown) {
        if (textStatus == 'error') {
					try {
					  parsed = $.parseJSON(jqXHR.responseText)
				  } catch (err) {
						this.showErrors("Server error encountered during '"+method+"' operation: "+errorThrown+" \n"+jqXHR.responseText)
					}
					if (parsed) {
					  if (parsed.exception)
					    this.showErrors("Server error encountered during '"+method+"' operation: "+parsed.exception.capitalize())
					  else
					    this.showErrors("Server error encountered during '"+method+"' operation: "+errorThrown+" \n"+parsed)
				  }
				} else {
				  this.showErrors("Client error encountered during '"+method+"' operation: "+errorThrown)
				}
      }
      
      _.each([this.collection, this.model], function (obj) {
        if (obj) {
          obj.on('sync:before', function () {
            this.indicator.css({display: ''}).addClass('loading')
          }, this)
          obj.on('sync:done', function (type, model, data) {
            if(data.success == false) {
              this.showErrors(data.form_errors)
            }
          }, this)
          obj.on('sync:fail', errorHandler, this)
          obj.on('sync:always', function () {
            if (this.indicator.hasClass('loading')) this.indicator.css({display: 'none'})
          }, this)
        }
      }, this)
    },
    getJSON: function (selector) {
      try {
        return $(selector).parseJSON() || {}
      } catch (err) {
        console.log('Contents of '+selector+ ' could not be parses as JSON')
        return {}
      }
    },
    showErrors: function (errors) {
      if (this.errorBlock instanceof jQuery
          && this.errorBlock.length > 0
          && this.errorBlock[0].nodeType > 0) { 
        this.showErrorBlock(errors)
		  } else {
		    var errorStr = (!errors || errors.constructor == String)
		      ? errors : 'The submitted data failed validation'
		    alert(errorStr)
		  }
    },
    showErrorBlock: function (errors) {
      this.errorBlock.empty()
      if (errors.constructor == String) {
        this.errorBlock.append($('<li />').text(errors))
      } else {
        this.stringifyErrors(errors).forEach( function (error) {
          this.errorBlock.append($('<li />').text(error))
        }, this)
        _.each(errors, function (value, field) {
  				if (value.length > 0) this.$('[name='+field+']').addClass('field_error')
  			})
      }
      if (!this.errorBlock.inDOM()) {
        this.errorBlock.prependTo(this.$el)
      }
			this.errorBlock.css({display: 'none'}).slideDown(300)
			this.errorBlock.scrollTo(300, -10);
    },
    stringifyErrors: function (errors) {
      errors = (errors.constructor == String) ? [errors] : errors
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
			return iterateErrors('', errors)
    },
    hideErrors: function () {
      if (this.errorBlock instanceof jQuery) this.errorBlock.css({display: 'none'})
      this.$('[name]').removeClass('field_error')
    }
    // bindToSync: function (obj) {
    //   if (obj) {
    //     obj.on('sync:fail', errorHandler)
    //     obj.on('sync:before', function () {
    //       this.indicator.css({display: ''}).addClass('loading')
    //     }, this)
    //     obj.on('sync:always', function () {
    //       if (this.indicator.hasClass('loading')) this.indicator.css({display: 'none'})
    //     }, this)
    //   }
    // },
    // unbindFromSync: function (obj) {
    //   obj.off('sync:before sync:fail sync:always', undefined, this)
    // }
  })
})