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

  def test_add_and_retrieve_note
    # Create a new note, then retrieve it and
    # assert that we get the same stuff back!

    note = { 
        "subject" => "Don't forget", 
        "content" => "Well, do not forget dude" 
    }
    put '/note', note.to_json
    assert_equal 200, last_response.status
 
    note_id = last_response.body
    assert_not_nil note_id
    assert_match /\d+/, note_id

    # Retrieve the note we just created
    get '/note/' + note_id
    assert_equal 200, last_response.status

    returned_note = JSON.parse(last_response.body)
    assert_not_nil returned_note

    # Check we got the same note back!
    note.each_key do |k|
      assert_not_nil returned_note[k]
      assert_equal note[k], returned_note[k]
    end
  end

  def test_add_and_remove_note
  end

  def test_add_and_update_note
  end

  def test_get_non_existent_note
  end

  def test_update_non_existent_note
  end

  def test_delete_non_existent_note
  end

  def test_reject_bad_media_type
  end

end
