# Rice Cooker

[![Build Status](https://travis-ci.org/lambda2/rice_cooker.svg?branch=master)](https://travis-ci.org/lambda2/rice_cooker)

Handle sort, filters, searches, and ranges on Rails collections.

-------------------

## Installation

In your `Gemfile`:

```ruby
gem 'has_scope'
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

### Sorting

The `sort` parameter allow sorting on one or several, comma-separated, fields. The sort is applied in the order specified.
The sort order for each sort field is ascending unless it is prefixed with a minus (-), in which case it is descending.

For example, the `api.example.org/unicorns?sort=color,-name` url will return all the unicorns order by **color** in the ascending order, and if they have the same color, by **name**, on the descending order.

### Filtering

The `filter` parameter is a hash allowing filtering for a field, as a key, on one or several, comma-separated, values. Only the fields matching the given filter(s) will be returned.

For example, the `api.example.org/unicorns?filter[color]=yellow&filter[age]=21,22` url will return all the **yellow** unicorns which are **21** OR **22** years old.

### Ranging

The `range` parameter is a hash allowing filtering for a field, as a key, on two comma-separated bounds. Only the fields between the given bounds will be returned. The bounds are inclusives.

For example, the `api.example.org/unicorns?range[age]=21,42` url will return all the unicorns which are between **21** and **42** years old.

### Searching

The `search` parameter is a hash allowing searching for a field, as a key, on one or several, comma-separated, values. Only the fields containing the given search(es) will be returned (internally, safely executes a `WHERE field LIKE '%SEARCH%'` query).

For example, the `api.example.org/unicorns?search[color]=e` url will return all the unicorns with a color containing the letter '**e**'.


## Specification

The gem try to follow the [RAPIS](https://github.com/lambda2/rapis) api convention.
