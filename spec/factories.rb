require 'ostruct'

class TestModel < OpenStruct
  def to_h
    @table
  end
end

module SyphonTest
  PERSON = TestModel.new(
     id: 123456789012345,
     first: 'Anon', 
     middle: 'O',
     last: 'User',
     age: 21,
     created_at: '2013-04-11 13:13:50 -0500',
     update_at: '2013-04-11 13:13:50 -0500')

  POST = TestModel.new( 
     id: 10,
     title: 'A Blog Post ', 
     body: 'This is a blog post.', 
     created_at: '2013-04-11 13:13:50 -0500',
     update_at: '2013-04-11 13:13:50 -0500')

  USER = TestModel.new( 
     id: 20,
     email: 'user@email.com', 
     password: 'afD1J2JjfhaIhflFJ', 
     login_count: 10,
     person: PERSON,
     posts: Array[POST],
     created_at: '2013-04-11 13:13:50 -0500',
     update_at: '2013-04-11 13:13:50 -0500')

  COMMENT = TestModel.new(
    id: 100,
    body: 'this post is 4w3s0m3!',
    user: USER,
    people: [PERSON] )
end
