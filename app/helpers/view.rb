module Tombstone
  App.helpers do

    def include_script_views(*names)
      names.each do |name|
        @document[:scripts] << "views/#{name}.js"
        content_for :head do
          File.read File.join(settings.views, "script_templates/#{name}.html")
        end
      end
    end
    
    def build_breadcrumb(segments = nil)
      if segments.nil?
        route_name = route.named.to_s.sub(Regexp.new(/^#{route.controller}_/), '')
        segments = []
        segments << ['', "/"]
        segments << [route.controller.demodulize.titleize, "/#{route.controller}"]
        segments << [route_name.demodulize.titleize, "/#{route.controller}/#{request.path_info.slice(/#{route_name}.*$/)}"] unless route_name == 'index'
      end
      segments.dup.map { |title, uri|
        "<a href='#{url uri}' class='breadcrumb #{(title.empty?) ? 'home' : ''}'>#{title}</a>"
      }.join('<span class="breadcrumb div">/</span>')
    end
    
    def print_field(value)
      (value.blank?) ? '<small>none</small>' : value
    end
    
    # Takes a plain xml/xhtml string, an array of field names indicating which fields have errors, and an array of
    # field/value pairs for repopulating the form. Applies the CSS class "field_error" to each field with an error.
    # Availabe options are:
    #
    # errors: Array of field names with errors.
    # values: Hash of key/value pairs, where key is the field name.
    # selector: A CSS selector to provide scope.
    def prepare_form(xml, opts = {})
      doc = Nokogiri::HTML::Document.parse(xml)
      doc = doc.css(opts[:selector]) unless opts[:selector].nil?
      
      # Add error class to all fields with errors.
      unless opts[:errors].nil? || opts[:errors].empty?
        doc.css(opts[:errors].map { |v| "[name='#{v}']" }.join(", ")).each { |v| v['class'] = 'field_error' }
      end

      # Repopulate field with the given field values.
      unless opts[:values].nil? || opts[:values].empty?
        values = opts[:values]
        p values
        doc.css(values.keys.map { |k| "[name='#{k}']" }.join(", ")).each do |v|
          case v.name
            when 'input'
              v['value'] = values[v['name']] || values[v['name'].to_sym]
            when 'select'
              v.css('option').each do |option|
                option['selected'] = 'selected' if (values[v['name']] || values[v['name'].to_sym]) == option['value']
              end
            when 'textarea'
              v.content = values[v['name']] || values[v['name'].to_sym]
          end
        end
      end
      (doc.nil?) ? str : Nokogiri::HTML::Builder.with(doc).to_html
    end
    
  end
end
