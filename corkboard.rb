require 'rubygems'
require 'sinatra'
require 'json'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'

if development?
  require 'sinatra/reloader'
  require 'debugger'
  Debugger.settings[:autoeval] = true
  Debugger.settings[:autolist] = 1
  Debugger.settings[:reload_source_on_change] = true
end

# TODO:
# . logging
# . media types testing
# . test mode and development mode
# . put the database somewhere else
# . GET a range
# . multi-user with authentication

DataMapper.setup(:default, "sqlite3://#{File.dirname(__FILE__)}/corkboard.sqlite3")

class Note
  include DataMapper::Resource

  Note.property(:id, Serial)
  Note.property(:subject, Text, :required => true)
  Note.property(:content, Text, :required => true)
  Note.property(:created_at, DateTime)
  Note.property(:updated_at, DateTime)

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

  if note.nil?
    return [404, {'Content-Type' => 'application/json'}, ['']]
  end

  return [200, {'Content-Type' => 'application/json'}, [note.to_json]]
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

  if data.nil? || data['subject'].nil? || data['content'].nil?
    return [406, {'Content-Type' => 'application/json'}, ['']]
  end

  note = Note.create(
              :subject => data['subject'],
              :content => data['content'],
              :created_at => Time.now,
              :updated_at => Time.now)

  if note.save
    return [200, {'Content-Type' => 'application/json', 'Location' => "/note/#{note.id}"}, [note.id.to_s]]
  else
    return [406, {'Content-Type' => 'application/json'}, ['']]
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
  if data.nil?
    return [406, {'Content-Type' => 'application/json'}, ['']]
  end

  note = Note.get(params[:id])
  if note.nil?
    return [404, {'Content-Type' => 'application/json'}, ['']]
  end

  updated = false
  %w(subject content).each do |key|
    if !data[key].nil? && data[key] != note[key]
      note[key] = data[key]
      note['updated_at'] = Time.now
    end
  end

  if note.save then
    return [200, {'Content-Type' => 'application/json'}, ['']]
  else
    return [406, {'Content-Type' => 'application/json'}, ['']]
  end
end

# Remove a note entirely
# delete method hack might be required here!
delete '/note/:id' do
  note = Note.get(params[:id])
  if note.nil?
    return [404, {'Content-Type' => 'application/json'}, ['']]
  end

  if note.destroy then
    return [200, {'Content-Type' => 'application/json'}, ['']]
  else
    return [500, {'Content-Type' => 'application/json'}, ['']]
  end
end

