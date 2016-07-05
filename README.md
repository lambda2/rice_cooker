# Rice Cooker

[![Build Status](https://travis-ci.com/lambda2/rice_cooker.svg?token=zsj9q6JjpQd8brNcmt9S&branch=master)](https://travis-ci.com/lambda2/rice_cooker)

Handle sort, filters, searches, and ranges on Rails collections.

-------------------

## Installation

In your `Gemfile`:

```ruby
gem 'rice_cooker'
```

Then, in your controllers

```ruby

class UsersController < ActionController::Base

  # Will handle sorting with the 'sort' parameter.
  sorted

  # Will handle filtering with the 'filter[]' parameter.
  filtered

  # Will handle range-ing with the 'range[]' parameter.
  ranged

  def index
    @users = apply_scopes(User).all
    render json: @users
  end
end

```