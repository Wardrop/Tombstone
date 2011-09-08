class User
  def authenticate(username, password); end
  def findByID(user_id); end
  def find(where); end
  def update(user_id, fields); end
  def validate(fields); end
end

class Article
  def findByUser(user_id); end
  def findByID(id); end
  def find(where); end #=> article.title, article.body, ..., user.name, user.age, ..., tag.name
end

class User
  class << self    
    def authenticate(username, password)
    end    
  end  
  
  fields :id, :name, :age, :occupation
  
  def validate
    # Returns true when valid, or a ValidationErrors object when invalid.
  end
  
  
  
  def authenticate(password)
    # Call class method with loaded username.
  end
end

def showArticles
  "SELECT article.*, user.* FROM article JOIN user ON article.user_id = user.id"
end


class Article
  field
  def save; end
end