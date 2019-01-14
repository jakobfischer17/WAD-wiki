=begin
Ruby version 2.4 or higher required for this application.
The following additional gems to the ones installed within Cloud9 were used for this application:
  bond
  ripl
  ripl-multi_line
  ripl-rack
  tux
  sinatra/activerecord
  pp
  fileutils
  bcrypt
=end

#tells ruby which gems to use
require 'sinatra'
require 'sinatra/activerecord' 
require 'pp'
require 'bcrypt' # encrypts passwords by hashing it, found through  https://learn.co/lessons/sinatra-password-security
require 'fileutils' # found on the following stackoverflow page: https://stackoverflow.com/questions/33769865/check-if-two-files-have-same-content
set :logging, :true

#defines adapter and database file
ActiveRecord::Base.establish_connection(
 :adapter => 'sqlite3',
 :database => 'wiki.db'
)

#defines what a information about a user needs to be there (name and password,
#while the username has to be unique.)
class User < ActiveRecord::Base
 validates :username, presence: true, uniqueness: true
 has_secure_password 
end

$myinfo = "Jakob Fischer"
@info =""

helpers do
    def protected! #problem: authorizes any user that has edit rights to access admin controls through URL, so essentially only two authentication levels: normal user, admin.
        if authorized? #solution: see below
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
    
=begin
adminprotected adds another layer of authentication, so that only the user with
the username "Admin" is allowed to enter areas that are protected with 
adminprotected! It checks if the user is authorized (like in the "normal"
protected! routine) and if the user is an admin. This check is performed
in the helper isuseradmin. If the curent users username is "Admin", it returns
true and if not it returns false. Consequently, adminprotected! returns false
if the users name is not "Admin". This is a workaround and only allows 1 real
administrator, which is "Admin".
=end
    def adminprotected!
        if authorized? == true and isuseradmin? == true
            return
        else redirect '/denied'
        end
    end

#isuseradmin checks if the currently logged in user has the username "Admin"
    def isuseradmin?
        if $credentials != nil
            isadminornot = User.where(:username => $credentials[0]).to_a.first
            @adminuser = "#{isadminornot.username}"
            if @adminuser == "Admin"
                return true
            else 
                return false
            end
        end
    end
    
    #this method logs the respective user actions into the logfile log.txt and includes username and time.
    def updateLogFile(operation)
        file = File.open("log.txt", "a")
        
        if operation == "Login"
            file.puts "#{$credentials[0]} logged in at #{Time.now}"
        elsif operation == "Logout"
            file.puts "#{$credentials[0]} logged out at #{Time.now}"
        elsif operation == "Updated"
            file.puts "#{$credentials[0]} proposed an update to the wiki content at #{Time.now}"
        elsif operation == "Deleted"
            file.puts "#{$credentials[0]} deleted the wiki content at #{Time.now}"
        elsif operation == "Backup"
            file.puts "#{$credentials[0]} created a backup of wiki content at #{Time.now}"
        elsif operation == "Updateapproved"
            file.puts "#{$credentials[0]} approved an update to the wiki at #{Time.now}"
        elsif operation == "Updatedenied"
            file.puts "#{$credentials[0]} denied a proposed update to the wiki at #{Time.now}"
        elsif operation == "Adminupdate"
            file.puts "The administrator updated the wiki at #{Time.now}"
        elsif operation == "Viewlog"
            file.puts "#{$credentials[0]} viewed this file at #{Time.now}"
        else
            #Do something
        end
        file.close
    end

    #the following methods handle the access to the .txt files and enables the variable $myinfo to store the contents of the file to count words, characters, display the file etc.
    def readFile(filename)
        info = ""
        file = File.open(filename)
        file.each do |line|
            info = info + line
        end
        file.close
        $myinfo = info
    end    
end

#counts words and characters to display on the homepage (including whitespaces)
get '/'do 
    info = ""
    len = info.length
    len1 = len
    readFile("wiki.txt")
    @info = info + " " + $myinfo
    len = @info.length
    len2 = len - 1
    len3 = len2 - len1
    @characters = len3.to_s
    @words = $myinfo.split.length
    erb :home
end

