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

    def add(data)
      json = JSON.parse(data)  
      Post.create!(json)
    end

    def update(id, data)
      json = JSON.parse(data)   
      post = Post.find(id)
      post.update_attributes!(json)
    end
    
    def remove(id)
      post = Post.new(_id: id)
      post.delete
    end

    def self.get_latest_five
       Post.all.order_by([:date_added, :desc]).limit(5) 
    end

    def get_all
      Post.all.sort({_id: -1})   
    end   

    def self.category_menu(categories, colors)
        menu_items = []
        categories.zip(colors).each do |(category, color)|
          menu_items.push({:category => category, :colors => color}) 
        end 
        menu_items
    end    
 
end

class Reply
   include Mongoid::Document
   include Mongoid::Timestamps::Created
   field :reply_id, type: BSON::ObjectId
   field :reply, type: String
   field :likes, type: Integer
   embedded_in :post

   def self.get_post_replies(forum_id)
      post = Post.find(forum_id)
      discussion_replies = post.replies.all
      replies = []
      discussion_replies.each do |reply|
        user_data = User.find(reply.reply_id)
        replies.push({
            :username => user_data.username,
            :image => user_data.image,
            :reply => reply.reply,
            :created_at => reply.created_at.strftime('%m/%d/%Y'),
            :likes => reply.likes,
            :reply_id => reply._id
        })
     end  
     replies 
   end 

   def add_reply(data)
     post = Post.find(data[:forum_id]) 
     post.replies.create!(
       reply_id: data[:id],
       reply: data[:reply],
       likes: data[:likes]
     ) 
   end 

   def delete_reply(forum_id, reply_id)
      post = Post.find(forum_id)
      reply = post.replies.find(reply_id)
      reply.delete
   end 
end




