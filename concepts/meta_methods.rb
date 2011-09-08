class Model
  class << self
    def do_it
      define_method(:dog) { puts 'Hello there!' }
    end
  end
end

Model.do_it
Model.new.dog