#shows the About page with the about.erb view
get'/about'do
    erb :about
end

#shows the create page with the create.erb view
get'/create'do
   erb :create
end

#shows the edit page with the edit.erb view and shows contents of wiki.txt in the textbox  
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

=begin
updates wiki page. checks if the username is "Admin", in this case directly
updates the wiki.txt files and redirects to the /adminupdate page. If the user-
name is something else and the user thus not an admin, it saves the contents in 
a new file wikichange.txt, which the user "Admin" can approve in the Admincontols.
=end
put '/edit' do
    protected!
    if  $credentials[0] == "Admin"
        info = "#{params[:message]}"
        @info = info
        file = File.open("wiki.txt", "w")
        file.puts @info
        file.close
        redirect '/adminupdate'
    else
        info = "#{params[:message]}"
        @info = info
        file = File.open("wikichange.txt", "w")
        file.puts @info
        file.close
        File.truncate("wikichange.txt", File.size("wikichange.txt") - 1) #removing last character is important to compare if wiki.txt and wikichange.txt are identical, as ruby automatically adds a newline when creating wikichange.txt source: https://stackoverflow.com/questions/1190383/how-to-delete-last-line-of-file-in-ruby
        updateLogFile("Updated")
        redirect'/updatepending'
    end
end

=begin
the file wikichange.txt gets replaced with the contents of wiki.txt here to prevent
that when "Admin" updates the wiki, his changes still show in the /approveupdate
request
=end
get '/adminupdate' do
    adminprotected!
    IO.copy_stream('wiki.txt', 'wikichange.txt')
    updateLogFile("Adminupdate")
    erb:adminupdate
end

#shows the update pending page with the updatepending.erb view
get '/updatepending' do
    erb:updatepending
end

=begin
checks if wikichange.txt and wiki.txt are identical by using a FileUtils method
(.compare_file). If they are identical, the user gets redirected to the noupdate
page, as no update is necessary if the wikichange.txt file hasn't been altered
through the put '/edit' route. if the files are different and thus an update 
has been made, the contents get displayed to the admin and he has the option
to accept or decline the changes.
=end
get '/approveupdate' do
    adminprotected!
        @updateyesorno = FileUtils.compare_file('wikichange.txt', 'wiki.txt') #returns true if files are identical, source: https://stackoverflow.com/questions/33769865/check-if-two-files-have-same-content
       #problem: adds new line after writing to wikichange.txt so files are never identical, solution: the line "File.truncate("wikichange.txt", File.size("wikichange.txt") - 1)"" in put '/edit'  removes that last character
        if @updateyesorno == true
            redirect '/noupdate'
        elsif @updateyesorno == false
            info = ""
            file = File.open("wikichange.txt")
                file.each do |line|
                    info = info + line
                end
            file.close
            @updateyesorno = "#{info}"
            erb:approveupdate
        end
end

#shows the noupdate view which tells the admin that no update to the wiki is pending
get '/noupdate' do
    erb:noupdate
end

=begin
if the admin clicks on the accept button in the /approveupdate routine, the updates 
pending get applied: the contents of the wikichange.txt file get copied into the
wiki.txt file, so that the wiki.txt file now includes the changed content. As
both files are similar now, so the .compare_file function in /approveupdate will 
now return true.
=end
get '/acceptupdate' do
    adminprotected!
    updateLogFile("Updateapproved")
    IO.copy_stream('wikichange.txt', 'wiki.txt')
    erb:acceptupdate
    # replace wiki.txt content with wikichange.txt 
end

=begin
if the admin clicks on the decline button in the /approveupdate routine, the updates 
pending do not get applied: the contents of the wikichange.txt file are overwritten
with the contents of the wiki.txt file, so that the wiki.txt file shows the "old"
content that was already there before the update request.
Both files are similar now, so the .compare_file function in /approveupdate will 
now return true.
=end
get '/declineupdate' do
    adminprotected!
    updateLogFile("Updatedenied")
    IO.copy_stream('wiki.txt', 'wikichange.txt')
    erb:declineupdate
end

