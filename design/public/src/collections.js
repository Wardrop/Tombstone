// JavaScript Document

Ts.Roles = Backbone.Collection.extend({
	model: Ts.Role
})

Ts.Addresses = Backbone.Collection.extend({
	model: Ts.Address,
  url: '/addresses'
})

Ts.People = Backbone.Collection.extend({
	model: Ts.Person,
  url: '/people'
})