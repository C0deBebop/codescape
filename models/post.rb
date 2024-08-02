require './models/user.rb'

class Post
    include Mongoid::Document
    field :topic, type: String
    field :date_added, type: DateTime
    field :views, type: Integer
    field :category, type: String
    field :likes, type: Integer
    field :last_active, type: DateTime
    field :color, type: String
    field :discussion, type: String
    field :tags, type: Array
    belongs_to :user
    embeds_many :replies
end

class Reply
   include Mongoid::Document
   include Mongoid::Timestamps::Created
   field :reply_id, type: BSON::ObjectId
   #field :user_id, type: BSON::ObjectId
   field :reply, type: String
   field :likes, type: Integer
   embedded_in :post
end




