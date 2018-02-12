require 'sinatra'
require 'sinatra/activerecord' #ERROR: CANNOT LOAD SUCH FILE!!!
#require 'data_mapper'     
require 'pp'
set :logging, :true

ActiveRecord::Base.establish_connection(
 :adapter => 'sqlite3',
 :database => 'wiki.db'
)
class User < ActiveRecord::Base
 validates :username, presence: true, uniqueness: true
 validates :password, presence: true
end


=begin
        class User 
            include DataMapper::Resource 
            property :id, Serial 
            property :username, Text, :required => true
            property :password, Text, :required => true 
            property :date_joined, DateTime 
            property :edit, Boolean, :required => true, :default => false 
            
         #   (@user == nil ? '<p>Click here to login</p>' : '<p>User logged in #{NAME}</p>')
         end
=end 
 

# DataMapper.finalize.auto_upgrade!


$myinfo = "Jakob Fischer"
@info =""

def readFile(filename)
    info = ""
    file = File.open(filename)
    file.each do |line|
        info = info + line
    end
    file.close
    $myinfo = info
end

helpers do
    def protected!
        if authorized?
            return
        end
    redirect '/denied'
    end
    
    def authorized?
        if $credentials != nil
            @Userz = User.where(:username => $credentials[0]).to_a.first
            if @Userz
                if @Userz.edit == true
                    return true
                else
                    return false
                end
            else
                return false
            end
        end
    end
end

get '/'do 
    info = "Hello there!"
    len = info.length
    len1 = len
    readFile("wiki.txt")
    @info = info + " " + $myinfo
    len = @info.length
    len2 = len - 1
    len3 = len2 - len1
    @words = len3.to_s
    erb :home
end
        
get'/about'do
    erb :about
end
        
get'/create'do
   protected!
   erb :create
end
       
get '/edit' do
    protected!
    info = ""
    file = File.open("wiki.txt")
    file.each do |line|
        info = info + line
    end
    file.close
    @info = info
    erb :edit
end

put '/edit' do
    protected!
        info = "#{params[:message]}"
        @info = info
        file = File.open("wiki.txt", "w")
        file.puts @info
        file.close
        redirect'/'
end

get '/reset' do
    protected!
    File.open("wiki.txt", "w") { |file| file.truncate(0) } # the reset process was implemented adapting te information fond in the following stackoverflow q/a: https://stackoverflow.com/questions/3815979/delete-all-the-content-from-file
    # File.close("wiki.txt") why doesnt this work? returns error that .close doesn't exist => still contents get deleted
    erb:reset
end

get '/login' do
    erb:login
end

post '/login' do
    $credentials = [params[:username],params[:password]]
    @Users = User.where(:username => $credentials[0]).to_a.first
    if @Users
        if 
            @Users.password == $credentials[1]
            redirect '/'
        else
            $credentials = ['','']
            redirect '/wrongaccount'
        end
    else
        $credentials = ['','']
        redirect '/wrongaccount'
    end
end

get '/wrongaccount' do
erb :wrongaccount
end
   
get '/wrongaccount' do
    erb:wrongaccount 
end


get '/user/:uzer' do
    @Userz = User.where(:username => params[:uzer]).first
    if @Userz != nil
        erb :profile
    else
        redirect '/noaccount'
    end
end
  
get '/createaccount' do
    erb :createaccount 
end


post '/createaccount' do
    n = User.new
    n.username = params[:username]
    n.password = params[:password]
    if n.username == "Admin" and n.password == "Password"
        n.edit = true
    end
    n.save
    redirect '/'
end
    
put '/user/:uzer' do
    n = User.where(:username => params[:uzer]).to_a.first
    n.edit = params[:edit] ? 1 : 0
    n.save
    redirect '/'
end

get '/user/delete/:uzer' do
    protected!
    n = User.where(:username => params[:uzer]).to_a.first
    if n.username == "Admin"
        erb :denied
    else
        n.destroy
        @list2 = User.all.sort_by { |u| [u.id] }
        erb :admincontrols
    end
end    

get '/admincontrols' do
    protected!
    @list2 = User.all.sort_by { |u| [u.id] }
    erb :admincontrols
end
    
get '/logout' do
    $credentials = [' ',' ']
    redirect '/'
end

get '/notfound' do
    erb:notfound
end

get '/noaccount' do
    erb:noaccount
end

get '/denied' do
    erb:denied
end

not_found do
        status 404
        redirect '/notfound'
end