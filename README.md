# WAD-wiki
This was my first university project and first somewhat completed coding project in general. The work was done in February 2018. It is a wiki website that can be hosted locally following the instructions below.
The work was done in collaboration with https://github.com/Odogwudozilla and was our first website project. it is written in Ruby using Sinatra.
This project was initially hosted on BitBucket, since GitHub did not offer private repos until recently.

# How to run the application:

# Note: the application was developed on Cloud9 on Ruby version 2.4.1, so the developers recommend using Cloud9 to run the application

1.  Extract the contents from the “wiki” zip folder (important: please do not rename or delete any of the contents of this folder)
    install Ruby version 2.4.1 or higher (follow instructions on: https://www.ruby-lang.org/en/downloads/) or use an integrated service       such as Cloud9
2.  Install the following gems (visit http://guides.rubygems.org/rubygems-basics/ on how to install gems):
      bcrypt
      bond
      dm-sqlite-adapter
      haml
      ripl
      ripl-multi_line
      fileutils
      ripl-rack
      rspec
      sinatra
      sinatra/activerecord
      sqlite3
      tux
3.  Open a new terminal in Cloud9 (or a a new Terminal/Powershell/command prompt window) and navigate to the extracted “wiki” folder
    Run the program:
    a. 	On Cloud 9: enter “ruby wiki.rb -p $PORT -o $IP” without the quotes and click on the link that pops up
    b. 	Locally: run “wiki.rb” by typing “ruby wiki.rb” without the quotes into your command line application and open                        http://localhost:4567 in a web browser
