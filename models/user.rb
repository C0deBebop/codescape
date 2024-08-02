require './models/post.rb'

class User
   include Mongoid::Document
   field :name, type: String
   field :username, type: String
   field :email, type: String
   field :password, type: String
   field :image, type:  String
   field :created_at, type: DateTime
   field :last_active, type: DateTime
   field :ranking, type: String
   has_many :posts
end