$( function () {
  Ts.FormViews = {}
  Ts.FormViews.Section = Backbone.View.extend({
    tagName: 'section',
    template: _.template($('#form\\:section_template').html()),
    initialize: function () {
      this.body = []
      if (body = this.options.body) {
        this.body = (body.constructor == Array) ? body : [body]
      }
    },
    render: function () {
      $(this.el).html(this.template(this.options))
      _.each(this.body, function (element) {
        this.$('div').append(element)
      }, this)
      return this
    }
  })
  Ts.FormViews.RoleBlock = Backbone.View.extend({
    template: _.template($('#form\\:role_block_template').html()),
    events: {
      'click div.row_block' : 'changeRole',
      'click a.add' : 'addRole',
      'click a.delete' : 'removeRole'
    },
    initialize: function () {
      this.group = this.options.group || {}
      this.role_type = this.options.role_type
			this.role_name = this.options.role_name || this.role_type.split('_').join(' ').titleize()
      _.bindAll(this, 'render', 'addRole', 'changeRole', 'onCompleteCallback')
    },
    render: function () {
      $(this.el).empty()
      if (this.model) {
        $(this.el).html(this.template({model: (this.model) ? this.model.recursiveToJSON() : null}))
      } else {
        values = {add: 'Add'}
        actions = {add: this.addRole}
        _.each(this.group, function (roleBlock) {
          if(roleBlock != this) {
            values['use_'+roleBlock.role_type] = 'Use '+roleBlock.role_name.demodulize().titleize()
            actions['use_'+roleBlock.role_type] = _.bind( function () {
              this.useRole(roleBlock)
            }, this)
          }
        }, this)
        var multibutton = new Ts.FormViews.Multibutton({
          name: this.role_type + '_action',
          values: values,
          actions: actions
        })
        $(this.el).append(multibutton.render().el)
      }
  		return this
    },
    getJSON: function () {
      return (this.model && this.model.recursiveToJSON()) || (this.use && {type: this.role_type, use: this.use}) || null
    },
    addRole: function () {
      this.use = null
      wizard = new Ts.RoleWizard({title: "Add "+this.role_name, role: new Ts.Role({type: this.role_type})})
			wizardView = new Ts.RoleWizardViews.WizardView({
        model: wizard,
        onComplete: this.onCompleteCallback
      })
      $('body').prepend(wizardView.render().el)
    },
    useRole: function (roleBlock) {
      this.use = roleBlock.role_type
    },
    changeRole: function () {
      // clonedModel = new Ts.Role({
      //   type: this.role_type,
      //   person: this.model.get("person").clone(),
      //   residential_contact: this.model.get("residential_contact").clone(),
      //   mailing_contact: this.model.get("mailing_contact").clone()
      // })
      // clonedModel.get("person").set({id: null})
      wizard = new Ts.RoleWizard({title: "Change "+this.role_name, role: this.model})
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
      'click input' : 'onSelectButton'
    },
    initialize: function () {
      _.bindAll(this, 'hideList', 'showList', 'keydownHideEvent')
    },
    render: function () {
      $(this.el).html(this.template({name: this.options.name, options: this.options.values}))
      var list = this.$('ul')
      list.css('display', 'none')
      this.selectButton(this.options.selected || list.find('input:first')[0].name)
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
    selectButton: function(selectedName) {
      selected = this.$('[name='+selectedName+']')
			if (selected.parent()[0] != this.el) {
				$(this.el).children('input').remove()
				$(this.el).prepend(selected.clone(true))
			  this.$('ul > li').removeClass('selected').find(selected).parent().addClass('selected')
			}
		},
    onSelectButton: function (e) {
			var target = e.currentTarget
      this.selectButton(target.name)
			if (this.options.actions && this.options.actions[target.name]) {
				this.options.actions[target.name](e)
			} else if (this.options.actions && this.options.actions['default']) {
				this.options.actions['default'](e)
			}
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
      _.bindAll(this, 'selectPlace')
    },
    render: function () {
      $(this.el).html(this.template({
					type: this.collection.first().get('type'),
					places: this.collection.toJSON(),
					selected: this.options.selected,
          disabled: this.options.disabled
			}))
			setTimeout("this.$('select').focus()")
      return this
    },
    renderPlaces: function (places, options) {
      options = options || {}
      options.insertFunction = options.insertFunction || 'append'
      var view = (new Ts.FormViews.PlacesView({collection: places, selected: options.selected}))
      $(this.el).parent()[options.insertFunction](view.render().el)
      return this
    },
    selectPlace: function (e) {
      var target = $(e.target)
      var placeId = target.children(':selected').attr('value')
      if(placeId) {
        $(this.el).nextAll().remove()
        this.$('.indicator').remove()
        if(target.data('placeType') == 'section') {
          this.nextAvailable(placeId)
        } else {
          this.load(placeId)
        }
      } else {
        $(this.el).nextAll().remove()
      }
      
      return this
    },
    load: function (parent_id) {
      this.lastRequest && this.lastRequest.abort()
      $(this.el).append('<div class="indicator loading" />')
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
          this.$('.indicator').remove()
        }, this)
      })
      return this
    },
    nextAvailable: function (parent_id) {
      this.lastRequest && this.lastRequest.abort()
      $(this.el).append('<div class="indicator loading" />')
      this.lastRequest = $.ajax('/place/next_available/'+parent_id, {
        type: 'GET',
				dataType: 'json',
        success: _.bind(function (data, textStatus, jqXHR) {
          _.each(data, function (place) {
            this.renderPlaces(new Ts.Places(place.siblings), {selected: place.id})
          }, this)
        }, this),
        error: function (jqXHR, textStatus, errorThrown) {
          // TODO
          if(textStatus != 'abort') alert('Some went wrong!')
        },
        complete: _.bind(function () {
          this.$('.indicator').remove()
        }, this)
      })
      return this
    },
    loadWithAncestors: function (id) {
      this.lastRequest && this.lastRequest.abort()
      $(this.el).append('<div class="indicator loading" />')
      this.lastRequest = $.ajax('/place/ancestors/'+id, {
        type: 'GET',
				dataType: 'json',
        data: {include_self: true},
        success: _.bind(function (data, textStatus, jqXHR) {
          var lastParent = id
          _.each(data, function (placeList) {
            this.renderPlaces(new Ts.Places(placeList), {selected: lastParent, insertFunction: 'prepend'})
            lastParent = placeList[0].parent_id
          }, this)
        }, this),
        error: function (jqXHR, textStatus, errorThrown) {
          // TODO
          if(textStatus != 'abort') alert('Some went wrong!')
        },
        complete: _.bind(function () {
          this.$('.indicator').remove()
        }, this)
      })
      return this
    }
  })

	Ts.FormViews.AllocationForm = Backbone.View.extend({
		events: {
			'submit' : 'onSubmit'
		},
		onSubmit: function () {
			return false
		},
		initialize: function () {
			this.firstSection = $(this.el).children('section').first()
			this.placeData = $('#json\\:place_data').parseJSON() || {}
			this.allocationData = $('#json\\:allocation_data').parseJSON() || {}
			this.indicator = $('<div class="indicator" />')
			this.render()
		},
		render: function () {
			this.renderRoles()
			this.renderPlaces()
			this.renderActions()
			return this
		},
		renderRoles: function () {
			this.roleBlocks = {}
			var roleData = {}
			_.each(this.allocationData.roles, function (role) {
				roleData[role.type] = role
			})
			_.each(this.options.valid_roles, function (type) {
				var role;
				if (roleData[type]) {
					role = new Ts.Role({
						type: type,
						person: new Ts.Person(roleData[type].person),
						residential_contact: new Ts.Contact(roleData[type].residential_contact),
						mailing_contact: new Ts.Contact(roleData[type].mailing_contact)
					})
				}
				var roleBlock = new Ts.FormViews.RoleBlock({role_name: type, role_type: type, group: this.roleBlocks, model: role})
				this.roleBlocks[type] = roleBlock
				var section = new Ts.FormViews.Section({
					title: type.demodulize().titleize(),
					name: type,
					body: roleBlock.el
				})
				this.firstSection.before(section.render().el)
			}, this)
			_.each(this.roleBlocks, function (block) { block.render() })
			return this
		},
		renderPlaces: function () {
			var section = new Ts.FormViews.Section({title: 'Location', name: 'place'})
			if(place_id = this.allocationData.place_id) {
				var currentPlace = place_id
				while (currentPlace > 0) {
					var siblings = this.placeData[currentPlace]
					var collection = new Ts.Places(siblings)
					var placeView = new Ts.FormViews.PlacesView({
            selected: currentPlace,
            collection: collection,
            disabled: !this.allocationData.id
          })
					section.body.unshift(placeView.render().el)
          currentPlace = siblings[0].parent_id
				}
			} else {
				var collection = new Ts.Places(this.placeData[""])
				var placeView = new Ts.FormViews.PlacesView({collection: collection})
				section.body.push(placeView.render().el)
			}
			this.firstSection.before(section.render().el)
			return this
		},
		renderActions: function () {
			this.multibutton = new Ts.FormViews.Multibutton({
				name: 'submit',
				values: this.options.states,
				actions: {
					default: _.bind(function (e) {
						this.submit(e.currentTarget.name)
					}, this)
				}
			})
			var section = new Ts.FormViews.Section({
				title: 'Actions',
				body: this.multibutton.render().el
			})
			$(this.el).append(section.render().el)
		},
		submit: function (status) {
			var data = this.formData()
			data.status = status
			this.indicator.attr('class', 'indicator loading').insertAfter('#actions_section .multibutton')
			this.hideFormErrors()
			if(this.lastRequest && this.lastRequest.state() == 'pending') {
				if (confirm('The last submit operation has not yet completed. Would you like to abort the last submit operations?')) {
					this.lastRequest.abort()
				} else {
					return false
				}
			}
			this.lastRequest = $.ajax(this.el.action, {
				type: 'POST',
				data: data,
				success: _.bind( function (data, textStatus, jqXHR) {
					if(data.success == false) {
						this.showFormErrors(data.form_errors)
						this.indicator.detach()
					} else {
						this.indicator.attr('class', 'indicator success')
						window.location = data.redirectTo
					}
				}, this),
				error: _.bind( function (jqXHR, textStatus, errorThrown) {
					// TODO
					this.indicator.detach()
					switch(textStatus) {
						case 'error':
							try {
								this.showFormErrors($.parseJSON(jqXHR.responseText).exception.capitalize())
							} catch (err) {
								this.showFormErrors("Server error encountered: "+errorThrown+"\n"+jqXHR.responseText)
							}
							break;
						default:
							this.showFormErrors("Error encountered: "+errorThrown)
					}
				}, this)
			})
		},
		formData: function () {
			var data = $(this.el).serializeObject()
			_.each(this.roleBlocks, function (roleBlock, role_type) {
        console.log(roleBlock.getJSON())
				data[role_type] = roleBlock.getJSON()
		  })
			return data
		},
		showFormErrors: function (errors) {
			var container = $('<ul class="error_block" />')
			errors = (errors.constructor == String) ? [errors] : errors
			var iterateErrors = function (ul, errors) {
				_.each(errors, function (error, field) {
					if (error.constructor == Array) {
						_.each(error, function (message) {
							errorObj = {}; errorObj[field] = message
							ul.append($('<li />').text(field.split('_').join(' ').titleize()))
							ul.append(iterateErrors($('<ul />'), errorObj))
						})
					} else if (error.constructor == Object) {
						ul.append(iterateErrors($('<ul />'), error))
					} else {
						ul.append($('<li />').text(error))
					}
				})
				return ul
			}
			iterateErrors(container, errors)
			
			_.each(errors, function (value, field) {
				if (value.length > 0) this.$('[name='+field+']').addClass('field_error')
			})
	
			container.css({display: 'none'}).prependTo(this.el).slideDown(300)
			this.$(':first').scrollTo(300, -10);
		},
		hideFormErrors: function () {
			this.$('.error_block').remove()
			this.$('[name]').removeClass('field_error')
		}
	})
})