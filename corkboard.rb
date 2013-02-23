require 'rubygems'
require 'sinatra'
require 'json'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'

require 'sinatra/reloader' if development?
require 'debugger' if development?

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

# Download one note, subject and content
# Returns:
# {
#    subject : "the subject",
#    content : "wibble wibble wibble wibble""
# }
#
get '/note/:id' do
  note = Note.get(params[:id])

  status 404 and return if note.nil?

  status 200
  body(note.to_json)
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
  data = JSON.parse(request.body.read)

  status 406 and return if data.nil? || data['subject'].nil? || data['content'].nil?

  note = Note.create(
              :subject => data['subject'],
              :content => data['content'],
              :created_at => Time.now,
              :updated_at => Time.now)

  if note.save
    status 200
    body note.id.to_s
  else
    status 406
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
  data = JSON.parse(request.body.read)
  status 406 and return if data.nil?

  note = Note.get(params[:id])
  status 404 and return if note.nil?

  updated = false
  %w(subject content).each do |key|
    if !data[key].nil? && data[key] != note[key]
      note[key] = data[key]
      note['updated_at'] = Time.now
    end
  end

  if note.save then
    status 200
  else
    status 406
  end
end

# Remove a note entirely
# delete method hack might be required here!
delete '/note/:id' do
  note = Note.get(params[:id])

  status 404 and return if note.nil?

  if note.destroy then
    status 200
  else
    status 500
  end
end

