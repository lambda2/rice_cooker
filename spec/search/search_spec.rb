require 'pry'
require 'rice_cooker'
require 'active_record'
require 'spec_helper'

RSpec.describe RiceCooker::Search do
  include RiceCooker::Helpers

  # class User < ActiveRecord::Base; end

  before do
    @collection_class = User
    @allowed_params = searchable_fields_for(@collection_class)
    @collection = @collection_class.all

    @test_search = {
      with_the_letter: { proc: -> (value) { where('first_name ILIKE ?', value.map { |e| "%#{e}%" }) } },
      without_the_letter: { proc: -> (value) { where.not('first_name ILIKE ?', value.map { |e| "%#{e}%" }) } }
    }

    @proc = -> (value) { value }
    @all = -> (_value) { [1, 2, 3] }
  end

  describe 'Search params must be okay' do
    it 'Null searching' do
      # Default null searching
      searching_params = parse_searching_param('', @allowed_params)
      expect(searching_params).to be_eql({})
    end

    it 'Default searching' do
      params = {
        login: 'aaubin'
      }

      searching_params = parse_searching_param(params, @allowed_params)
      expect(searching_params).to be_eql(login: ['aaubin'])
    end

    it 'Double searching' do
      params = {
        login: 'aaubin,qbollach'
      }

      searching_params = parse_searching_param(params, @allowed_params)
      expect(searching_params).to be_eql(login: %w(aaubin qbollach))
    end

    it 'Multiple searching' do
      params = {
        login: 'aaubin,qbollach,andre',
        id: '74,75,76'
      }

      searching_params = parse_searching_param(params, @allowed_params)
      expect(searching_params).to be_eql(login: %w(aaubin qbollach andre),
                                         id: %w(74 75 76))
    end

    it 'invalid args' do
      # invalid args

      params = {
        wtf: 'aaubin,qbollach,andre',
        id: '74,75,76'
      }

      expect { parse_searching_param(params, @allowed_params) }.to raise_error(RiceCooker::InvalidSearchException)
    end
  end

  describe 'Must apply search to given collection' do
    it 'Default null searching' do
      searched_collection = apply_search_to_collection(@collection, {})
      # puts searched_collection.to_sql
      expect(searched_collection.to_sql).to match(/^((?!WHERE).)*$/)
    end

    it 'Default searching' do
      searched_collection = apply_search_to_collection(@collection, login: ['aaubin'])
      # puts searched_collection.to_sql
      expect(searched_collection.to_sql).to match(/WHERE/)
      expect(searched_collection.to_sql).to match(/\"login\" LIKE '%aaubin%'/)
    end

    it 'Double searching' do
      # Desc searching
      searched_collection = apply_search_to_collection(@collection, login: %w(aaubin qbollach))
      # puts searched_collection.to_sql
      expect(searched_collection.to_sql).to match(/WHERE/)
      expect(searched_collection.to_sql).to match(/\"login\" LIKE '%aaubin%'/)
      expect(searched_collection.to_sql).to match(/\"login\" LIKE '%qbollach%'/)
    end

    it 'Multiple searching' do
      # Desc searching
      searched_collection = apply_search_to_collection(@collection, login: %w(aaubin qbollach andre),
                                                                    id: %w('74' '75' '76'))
      # puts searched_collection.to_sql
      expect(searched_collection.to_sql).to match(/\"login\" LIKE '%aaubin%'/)
      expect(searched_collection.to_sql).to match(/\"login\" LIKE '%qbollach%'/)
      expect(searched_collection.to_sql).to match(/\) AND \(/)
      # puts searched_collection.to_sql
      expect(searched_collection.to_sql).to match(/\"id\" LIKE 0/)
      expect(searched_collection.to_sql).to match(/\"id\" LIKE 0/)
      expect(searched_collection.to_sql).to match(/\) AND \(/)
    end
  end

  describe 'Must apply custom searchs to given collection' do
    it 'Default null searching' do
      searched_collection = apply_search_to_collection(@collection, {}, @test_search)
      # puts searched_collection.to_sql
      expect(searched_collection.to_sql).to match(/^((?!WHERE).)*$/)
    end

    it 'Default searching' do
      searched_collection = apply_search_to_collection(@collection, { with_the_letter: ['a'] }, @test_search)
      # puts searched_collection.to_sql
      expect(searched_collection.to_sql).to match(/WHERE/)
      expect(searched_collection.to_sql).to match(/ILIKE/)
    end

    it 'Double searching' do
      # Desc searching
      searched_collection = apply_search_to_collection(@collection, { with_the_letter: ['a'], without_the_letter: ['l'] }, @test_search)
      # puts searched_collection.to_sql
      expect(searched_collection.to_sql).to match(/WHERE/)
      expect(searched_collection.to_sql).to match(/first_name ILIKE '%a%'/)
      expect(searched_collection.to_sql).to match(/NOT \(first_name ILIKE '%l%'\)/)
    end

    # it 'invalid args' do
    #   # invalid args
    #   expect do
    #     apply_search_to_collection(
    #       @collection,
    #       { sorted: %w(true baguette) },
    #       format_additional_param(sorted: [-> (v) { v }, %w(true false maybe)])
    #     )
    #   end.to raise_error(RiceCooker::InvalidSearchValueException)
    # end
  end

  describe 'Additional params must be correctly formated' do
    it 'No additional params' do
      formated = format_additional_param({})
      expect(formated).to be_eql({})
    end

    it 'Already correctly formatted additional params' do
      p = { search: {
        proc: @proc,
        all: [1, 2, 3],
        description: 'A good search'
      } }
      formated = format_additional_param(p)
      expect(formated).to be_eql(p)
    end

    it 'Missing description additional params' do
      p = { search: {
        proc: @proc,
        all: [1, 2, 3]
      } }
      expected = { search: {
        proc: @proc,
        all: [1, 2, 3],
        description: ''
      } }
      formated = format_additional_param(p)
      expect(formated).to be_eql(expected)
    end

    it 'Only proc additional params' do
      p = { search: @proc }
      expected = { search: {
        proc: @proc,
        all: [],
        description: ''
      } }
      formated = format_additional_param(p)
      expect(formated).to be_eql(expected)
    end

    it 'Array with proc and all additional params' do
      p = { search: [@proc, @all] }
      expected = { search: {
        proc: @proc,
        all: @all,
        description: ''
      } }
      formated = format_additional_param(p)
      expect(formated).to be_eql(expected)
    end

    it 'Multiple, std + Array with proc and all additional params' do
      p = {
        tata: @proc,
        toto: { proc: @proc, all: [1, 2] },
        search: [@proc, @all],
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
        search: {
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
      formated = format_additional_param(p)
      expect(formated).to be_eql(expected)
    end
  end
end

RSpec.describe UsersController, type: :controller do
  include RiceCooker::Helpers

  before { request.host = 'example.org' }

  describe 'GET #index' do
    it 'without search parameter' do
      process :index, method: :get, params: { search: '', format: :json }
      expect(response.body).to eq(User.all.order(id: :desc).to_json)
    end

    it 'with simple search parameter' do
      process :index, method: :get, params: { search: { login: 'a' }, format: :json }
      expect(response.body).to eq(User.where(User.arel_table[:login].matches("%a%")).order(id: :desc).to_json)
    end

    it 'with double search parameter' do
      process :index, method: :get, params: { search: { login: 'a,q' }, format: :json }
      expect(response.body).to eq(User.where(
        User.arel_table[:login].matches("%a%").or(User.arel_table[:login].matches("%q%"))
      ).order(id: :desc).to_json)
    end

    it 'with double and multiple search parameter' do
      process :index, method: :get, params: { search: { login: 'a,q', email: 't' }, format: :json }
      expect(response.body).to eq(
        User.where(
          User.arel_table[:login].matches("%a%").or(User.arel_table[:login].matches("%q%"))
        ).where(
          User.arel_table[:email].matches("%t%")
        ).order(id: :desc).to_json
      )
    end
  end
end
