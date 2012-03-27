$( function () {
	Ts.FormViews.AllocationForm = Ts.View.extend({
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
					var placeView = new Ts.FormViews.PlacesPicker({
            selected: currentPlace,
            collection: collection,
            disabled: !this.allocationData.id
          })
					section.body.unshift(placeView.render().el)
          currentPlace = siblings[0].parent_id
				}
        if (placeView.options.disabled) {
          section.body.unshift($('<input type="hidden" name="place[]" value="'+place_id+'" />')[0])
        }
			} else {
				var collection = new Ts.Places(this.placeData[''])
				var placeView = new Ts.FormViews.PlacePicker({collection: collection})
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
					default: _.bind(function (el) {
						this.submit(el.attr("name"))
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
			this.indicator.attr('class', 'indicator loading').insertAfter(this.multibutton.el)
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
				data[role_type] = roleBlock.getJSON()
		  })
			return data
		},
		showFormErrors: function (errors) {
			var container = $('<ul class="error_block" />')
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
			iterateErrors('', errors).forEach( function (error) {
        container.append($('<li />').text(error))
      })
			
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