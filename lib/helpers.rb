module Tombstone
  module Helpers
    
    def include_script_templates(*templates)
      templates.each do |template|
        if template[-1] == '/'
          files = Dir.glob("views/script_templates/#{template}*.html").map { |f| f.sub(%r~^views/script_templates/(.*).html$~, '\1') }
          include_script_templates(*files)
        else
          @document[:script_templates] << template
        end
      end
    end
    
  end
end
