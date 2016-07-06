require 'rice_cooker'
require 'active_record'
require 'spec_helper'

RSpec.describe RiceCooker::Range do
  include RiceCooker::Helpers

  before do
    @collection_class = User
    @allowed_params = rangeable_fields_for(@collection_class)
    @collection = @collection_class.all

    @test_range = {
      between_the_letter: { proc: -> (start_field, end_field) { where('first_name BETWEEN ? AND ?', start_field, end_field) } },
      not_between_the_letter: { proc: -> (start_field, end_field) { where('first_name NOT BETWEEN ? AND ?', start_field, end_field) } }
    }

    @proc = -> (value) { value }
    @all = -> (_value) { [1, 2, 3] }
  end

  describe 'Range params must be okay' do
    it 'Null ranged' do
      # Default null ranged
      ranged_params = parse_ranged_param('', @allowed_params)
      expect(ranged_params).to be_eql({})
    end

    it 'Default ranged' do
      params = {
        id: '1,5'
      }
      ranged_params = parse_ranged_param(params, @allowed_params)
      expect(ranged_params).to be_eql(id: %w(1 5))
    end

    it 'Multiple ranged' do
      params = {
        login: 'aaubin,bobol',
        id: '4,5'
      }
      ranged_params = parse_ranged_param(params, @allowed_params)
      expect(ranged_params).to be_eql(login: %w(aaubin bobol),
                                      id: %w(4 5))
    end

    it 'too many args' do
      # invalid args

      params = {
        wtf: 'aaubin,qbollach,andre',
        id: '74,75,76'
      }

      expect { parse_ranged_param(params, @allowed_params) }.to raise_error(RiceCooker::InvalidRangeException)
    end

    it 'too few args' do
      # invalid args

      params = {
        wtf: 'aaubin',
        id: '74'
      }

      expect { parse_ranged_param(params, @allowed_params) }.to raise_error(RiceCooker::InvalidRangeException)
    end
  end

  describe 'Must apply range to given collection' do
    it 'Default null ranged' do
      ranged_collection = apply_range_to_collection(@collection, {})
      expect(ranged_collection.to_sql).to match(/^((?!WHERE).)*$/)
    end

    it 'Default ranged' do
      ranged_collection = apply_range_to_collection(@collection, login: %w(aaubin qbollach))
      expect(ranged_collection.to_sql).to match(/BETWEEN/)
      expect(ranged_collection.to_sql).to match(/'aaubin'/)
    end

    it 'Double ranged' do
      # Desc ranged
      ranged_collection = apply_range_to_collection(@collection, login: %w(aaubin qbollach), id: [1, 2])
      expect(ranged_collection.to_sql).to match(/BETWEEN/)
      expect(ranged_collection.to_sql).to match(/'aaubin'/)
    end

    it 'Invalid ranged' do
      # Desc ranged
      expect do
        apply_range_to_collection(@collection, login: %w(aaubin qbollach andre),
                                               id: ['74'])
      end.to raise_error(RiceCooker::InvalidRangeValueException)
    end
  end

  describe 'Must apply custom ranges to given collection' do
    it 'Default null ranged' do
      ranged_collection = apply_range_to_collection(@collection, {}, @test_range)
      expect(ranged_collection.to_sql).to match(/^((?!WHERE).)*$/)
    end

    it 'Default ranged' do
      ranged_collection = apply_range_to_collection(@collection, { between_the_letter: %w(a b) }, @test_range)
      expect(ranged_collection.to_sql).to match(/WHERE/)
      expect(ranged_collection.to_sql).to match(/BETWEEN/)
    end

    it 'Double ranged' do
      # Desc ranged
      ranged_collection = apply_range_to_collection(@collection, {
                                                      between_the_letter: %w(a b),
                                                      not_between_the_letter: %w(x z)
                                                    }, @test_range)
      expect(ranged_collection.to_sql).to match(/WHERE/)
      expect(ranged_collection.to_sql).to match(/first_name BETWEEN 'a' AND 'b'/)
      expect(ranged_collection.to_sql).to match(/AND \(first_name NOT BETWEEN 'x' AND 'z'\)/)
    end

    it 'Multiple ranged' do
      # Desc ranged
      ranged_collection = apply_range_to_collection(@collection, login: %w(aaubin qbollach),
                                                                 id: %w(74 76))
      expect(ranged_collection.to_sql).to match(/WHERE/)
      expect(ranged_collection.to_sql).to match(/BETWEEN 'aaubin' AND 'qbollach'/)
      expect(ranged_collection.to_sql).to match(/\) AND \(/)
      expect(ranged_collection.to_sql).to match(/BETWEEN 74 AND 76/)
    end

    it 'invalid args' do
      # invalid args
      expect do
        apply_range_to_collection(
          @collection,
          { sorted: %w(true baguette) },
          format_additional_param({ sorted: [-> (v, _w) { v }, %w(true false maybe)] }, 'ranged')
        )
      end.to raise_error(RiceCooker::InvalidRangeValueException)
    end
  end

  describe 'Additional params must be correctly formated' do
    it 'No additional params' do
      formated = format_additional_param({}, 'ranged')
      expect(formated).to be_eql({})
    end

    it 'Already correctly formatted additional params' do
      p = { range: {
        proc: @proc,
        all: [1, 2, 3],
        description: 'A good filter'
      } }
      formated = format_additional_param(p, 'ranged')
      expect(formated).to be_eql(p)
    end

    it 'Missing description additional params' do
      p = { filter: {
        proc: @proc,
        all: [1, 2, 3]
      } }
      expected = { filter: {
        proc: @proc,
        all: [1, 2, 3],
        description: ''
      } }
      formated = format_additional_param(p, 'ranged')
      expect(formated).to be_eql(expected)
    end

    it 'Only proc additional params' do
      p = { filter: @proc }
      expected = { filter: {
        proc: @proc,
        all: [],
        description: ''
      } }
      formated = format_additional_param(p, 'ranged')
      expect(formated).to be_eql(expected)
    end

    it 'Array with proc and all additional params' do
      p = { filter: [@proc, @all] }
      expected = { filter: {
        proc: @proc,
        all: @all,
        description: ''
      } }
      formated = format_additional_param(p, 'ranged')
      expect(formated).to be_eql(expected)
    end

    it 'Multiple, std + Array with proc and all additional params' do
      p = {
        tata: @proc,
        toto: { proc: @proc, all: [1, 2] },
        filter: [@proc, @all],
        tutu: { proc: @proc, description: 'Buuuuh' }
      }
      expected = {
        tata: {
          proc: @proc,
          all: [],
          description: ''
        },
        toto: {
          proc: @proc,
          all: [1, 2],
          description: ''
        },
        filter: {
          proc: @proc,
          all: @all,
          description: ''
        },
        tutu: {
          proc: @proc,
          all: [],
          description: 'Buuuuh'
        }
      }
      formated = format_additional_param(p, 'ranged')
      expect(formated).to be_eql(expected)
    end
  end
end

RSpec.describe UsersController, type: :controller do
  include RiceCooker::Helpers

  before { request.host = 'example.org' }

  describe 'GET #index' do
    it 'without range parameter' do
      process :index, method: :get, params: { range: '', format: :json }
      expect(response.body).to eq(User.all.order(id: :desc).to_json)
    end

    it 'with simple range parameter' do
      process :index, method: :get, params: { range: { login: 'aaubin,qbollach' }, format: :json }
      expect(response.body).to eq(User.where(login: 'aaubin'..'qbollach').order(id: :desc).to_json)
    end

    it 'with multiple range parameter' do
      process :index, method: :get, params: { range: { login: 'aaubin,qbollach', id: '1,5' }, format: :json }
      expect(response.body).to eq(User.where(login: 'aaubin'..'qbollach', id: 1..5).order(id: :desc).to_json)
    end

    it 'with invalid range parameter' do
      expect do
        process :index, method: :get, params: { range: { created_at: '2016-02-04,qbollach', login: '^,&' }, format: :json }
      end.to raise_error(RiceCooker::InvalidRangeException)
    end
  end
end
