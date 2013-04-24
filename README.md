# Syphon

Syphon helps you build discoverable JSON apis on top of Rails applications and intuitive clients to consume them.

## Installation

Add this line to your application's Gemfile:

    gem 'syphon'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install syphon

## Usage

### Service

To define a syphon service, simply add a ruby class to a location of your choice
(make sure the class can be autoloaded), define your api, and generate the
routes.

For example. Let's say we want to place our api definition in */app/api/v1.rb*

```bash
├── twitter_clone
│   ├── api
│   │   ├── v1.rb
│   ├── models
│   ├── controllers 
```

*v1.rb* would look like this. See the [DSL](#dsl) section for specifics.

```ruby
class Api::V1 < Syphon::Api
  ...
end
```

Now that the api is defined, you must explicitly generate the routes in your
*routes.rb* file.

```ruby
# Draws routes for all the api defined resources
#
Api::V1.draw_routes!

# Draws a route for automatic api discovery (used by Syphon::Client)
#
Api::V1.draw_discovery_route!('/api/v1')
```

#### <a id='dsl'></a> The DSL

An api definition for our Twitter Clone App might look something like this.

```ruby
class Api::V1
  api do
    resource :users do
      scope       { |a| a.where(user_id: current_user.id) }

      routes      :show   => ['/account', :via => :get],
                  :update => ['/account', :via => :put] 

      fields      :id, :username, :email, :name, :location, :website, :bio
      renames     :full_name => :name

      collections :tweets, :favorites, :followers, :followings
    end

    resource :followers, :extends => :users do
      routes      :index, :show, :destroy
      resources   :user
    end

    resource :followings, :extends => :followers

    resource :tweets, :except => :update do
      
      fields      :id, :body, :retweets, :created_at
      renames     :created_at => :tweeted_at

      resources   :user
      collections :retweets, :replies
    end

    resource :retweets, :extends => :tweets
    resource :replies,  :extends => :tweets

  end
end
```

### Client

## FAQ

* Can syphon be used without Rails?

  * No. It makes use of ActionController for building routes among other things.
    I might look into making it only Rack dependent in the future.


### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
