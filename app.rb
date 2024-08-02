require 'sinatra/base'
require 'mongoid'
require 'dotenv'
require './models/user.rb'
require './models/post.rb'
require 'json'
require 'date'
require 'bcrypt'
require 'securerandom'
require 'redis'

Dotenv.load
Mongoid.load!(File.join(File.dirname(__FILE__), 'mongoid.yml'))
Dir[File.join(File.dirname(__FILE__), "models", "*.rb")].each { |model| require model }

class CodescapeApp < Sinatra::Base
    
    configure do
      enable :sessions
      set :sessions, :expire_after => 144000
      set :session_secret, ENV.fetch('SESSION_SECRET') {SecureRandom.hex(64)}

    end  
    
    before do
      @redis = Redis.new
    end    

    get '/' do  
        erb :index 
     end  

     post '/' do
        begin
           user = User.find_by(email: params[:email], password: params[:password])
        rescue Mongoid::Errors::DocumentNotFound
           redirect '/'
        else
           check_session = @redis.hgetall("user:000#{session.id}")
           if check_session.empty?
              @redis.mapped_hmset("user:000#{session.id}", {:email => params[:email]})
           end     
           redirect '/forums/latest'
        end   
          
     end   

    get '/forums/latest' do
       @page = 'Latest'
       @posts = Post.all.sort({_id: -1}).limit(5) 
       @categories = Post.distinct("category")
       @colors = Post.distinct("color")
       @tags = Post.distinct("tags")
       @menu_items = []
       @categories.zip(@colors).each do |(category, color)|
            @menu_items.push({:category => category, :colors => color}) 
       end 

        begin
          data = @redis.hgetall("user:000#{session.id}").to_json
          @json = JSON.parse(data)
          @user = User.find_by(email: @json["email"])
        rescue Mongoid::Errors::DocumentNotFound
          redirect '/' 
        end
        erb :latest
    end

    get '/forums/:forum_id' do 
      @page = 'Forum'
      @post = Post.find(params[:forum_id])
      @categories = Post.distinct("category")
      @colors = Post.distinct("color")
      @tags = Post.distinct("tags")
      @menu_items = []
      @categories.zip(@colors).each do |(category, color)|
           @menu_items.push({:category => category, :colors => color}) 
      end 
      #puts @post. 
      data = @redis.hgetall("user:000#{session.id}")
      @user = User.find_by(email: data["email"])

      @discussion_replies = @post.replies.all
      @replies = []
      @reply_count = @discussion_replies.count
      @discussion_replies.each do |reply|
          user_data = User.find(reply.reply_id)
          @replies.push({
            :username => user_data.username,
            :image => user_data.image,
            :reply => reply.reply,
            :reply_date => reply.created_at,
            :likes => reply.likes
         })
      end   




      erb :forum
    end    

    get '/forums/add/reply/:forum_id' do
      @page = 'Add reply' 
      data = @redis.hgetall("user:000#{session.id}")
      @user = User.find_by(email: data["email"])
      @post = Post.find_by(_id: params[:forum_id])

      #puts @replies
      erb :reply
    end
    
    post '/forums/add/reply/:forum_id' do
      data = @redis.hgetall("user:000#{session.id}")
      @user = User.find_by(email: data["email"])
      post = Post.find(params[:forum_id]) 
      reply = post.replies.create!(
         reply_id: @user._id,
         reply: params[:reply],
         likes: 0
      ) 
      erb :forum
    end   
 

    get '/signup' do
      erb :signup
    end

    post '/signup' do  
      content_type :json   
      data = request.body.read
      json = JSON.parse(data)
      post_date = DateTime.now()
      hashed_password = BCrypt::Password.create(json['password'])
      data = {:email => json['email']}
      check_session = @redis.hgetall("user:000#{session.id}")
      if check_session.empty?
         @redis.mapped_hmset("user:000#{session.id}", data)
         user = User.create!(
            name: json['fullname'],
            username: json['username'],
            email: json['email'],
            password: hashed_password,
            created_at: post_date,
            last_active: post_date,
            image: 'default.png'
         )          
      end
      return {success: 200}.to_json
    end    

    get '/forums/category/:category_name' do 
        @page = 'Categories' 
        category = params[:category_name]
        splitCategory = category.split("-").join(" ")
        @posts = Post.where(category: splitCategory)
        @categories = Post.distinct("category")
        @colors = Post.distinct("color")
        @tags = Post.distinct("tags")
        @menu_items = []
        @categories.zip(@colors).each do |(category, color)|
            @menu_items.push({:category => category, :colors => color}) 
        end 

        #move this to a method 
        data = @redis.hgetall("user:000#{session.id}")
        @user = User.find_by(email: data["email"])
        erb :latest
     end

    get '/forums/tags' do

    end

    get '/forums/tag/:tagname' do
        @page = 'Tags'
    
        @categories = Post.distinct("category")
        @colors = Post.distinct("color")
        @tags = Post.distinct("tags")
        @menu_items = []
        @categories.zip(@colors).each do |(category, color)|
            @menu_items.push({:category => category, :colors => color}) 
        end 
        data = @redis.hgetall("user:000#{session.id}")
        @user = User.find_by(email: data["email"])
        @posts = Post.where(tags: params[:tagname])
        puts params[:tagname]
        erb :latest
    end

    get '/add/profile' do        
       erb :profile
    end  
    
    
    post '/add/profile' do
       experience = params[:experience]
       profile_image = params[:image]
       current_date = DateTime.now()
       data = @redis.hgetall("user:000#{session.id}").to_json
       if data.empty?
          redirect '/'
       else
          json = JSON.parse(data)
          @user = User.find_by(email: json["email"])
          @user.update_attributes!(
             image: profile_image,
             ranking: experience,
             last_active: current_date
          )
          redirect '/forums/latest'
       end  
    end



    get '/profile' do

    end

    get '/profile/search/:user' do

    end

    get '/profile/:user_id' do

    end

    get '/add/forum' do
      @categories = Post.distinct("category")  
      @tags = Post.distinct("tags")
      erb :'add-forum'
    end  

    post '/add/forum' do
      data = @redis.hgetall("user:000#{session.id}").to_json
      json = JSON.parse(data)
      puts json
      if data.empty?
         redirect '/'
      else
         topic = params[:topic]
         splitCategory =  params[:categories].split(',')
         category = splitCategory[0].downcase
         color = splitCategory[1]
         tag = params[:tag]
         tag2 = params[:tag2]
         forum_post = params[:forumpost]
         current_date = DateTime.now()
         @user = User.find_by(email: json["email"])
         post = @user.posts.create!(
            topic: topic, 
            category: category, 
            color: color,
            tags: [tag, tag2], 
            views: 0, 
            likes: 0,
            date_added: current_date,
            discussion: forum_post
         ){}.to_json
         redirect '/forums/latest'
       end
    end 
    
    get '/logout' do
      session.clear  
      redirect '/'
    end

    not_found do
     
    end   

    run!
end