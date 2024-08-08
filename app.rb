require 'sinatra'
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
    
    before ['/forums/latest', '/forums/:forum_id', '/forums/tag/:tagname', '/forums/add/reply/:forum_id',
      '/forums/category/:category_name', '/edit/forum/:forum_id']  do |pages|
      @categories = Post.distinct("category")
      @colors = Post.distinct("color")
      @tags = Post.distinct("tags")
      @menu_items = Post.category_menu(@categories, @colors)
    end    

    before do
      @redis = Redis.new
      Mongoid.raise_not_found_error = false
    end
     
    post '/signup' do  
      content_type :json   
      post_data = JSON.parse(request.body.read, symbolize_names: true)
      data = {
        :name => post_data[:fullname],
        :username => post_data[:username],
        :email => post_data[:email], 
        :created_at => DateTime.now(),
        :last_active => DateTime.now(),
        :image => 'default.png',
        :session_id => session.id, 
        :password => post_data[:password]
      }
      #check to see if user has account
      @user = User.new
      user_credentials = @user.check_for_account(data)
      unless user_credentials  
        #create user and session
        @user.create_session(@redis, session.id, post_data[:email])
        @user.create_account(data)
        return {status: 200}.to_json
      else
        return {status: 401}.to_json
      end 
    end  

    get '/' do  
      erb :index 
    end  

    get '/signup' do
      erb :signup
    end

     post '/' do
       user = User.new
       account_status = user.check_for_account(params[:email])
       password_valid = user.check_password(params[:password], account_status["password"])
       if account_status && password_valid
         puts session.id
         session_data = {redis: @redis, email: params[:email], session_id: session.id}
         user.check_for_session(session_data)
         redirect '/forums/latest'
       else
         redirect '/signup'
       end 
     end   

    get '/forums/latest' do
       @user = User.get_user_account(@redis, session.id)
       unless @user
         redirect '/signup'
       else
        @page = 'Latest'
        @posts = Post.get_latest_five
        erb :latest
      end
    end

    get '/forums/:forum_id' do 
      @page = 'Forum'
      @user = User.get_user_account(@redis, session.id)
      @post = User.get_user_post(params[:forum_id])
      @replies = Reply.get_post_replies(params[:forum_id])
      @author = User.find(@post["user_id"])
      erb :forum
    end    

    get '/forums/add/reply/:forum_id' do
      @page = 'Add reply' 
      @user = User.get_user_account(@redis, session.id)
      @post = Post.find(params[:forum_id])
      erb :reply
    end
    
    post '/forums/add/reply/:forum_id' do
      @user = User.get_user_account(@redis, session.id)
      @post = Post.find(params[:forum_id])
      reply = Reply.new
      data = {id: @user._id, reply: params[:reply], likes: 0, forum_id: params[:forum_id]}
      reply.add_reply(data)
      erb :reply
    end   

    post '/forums/:forum_id/reply/:reply_id' do
       content_type :json   
       data = JSON.parse(request.body.read, symbolize_names: true)
       @reply = Reply.new
       @reply.delete_reply(data[:forum_id], data[:reply_id])
       return {status: 200}.to_json
    end
  
    get '/forums/category/:category_name' do 
        @page = 'Categories' 
        category = params[:category_name]
        splitCategory = category.split("-").join(" ")
        @posts = Post.where(category: splitCategory)
        @user = User.get_user_account(@redis, session.id)
        erb :latest
     end

    get '/forums/tag/:tagname' do
        @page = 'Tags'
        @user = User.get_user_account(@redis, session.id)
        @posts = Post.where(tags: params[:tagname])
        erb :latest
    end

    get '/add/forum' do
      @categories = Post.distinct("category")
      @colors = Post.distinct("color")
      @tags = Post.distinct("tags")
      @menu_items = Post.category_menu(@categories, @colors)
      @user = User.get_user_account(@redis, session.id)
      erb :'add-forum'
    end  

    get '/profiles/:id' do 
      erb :profile
    end  

    get '/add/profile' do        
       erb :profile
    end  
    
    
    post '/add/profile' do
       experience = params[:experience]
       profile_image = params[:image]
       @user = User.get_user_account(@redis, session.id)
       if @user.empty?
          redirect '/'
       else
          @user.update_attributes!(
             image: profile_image,
             ranking: experience,
             last_active: DateTime.now()
          )
          redirect '/forums/latest'
       end  
    end

    get '/profile/:user_id' do
      @user = User.get_user_account(@redis, session.id)
      erb :profile 
    end


    get '/profile' do

    end

    get '/profile/search/:user' do

    end

    post '/add/forum' do
      @user = User.get_user_account(@redis, session.id)
      if @user.empty?
         redirect '/'
      else
         topic = params[:topic]
         splitCategory =  params[:categories].split(',')
         category = splitCategory[0].downcase
         color = splitCategory[1]
         tag = params[:tag]
         tag2 = params[:tag2]
         forum_post = params[:forumpost]
         post = @user.posts.create!(
            topic: topic, 
            category: category, 
            color: color,
            tags: [tag, tag2], 
            views: 0, 
            likes: 0,
            date_added: DateTime.now(),
            discussion: forum_post
         ){}.to_json
         redirect '/forums/latest'
       end
    end 
    

   get '/edit/forum/:forum_id' do
       @page = 'Edit forum'
       @post = Post.find(params[:forum_id])
       @menu_items = Post.category_menu(@categories, @colors)
       @user = User.get_user_account(@redis, session.id)
       erb :edit
    end  

    post '/edit/forum/:forum_id' do
      @post = Post.find(params[:forum_id])
      @post.update_attributes!(
         topic: params[:topic],
         category: params[:category],
         tags: [params[:tag]],
         date_added: DateTime.now(),
         discussion: params[:discussion]
      )
  end  


  get '/logout' do
    user = User.new
    session_status = user.get_session(@redis, session.id)
    session_key = "user:000#{session.id}"
    puts session_status
    if session_status
      user.signout(@redis, session_key)
      session.clear
      redirect '/'      
    end
  end

    not_found do
     
    end   

    run!
end