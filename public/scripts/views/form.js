$( function () {
  Ts.FormViews = {}
  Ts.FormViews.RoleBlock = Backbone.View.extend({
    className: 'row_block clickable',
    template: _.template($('#form\\:role_block_template').html()),
    events: {
      'click div.row_block' : 'changeRole',
      'click a.add' : 'addRole',
      'click .actions a.delete' : 'removeRole'
    },
    initialize: function () {
      this.role_type = this.options.role_type
			this.role_name = this.options.role_name || this.role_type.split('_').join(' ').toTitleCase()
      _.bindAll(this, 'render', 'addRole', 'changeRole', 'onCompleteCallback')
    },
    render: function () {
      $(this.el).html(this.template({model: (this.model) ? this.model.recursiveToJSON() : null}))
  		return this
    },
    addRole: function () {
      wizard = new Ts.RoleWizard({title: "Add "+this.role_name, role: new Ts.Role({type: this.role_type})})
			wizardView = new Ts.RoleWizardViews.WizardView({
        model: wizard,
        onComplete: this.onCompleteCallback
      })
      $('body').prepend(wizardView.render().el)
    },
    changeRole: function () {
      clonedModel = new Ts.Role({
        type: this.role_type,
        person: this.model.get("person").clone(),
        residential_contact: this.model.get("residential_contact").clone(),
        mailing_contact: this.model.get("mailing_contact").clone()
      })
      clonedModel.get("person").set({id: null})
      wizard = new Ts.RoleWizard({title: "Change "+this.role_name, role: clonedModel})
			wizardView = new Ts.RoleWizardViews.WizardView({
        model: wizard,
        onComplete: this.render
      })
      $('body').prepend(wizardView.render().el)
    },
    removeRole: function () {
      if(confirm('Are you sure you want to remove this object?')) {
        this.model = null
        this.render()
      }
      return false
    },
    onCompleteCallback: function (role) {
      this.model = role
      this.render()
    }
  })
  
  Ts.FormViews.Multibutton = Backbone.View.extend({
    tagName: 'span',
    className: 'multibutton',
    template: _.template($('#form\\:multibutton_template').html()),
    events: {
      'click span.dropdown_button' : 'toggleList',
      'click ul input' : 'onSelectListItem'
    },
    initialize: function () {
      _.bindAll(this, 'hideList', 'showList', 'keydownHideEvent')
    },
    render: function () {
      $(this.el).html(this.template({name: this.options.name, options: this.options.values}))
      var list = this.$('ul')
      list.css('display', 'none')
      this.selectButton(list.find('input:first'))
      this.hideList()
  		return this
    },
    toggleList: function () {
      var hidden = this.$('ul').css('display') == 'none'
			hidden ? this.showList() : this.hideList()
    },
    showList: function () {
      var list = this.$('ul')
      list.css('min-width', $(this.el).outerWidth());
      list.css('display', '')
      var viewport_bottom = $(window).scrollTop() + $(window).height();
			var list_bottom = list.offset().top + list.outerHeight();
			if((list_bottom + 10) > viewport_bottom) {
			  $(this.el).addClass('top');
			} else {
			  $(this.el).addClass('bottom');
			}
			// If we don't wrap this binding in a delay, it'll fire directly after this event which is not what we want.
			_.delay(function (self) { $(document).click(self.hideList); }, 1, this);
			$(window).blur(this.hideList)
			$(document).keydown(this.keydownHideEvent)
    },
    hideList: function () {
      this.$('ul').css('display', 'none')
			$(this.el).removeClass('top bottom')
      $(document).unbind('click', this.hideList)
			$(window).unbind('blur', this.hideList)
			$(document).unbind('keydown', this.keydownHideEvent)
    },
    selectButton: function(selected) {
      $(this.el).children('input').remove()
			$(this.el).prepend($(selected).clone(true))
		  this.$('ul > li').removeClass('selected').find(selected).parent().addClass('selected')
		},
    onSelectListItem: function (e) {
      this.selectButton(e.currentTarget)
    },
    keydownHideEvent: function (e) {
      if (e.keyCode == 27) this.hideList();
    }
  })
  
  Ts.FormViews.PlacesView = Backbone.View.extend({
    tagName: 'label',
    template: _.template($('#form\\:place_list_template').html()),
    events: {
      'change': 'selectPlace'
    },
    initialize: function () {
      this.selected = this.options.selected
      _.bindAll(this, 'selectPlace')
    },
    render: function () {
      $(this.el).html(this.template({
					type: this.collection.first().get('type'),
					places: this.collection.toJSON(),
					selected: this.selected
			}))
			setTimeout("this.$('select').focus()")
      return this
    },
    renderPlaces: function (places, selected) {
      var view = (new Ts.FormViews.PlacesView({collection: places, selected: selected}))
      $(this.el).parent().append(view.render().el)
    },
    selectPlace: function (e) {
      var target = $(e.target)
      var placeId = target.children(':selected').attr('value')
      if(placeId) {
        $(this.el).nextAll().remove()
        this.$('.loading').remove()
        if(target.data('placeType') == 'section') {
          this.nextAvailable(placeId)
        } else {
          this.loadPlaceList(placeId)
        }
      } else {
        $(this.el).nextAll().remove()
      }
    },
    loadPlaceList: function (parent_id) {
      this.lastRequest && this.lastRequest.abort()
      $(this.el).append('<div class="loading" />')
      this.lastRequest = $.ajax('/place/children/'+parent_id, {
				type: 'GET',
				dataType: 'json',
        success: _.bind(function (data, textStatus, jqXHR) {
          var places = new Ts.Places(data)
          if(places.length > 0) {
            var childPlacesView = new Ts.FormViews.PlacesView({collection: places})
            $(this.el).parent().append(childPlacesView.render().el)
          }
        }, this),
        error: function (jqXHR, textStatus, errorThrown) {
          // TODO
          if(textStatus != 'abort') alert('Some went wrong!')
        },
        complete: _.bind(function () {
          this.$('.loading').remove()
        }, this)
      })
    },
    nextAvailable: function (parent_id) {
      this.lastRequest && this.lastRequest.abort()
      $(this.el).append('<div class="loading" />')
      this.lastRequest = $.ajax('/place/next_available/'+parent_id, {
        type: 'GET',
				dataType: 'json',
        success: _.bind(function (data, textStatus, jqXHR) {
          _.each(data, function (place) {
            this.renderPlaces(new Ts.Places(place.siblings), place.id)
          }, this)
        }, this),
        error: function (jqXHR, textStatus, errorThrown) {
          // TODO
          if(textStatus != 'abort') alert('Some went wrong!')
        },
        complete: _.bind(function () {
          this.$('.loading').remove()
        }, this)
      })
    }
  })

	Ts.FormViews.AllocationForm = Backbone.View.extend({
  	events: {
			'click #actions_section input[type=button]' : 'submit'
		},
		initialize: function () {
			this.roles = this.options.roles
			this.loader = $('<div class="loading" />')
			_.bindAll(this, 'submit')
		},
		submit: function (e) {
			var data = this.formData()
			data.status = $(e.currentTarget).attr('name')
			this.loader.attr('class', 'loading').insertAfter('#actions_section .multibutton')
			this.hideFormErrors()
			if(this.lastRequest && this.lastRequest.state() == 'pending') {
				alert('The last submit operation has not completed. Please wait...')
				return false
			}
      this.lastRequest = $.ajax(this.el.action, {
        type: 'POST',
        data: data,
        success: _.bind( function (data, textStatus, jqXHR) {
          console.log(data)
          if(data.success == false) {
            this.showFormErrors(data.form_errors)
            this.loader.detach()
          } else {
            this.loader.attr('class', 'success')
						window.location = data.nextUrl
          }
        }, this),
        error: function (jqXHR, textStatus, errorThrown) {
					// TODO
          this.loader.detach()
          if(textStatus != 'abort') alert('Some went wrong!')
				}
      })
		},
		formData: function () {
			var data = $(this.el).serializeObject()
			data.what = null
      _.each(this.roles, function (role, name) {
        if (role.model) {
          data[name] = role.model.recursiveToJSON()
        }
      })
			return data
		},
		// field.split('_').join(' ')).toTitleCase()
		showFormErrors: function (errors) {
			var container = $('<ul class="form_errors" />')
			var iterateErrors = function (ul, errors) {
				_.each(errors, function (error, field) {
				  if (error.constructor == Array) {
						_.each(error, function (message) {
							errorObj = {}; errorObj[field] = message
							ul.append('<li>'+field.split('_').join(' ').toTitleCase()+'</li>')
							ul.append(iterateErrors($('<ul />'), errorObj))
						})
					} else if (error.constructor == Object) {
						ul.append(iterateErrors($('<ul />'), error))
					} else {
						ul.append('<li>'+error+'.</li>')
					}
				})
				return ul
			}
			
			iterateErrors(container, errors)
			
      _.each(errors, function (value, field) {
        this.$('[name='+field+']').addClass('field_error')
      })

      container.css({display: 'none'}).prependTo(this.el).slideDown(300)
			this.$(':first').scrollTo(300, -10);
		},
		hideFormErrors: function () {
			this.$('.form_errors').remove()
      this.$('[name]').removeClass('field_error')
		}
	})

})