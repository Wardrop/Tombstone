$( function () {
  Ts.View = Backbone.View.extend({
    template: function (obj) {
      this.template = _.template($('#'+this.templateId.replace(/([:.])/g, '\\$1')).html())
      return this.template(obj)
    },
    initialize: function () {
      if (this.options.bindToSync == undefined) {
        this.options.bindToSync = true
      }
      this.bindToSync(
			  this.eventReceiver = _.extend({}, Backbone.Events)
			)
      this.options.scrollToErrors = this.options.scrollToErrors || true
      this.indicator = this.options.indicator || $('<div class="indicator" style="display: none;" />')
      this.errorBlock = this.options.errorBlock || $('<ul class="error_block" style="display: none;" />')
      if(this.options.bindToSync) {
        _.each([this.collection, this.model], function (obj) {
          if (obj) this.bindToSync(obj)
        }, this)
      }
    },
    syncCallbacks: {
      'sync:before': function (method, obj) {
        this.indicator.css({display: ''}).attr({'class': 'indicator loading', title: ''})
        this.hideErrors()
      },
      'sync:always': function (method, obj)  {
        if (this.indicator.hasClass('loading')) this.indicator.css({display: 'none'})
      },
      'sync:fail': function (method, obj, jqXHR, textStatus, errorThrown) {
        if (textStatus == 'error') {
          var parsed
          try {
            parsed = $.parseJSON(jqXHR.responseText)
          } catch (err) { }
          if (parsed) {
            if (parsed.errors) {
              this.showErrors(parsed.errors)
            } else if (parsed.warnings) {
              this.showWarnings(parsed.warnings)
            } else {
              this.showErrors(parsed)
            }
          } else {
            this.showErrors("Server error encountered during '"+method+"' operation: "+errorThrown+" \n"+jqXHR.responseText)
          }
        } else {
          this.showErrors("Client error encountered during '"+method+"' operation: "+errorThrown)
        }
      }
    },
    bindToSync: function (obj) {
      _.each(['sync:before', 'sync:fail', 'sync:always'], function (event) {
        obj.on(event, this.syncCallbacks[event], this)
      }, this)
    },
    unbindFromSync: function (obj, context) {
      _.each(['sync:before', 'sync:fail', 'sync:always'], function (event) {
        obj.off(event, this.syncCallbacks[event], (context == undefined) ? this : context)
      }, this)
    },
    getJSON: function (selector) {
      try {
        return $(selector).parseJSON() || {}
      } catch (err) {
        return {}
      }
    },
    showErrors: function (errors) {
      if (!errors) errors = "Unknown error occured."
      if (this.errorBlock instanceof jQuery
          && this.errorBlock.length > 0
        /* && this.errorBlock.inDOM()*/ )
      {
        this.showErrorBlock(errors)
      } else {
        var errorStr = errors
        if (errors.constructor != String) {
          errorStr = this.stringifyErrors(errors).join("\n")
        }
        alert(errorStr)
      }
      if (errors.constructor == Object) {
        _.each(errors, function (value, field) {
          if (value.length > 0) this.$('[name='+field+']').addClass('field_error')
        })
      }
    },
    showWarnings: function (warnings) {
			warningOverlay = new Ts.WizardViews.WarningOverlay({
        model: new Ts.Wizard({title: "Warnings"}),
        'class': 'warning',
        onConfirm: _.bind(function () {
          this.el.action = this.el.action+'?confirm'
          this.submit()
          // this.$('section > [name=actions] > .multibutton li.selected').click()
        }, this)
      })
      warningOverlay.showWarnings(this.stringifyErrors(warnings))
      $('body').prepend(warningOverlay.render().el)
    },
    showErrorBlock: function (errors) {
      this.errorBlock.empty()
      if (errors.constructor == String) {
        this.errorBlock.append($('<li />').text(errors))
      } else {
        this.stringifyErrors(errors).forEach( function (error) {
          this.errorBlock.append($('<li />').text(error))
        }, this)
      }
      
      this.errorBlock.css({display: 'none'}).slideDown(300)
      if(this.options.scrollToErrors) {
        this.errorBlock.scrollTo(300, -10);
      }
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
  })
})