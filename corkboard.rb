require 'rubygems'
require 'sinatra'
require 'json'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'

# TODO:
# . logging
# . media types testing
# . test mode and development mode
# . put the database somewhere else
# . tests 

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/corkboard.sqlite3")

class Note 
  include DataMapper::Resource

  property :id, Serial
  property :subject, Text, :required => true
  property :content, Text, :required => true
  property :created_at, DateTime
  property :updated_at, DateTime

  def to_json(*a)
   { 
     'subject' => self.subject, 
     'content' => self.content,
     'date'    => self.updated_at
   }.to_json(*a)
  end
end

DataMapper.finalize
Note.auto_upgrade!

# Download subjects and ids of my notes
# Returns:
# { 
#    1 : "the subject",
#    2 : "the other subject"
# }
#
get '/notes' do
  puts "**** give me all the notes there "
  501
end

# Download one note, subject and content
# Returns:
# { 
#    subject : "the subject",
#    content : "wibble wibble wibble wibble""
# }
#
get '/note/:id' do
  note = Note.find(params[:id])
  if note.nil? then
    status 404
  else
    status 200
    body(note.first.to_json)  # Notice the first here!
  end
end

# Add a note to the server, subject and content
# will give you back an id
# Body
# { 
#    subject : "the subject",
#    content : "wibble wibble wibble wibble""
# }
#
# Returns 
#  2
put '/note' do
  puts "**** adding a note "
  data = JSON.parse(request.body.string)
  if data.nil? or !data.has_key?('subject') or !data.has_key?('content') then
    status 400
  else
    note = Note.create( 
                :subject => data['subject'], 
                :content => data['content'],
                :created_at => Time.now,
                :updated_at => Time.now
           )
    note.save
    status 200
    body(note.id.to_s)
  end
end

# Update the content of a note, replace subject
# or content
# Body
# { 
#    subject : "the subject",
#    content : "wibble wibble wibble wibble""
# }
# Subject and content are optional!
post '/note/:id' do
  puts "**** update note number #{params[:id]}"
  status 501
end

# Remove a note entirely
# delete method hack might be required here!
delete '/note/:id' do
  puts "**** delete note number #{params[:id]}"
  status 501
end
