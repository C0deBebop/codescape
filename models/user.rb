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
   field :status, type: String
   field :ranking, type: String
   validates_uniqueness_of :username, :email
   has_many :posts

   RANKINGS = {
      novel_novice: 0,
      burgeoning_badger: 1,
      sprawling_sprite: 2,
      artful_codesmith: 3,
      inquisitive_wizard: 5,
      adventurous_inventor: 10,
      contemplative_codger: 20
   }

   def check_for_account(email)
      #check for account existence by email(emails must be unique)
     user = User.find_by(email: email)
     if user.nil?
        false
     else
         user   
     end
   end   

   def create_account(data)
      User.create!(
         name: data[:name],
         username: data[:username],
         email: data[:email],
         password: hash_user_password(data[:password]),
         image: data[:image],
         created_at: DateTime.now(),
         last_active: DateTime.now(),
         status: 'active'
      )
   end
   
   #def update_settings()
      #this updates the settings view of the user profile(username, email, password)
   #end

   def setup_profile(data)
      #add user details after account creation
      json = JSON.parse(data)
      user = User.find_by(email: json["email"])
      user.update_attributes!(
         image: json["image"],
         ranking: json["ranking"],
         last_active: DateTime.now(),
         bio: json["bio"]
      )
   end   

   def self.get_all_user_post(email)
       user = User.find_by(email: email)
       user.attributes.merge(
           posts: user.posts
       )
   end    
   
   def self.get_user_post(post_id)
      Post.find(post_id) 
   end  

   def update_profile(data)
      #this updates the profile of the user(profile image and bio)
      json = JSON.parse(data)
      user = User.find_by(email: json['email'])
      user.update_attributes!(json)
   end   

   def update_ranking(user)
      #get account creation year and the current year and if the current year is greater than the creation year
      #change the users ranking(if it falls into one of the experience rankings ie. 5 yrs inquisitive wizard, 
      #3 yrs artful codesmith)
      account_creation = user.created_at
      current_date = DateTime.now()
      account_creation_year = account_creation.strftime('%Y')
      current_year = current_date.strftime('%Y')
      if current_year > account_creation_year
          #get ranking, add the year and see if it unlocks a new ranking
          #RANKINGS[:]
      end
   end 

   def deactivate_account(email)
     user = User.find_by(email: email)
     user.update_attributes!(status: 'inactive', last_active: DateTime.now())
   end

   #same as get_session(choose one)
   def self.get_user_account(redis, session_id)
      data = redis.hgetall("user:000#{session_id}").to_json
      @json = JSON.parse(data)
      @user = User.find_by(email: @json["email"])
   end   
      
   def hash_user_password(password)
      BCrypt::Password.create(password)
   end  
   
   def check_password(password, user_password)
      hashed_password = BCrypt::Password.new(user_password)
      if hashed_password == password
          true
      else
          false
      end
   end   
   
   def check_for_session(data)
      session_id = data[:session_id]
      redis = data[:redis]
      session_result = redis.hgetall("user:000#{session_id}")
      if session_result.empty?
         create_session(redis, session_id, data[:email])
      else
         session_result.to_json
      end 
   end 

   #same as get_user_account(choose one)
   def get_session(redis, session_id)
      #get user session if it exists or return false
      session_data = redis.hgetall("user:000#{session_id}").to_json
      if session_data.empty?
         false
      else
         session_data   
      end
   end   

   def create_session(redis, session_id, email)
     #create a user session
     redis.mapped_hmset("user:000#{session_id}", {:email => email})
   end  
   
   def signout(redis, user_session)
      if redis.exists?(user_session)
         redis.del(user_session)
      end 
   end

end

