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
    
  end
end
