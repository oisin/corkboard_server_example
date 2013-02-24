ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'sinatra'
require 'test/unit'
require 'rack/test'
require 'base64'
require 'json'
require 'timecop'
require './corkboard'

class ApplicationTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def make_a_note(note)
    put '/note', note.to_json
    assert_equal 201, last_response.status

    note = JSON.parse(last_response.body)
    refute_nil note['id']
    assert_equal Fixnum, note['id'].class
    return note['id'].to_s
  end

  def retrieve_note(note_id)
    get '/note/' + note_id
    assert_equal 200, last_response.status

    returned_note = JSON.parse(last_response.body)
    refute_nil returned_note
    returned_note
  end

  def test_add_and_retrieve_note
    # Create a new note, then retrieve it and
    # assert that we get the same stuff back!

    note = {
        "subject" => "Don't forget",
        "content" => "Test add and retrieve note!"
    }

    note_id = make_a_note(note)

    # Retrieve the note we just created
    returned_note = retrieve_note(note_id)

    # Check we got the same note back!
    note.each_key do |k|
      refute_nil returned_note[k]
      assert_equal note[k], returned_note[k]
    end
  end

  def test_add_and_remove_note
    note = {
        "subject" => "Don't forget",
        "content" => "Test and remove note!"
    }

    # Make a new note and then delete it
    note_id = make_a_note(note)
    delete '/note/' + note_id
    assert_equal 204, last_response.status

    # Make sure that the note is gone!
    get '/note/' + note_id
    assert_equal 404, last_response.status
  end

  def test_add_and_update_note_subject
    note = {
        "subject" => "Don't forget",
        "content" => "Test add and update note subject!"
    }

    note_id = make_a_note(note)

    Timecop.freeze(Date.today + 30) do
      # Update the subject of the note
      note_update_subject = {
          "subject" => "Remember!"
      }

      test_time = DateTime.now

      post '/note/' + note_id, note_update_subject.to_json
      assert_equal 200, last_response.status

      returned_note = retrieve_note(note_id)

      assert_equal returned_note['content'], note['content']
      assert_equal returned_note['subject'], note_update_subject['subject']

      assert returned_note['date'] >= test_time.inspect, "Note time not updated"

      # Update the content of the note
      note_update_content = {
          "content" => "Test add and update note content!"
      }

      test_time = DateTime.now

      post '/note/' + note_id, note_update_content.to_json
      assert_equal 200, last_response.status

      returned_note = retrieve_note(note_id)

      assert_equal returned_note['content'], note_update_content['content']
      assert_equal returned_note['subject'], note_update_subject['subject']

      assert returned_note['date'] >= test_time.inspect, "Note time not updated"

      # Update both subject and content of the note
      test_time = DateTime.now

      post '/note/' + note_id, note.to_json
      assert_equal 200, last_response.status

      returned_note = retrieve_note(note_id)

      assert_equal returned_note['content'], note['content']
      assert_equal returned_note['subject'], note['subject']

      assert returned_note['date'] >= test_time.inspect, "Note time not updated"
    end
  end

  # def test_get_notes_range
  #   puts "****TODO: test_get_notes_range "
  # end

  # def test_reject_bad_media_type
  #   puts "****TODO: test_reject_bad_media_type"
  # end

  def test_get_non_existent_note
    get '/note/BLOOTYWOOTY'  # always an integer id...
    assert_equal 404, last_response.status
  end

  def test_update_non_existent_note
    note = {
        "subject" => "Don't forget",
        "content" => "Test update non-existent note!"
    }

    post '/note/BLOOTYWOOTY', note.to_json
    assert_equal 404, last_response.status
  end

  def test_delete_non_existent_note
    delete '/note/BLOOTYWOOTY'
    assert_equal 404, last_response.status
  end
end
