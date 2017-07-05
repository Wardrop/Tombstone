module Tombstone
  Root.controller '/place', conditions: {logged_in: true} do

    get '/manage', 1 do
      @place = Place.with_pk(request.GET['place_id']) if request.GET['place_id']
      render :'place/manage'
    end

    get '/' do
      redirect absolute('/place/manage')
    end

    get '/:id' do |id|
      @place = Place.with_pk(id)
      if @place
        render :'place/view'
      else
        halt 404, render("error", :locals => {message: "Place with ID ##{id} does not exist."})
      end
    end

    get '/:id', media_type: 'application/json' do |id|
      json_response Place.with_pk(id).values
    end

    # Valid ranges: Row [A-Z], Plot [1-49]a, Row [A-ZZ], Plot[001-150]
    # Zero-prefixes are decided at a global level.
    post '/', media_type: 'application/json' do
      place = Place.new.set_valid_only(request.POST)
      if place.valid?
        parsed = parse_place_name(request.POST['name'])
        if parsed.nil?
          place.save
        elsif Array === parsed
          new_places = parsed.map { |v| Place.new(request.POST.merge({'name' => v})) }
          if new_places.all? { |place| place.valid? }
            new_places.each { |place| place.save }
          else
            place.errors.add(:name, "One or more of the new place names conflict with an existing sibling. Place names must be unique among siblings.")
          end
        else
          place.errors.add(:name, parsed)
        end
      end
      json_response(errors: place.errors)
    end

    put '/:id', media_type: 'application/json' do |id|
      place = Place.with_pk(id)
      halt 404, "Place with ID ##{id} does not exist." unless place
      place.set_valid_only(request.POST)
      if place.valid?
        place.save
      end
      self.response.status = 500 unless place.errors.empty?
      json_response(errors: place.errors)
    end

    delete '/:id', media_type: 'application/json' do |id|
      place = Place.with_pk(id)
      halt 404, "Place with ID ##{id} does not exist." unless place
      response = {}
      if place.allocations_dataset.count > 0
        response[:errors] = "Cannot delete place with ID ##{id} because it has associated allocations."
      elsif place.children_dataset.count > 0
        response[:errors] = "Cannot delete place with ID ##{id} because it contains child places."
      else
        unless place.destroy
          response[:errors] = "An unknown error occured while deleting place with ID ##{id}."
        end
      end
      json_response response
    end

    get %r{/([0-9]+)/next_available}, media_type: 'application/json' do |id|
      place = Place.with_pk(id)
      halt 404, "Place with ID ##{id} does not exist." unless place
      next_available = place.next_available
      response = begin
        if next_available
          ancestors = next_available.ancestors(true, id).reverse
          ancestors.map do |place|
            place.siblings.with_child_count.available_only.with_natural_order.naked.all
          end
        else
          nil
        end
      end
      json_response response
    end

    get %r{/([0-9]+)/children(/[^/]+)?}, media_type: 'application/json' do |id, filter|
      filter = filter[1..-1] if filter
      id = (id.to_i < 1) ? nil : id.to_i
      places = Place.filter(:parent_id => id)
      if filter
        case filter
        when 'available'
          places = places.available_only
        when 'all'
        else
          halt 404
        end
      end
      json_response places.with_child_count.with_natural_order.naked.all
    end

    get '/ancestors/:id', media_type: 'application/json' do |id|
      place = Place.with_pk(id)
      halt 404, "Place with ID ##{id} does not exist." unless place
      chain = place.ancestors(!!request.GET['include_self']).reduce([]) do |memo, anc|
        memo << Place.filter(:parent_id => anc.parent_id).with_natural_order.naked.all
      end
      json_response chain
    end

    # Takes a plot name with optional range. Returns an array of generated names if range exists and is valid, otherwise
    # returns an error string when invalid. Returns nil if there are no square brackets in the string.
    # Error handling is made verbose as to guide the user.
    def parse_place_name(name)
      if name =~ /[\[\]]/
        if name.scan(/[\[\]]/).length > 2
          'Found multiple opening or closing square brackets. Only one range can be specified.'
        elsif not name.match(/\[[^\[\]]+\]/)
          'Mismatched square brackets.'
        elsif not name.match(/\[\w+[.]{2,3}\w+\]/)
          'Invalid range specified. Must be in the form [\w..\w] or [\w...\w] where "\w" is one or more word '+
            'characters (e.g. numbers, letters).'
        else
          full, before, from, to, after = name.match(/(.*)\[(\w+)[.]{2}(\w+)\](.*)/).to_a
          begin
            range = Range.new(from, to).to_a
            range.map! { |v| "#{before}#{v}#{after}" }
          rescue ArgumentError => e
            'Invalid range specified.'
          end
        end
      end
    end

  end
end