#deletes contents of wiki file
get '/reset' do
    adminprotected!
    File.truncate("wiki.txt", 0) # the reset process was implemented adapting the information found in the following stackoverflow q/a: https://stackoverflow.com/questions/3815979/delete-all-the-content-from-file
    updateLogFile("Deleted")
    erb:reset
end

#allows admin to overwrite wiki.txt file with wikidefault.txt file to reset the
#contents of the wiki to their default
get '/resettodefault' do
    adminprotected!
    IO.copy_stream('wikidefault.txt', 'wiki.txt')
    erb:resettodefault
end

#shows login view on login page, which allows a user to login or click on create account
get '/login' do
    erb:login
end

#retrieves username and password from the login textboxes in the erb:login view
#checks if the user entered valid credentials by comparing them to the database
post '/login' do
    $credentials = [params[:username],params[:password]]
    @Users = User.where(:username => $credentials[0]).to_a.first
    if @Users
        if @Users.try(:authenticate, $credentials[1]) 
            updateLogFile("Login")
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

#where the user gets redirected to if wrong credentials are entered   
get '/wrongaccount' do
    erb:wrongaccount 
end

#displays username on page and allows to view the profile page after checking
#if a user is logged in
get '/user/:uzer' do
    @Userz = User.where(:username => params[:uzer]).first
    if @Userz != nil
        erb :profile
    else
        redirect '/noaccount'
    end
end

#allows to update edit settings for users in the admin controls
put '/user/:uzer' do
    n = User.where(:username => params[:uzer]).to_a.first
    n.edit = params[:edit] ? 1 : 0
    n.save
    redirect '/'
end

#allows then admin to delete users, unless the username is "Admin"
get '/user/delete/:uzer' do
    adminprotected!
    n = User.where(:username => params[:uzer]).to_a.first
    if n.username == "Admin"
        erb :denied
    else
        n.destroy
        @list2 = User.all.sort_by { |u| [u.id] }
        erb :admincontrols
    end
end

#shows the createaccount view and allows users to create an account
get '/createaccount' do
    erb :createaccount 
end

#allows the admin to add new users
get '/adduser' do
    adminprotected!
    erb:adduser
end

#updates the database with a new users username and password and gives edit rights
#if the username is "Admin"
#checks if the username is unique and returns error message if not
post '/createaccount' do
    n = User.new
    n.username = params[:username]
    n.password = params[:password]
    n_unique = User.where(:username => params[:username]).to_a.first
    if n.username == "Admin" and n.password == "Password"
        n.edit = true
    elsif n_unique
        redirect '/notunique'
    end
    n.save
    redirect '/'
    #if the username already exists, redirect to error message
end

#available to admin only, allows access to various control features
#lists all users of the wiki for the admin to view and edit
get '/admincontrols' do
    adminprotected!
    @list2 = User.all.sort_by { |u| [u.id] }
    erb :admincontrols
end

# source on how to create backup: https://stackoverflow.com/questions/8384869/how-can-i-copy-the-contents-of-one-file-to-another-using-rubys-file-methods
# this does only allow text to be backed up, no pictures
get '/backup' do
    adminprotected!
    updateLogFile("Backup")
    IO.copy_stream("wiki.txt", "backup.txt")
    @backup = readFile("backup.txt")
    erb:backup
end

# opens logile and iterates through it to display the contents in the "log" view
get '/log' do
    adminprotected!
    updateLogFile("Viewlog")
    logfile = []
    file = File.open("log.txt")
    file.each do |line|
        logfile << line
    end
    file.close
    @logfile = logfile
    erb:log
end

#ends user session by setting the credentials to whitespace
get '/logout' do
    updateLogFile("Logout")
    $credentials = ["",""]
    redirect '/'
end

#shows notfound page 
get '/notfound' do
    erb:notfound
end

#error message a user sees if they are not logged in and try to access a user profile
get '/noaccount' do
    erb:noaccount
end

#error message a user sees when they try to register a new user with a username already taken.
get '/notunique' do
    erb:notunique
end

#what non-authenticated users see when trying to accessp protected parts of the site
get '/denied' do
    erb:denied
end

#if the user enters an invalid URL he gets redirected to the /notfound page
not_found do
        status 404
        redirect '/notfound'
end