require 'rubygems'
require 'sinatra'
require '../corkboard'
require 'test/unit'
require 'rack/test'
require 'base64'
require 'json'

class ApplicationTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_add_note
    note = { :subject => "Don't forget", :content => "Well, do not forget dude" }
    put '/note', note.to_json
    assert_equal 200, last_response.status
 
    note_id = last_response.body
    assert_not_nil note_id
    assert_match /\d+/, note_id
    # Check the note got there 
    
    get '/note/#{note_id}'
    assert_equal 200, last_response.status

    returned_note = JSON.parse(last_response.data.string)
    assert_not_nil returned_note

    note.each_key do |k|
      assert_not_nil returned_note[k]
      assert_equal note[k], returned_note[k]
    end
  end
end
