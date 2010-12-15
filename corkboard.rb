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
# . GET a range
# . tests
# . multi-user with authentication

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/corkboard.sqlite3")

class Note 
  include DataMapper::Resource

  property :id, Serial
  property :subject, Text, :required => true
  property :content, Text, :required => true
  property :created_at, Time
  property :updated_at, Time

  def to_json(*a)
   {
     'subject' => self.subject,
     'content' => self.content,
     'date'    => self.updated_at.to_i
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
get '/notes/:range' do
  puts "**** give me all the notes in the range " +params[:range]
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
  puts "**** get note number #{params[:id]}"
  note = Note.get(params[:id])
  if note.nil? then
    status 404
  else
    status 200
    body(note.to_json) 
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
    puts "**** put a new note @" + note.id.to_s
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
  data = JSON.parse(request.body.string)

  if data.nil? then
    status 400
  else
    puts ""
    note = Note.get(params[:id])
    if note.nil? then
      status 404
    else
      updated = false
      %w(subject content).each do |k|
        if data.has_key?(k)
          note[k] = data[k]
          updated = true
        end

      end
      if updated then
        note['updated_at'] = Time.now
        if !note.save then
          status 500
        else
          
        end
      end
    end
  end
end

# Remove a note entirely
# delete method hack might be required here!
delete '/note/:id' do
  puts "**** delete note number #{params[:id]}"
  note = Note.get(params[:id])
  if note.nil? then
    status 404
  else
    if note.destroy then
      status 200
    else
      status 500
    end
  end
end

