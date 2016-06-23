require 'rice_cooker'
require 'active_record'
require 'spec_helper'

RSpec.describe RiceCooker::Range do
  include RiceCooker::Helpers

  before do
    @collection_class = User
    @allowed_params = rangeable_fields_for(@collection_class)
    @collection = @collection_class.all

    @test_filter = {
      with_the_letter: {proc: -> (value) {where('first_name ILIKE ?', value.map{|e| "%#{e}%"})}},
      without_the_letter: {proc: -> (value) {where.not('first_name ILIKE ?', value.map{|e| "%#{e}%"})}}
    }

    @proc = -> (value) { value }
    @all = -> (value) { [1, 2, 3] }
  end

  describe 'Range params must be okay' do
    it 'Null ranged' do
      # Default null ranged
      ranged_params = parse_ranged_param('', @allowed_params)
      expect(ranged_params).to be_eql({})
    end

    it 'Default ranged' do
      params = ({
        id: '1,5'
      })
      ranged_params = parse_ranged_param(params, @allowed_params)
      expect(ranged_params).to be_eql({id: ['1', '5']})
    end

    it 'Multiple ranged' do
      params = ({
        login: 'aaubin,bobol',
        id: '4,5'
      })
      ranged_params = parse_ranged_param(params, @allowed_params)
      expect(ranged_params).to be_eql({
              login: ['aaubin', 'bobol'],
              id: ['4', '5']
            })
    end

    it 'too many args' do
      # invalid args

      params = ({
        wtf: 'aaubin,qbollach,andre',
        id: '74,75,76'
      })

      expect { parse_ranged_param(params, @allowed_params) }.to raise_error(RiceCooker::InvalidRangeException)
    end

    it 'too few args' do
      # invalid args

      params = ({
        wtf: 'aaubin',
        id: '74'
      })

      expect { parse_ranged_param(params, @allowed_params) }.to raise_error(RiceCooker::InvalidRangeException)
    end
  end

  describe 'Must apply range to given collection' do

    it 'Default null ranged' do
      ranged_collection = apply_range_to_collection(@collection, {})
      # puts ranged_collection.to_sql
      expect(ranged_collection.to_sql).to match(/^((?!WHERE).)*$/)
    end

    it 'Default ranged' do
      ranged_collection = apply_range_to_collection(@collection, {login: ['aaubin', 'qbollach']})
      puts ranged_collection.to_sql
      expect(ranged_collection.to_sql).to match(/BETWEEN/)
      expect(ranged_collection.to_sql).to match(/'aaubin'/)
    end

    it 'Double ranged' do
      # Desc ranged
      ranged_collection = apply_range_to_collection(@collection, {login: ['aaubin', 'qbollach'], id: [1, 2]})
      # puts ranged_collection.to_sql
      expect(ranged_collection.to_sql).to match(/BETWEEN/)
      expect(ranged_collection.to_sql).to match(/'aaubin'/)
    end

    it 'Invalid ranged' do
      # Desc ranged
      expect do
        ranged_collection = apply_range_to_collection(@collection, {
          login: ['aaubin', 'qbollach', 'andre'],
          id: ['74']
        })
      end.to raise_error(RiceCooker::InvalidRangeValueException)
    end
  end

  # describe 'Must apply custom filters to given collection' do



  #   it 'Default null ranged' do
  #     filtered_collection = apply_filter_to_collection(@collection, {}, @test_filter)
  #     # puts filtered_collection.to_sql
  #     expect(filtered_collection.to_sql).to match(/^((?!WHERE).)*$/)
  #   end

  #   it 'Default ranged' do
  #     filtered_collection = apply_filter_to_collection(@collection, {with_the_letter: ['a']}, @test_filter)
  #     # puts filtered_collection.to_sql
  #     expect(filtered_collection.to_sql).to match(/WHERE/)
  #     expect(filtered_collection.to_sql).to match(/ILIKE/)
  #   end

  #   it 'Double ranged' do
  #     # Desc ranged
  #     filtered_collection = apply_filter_to_collection(@collection, {with_the_letter: ['a'], without_the_letter: ['l']}, @test_filter)
  #     # puts filtered_collection.to_sql
  #     expect(filtered_collection.to_sql).to match(/WHERE/)
  #     expect(filtered_collection.to_sql).to match(/first_name ILIKE '%a%'/)
  #     expect(filtered_collection.to_sql).to match(/NOT \(first_name ILIKE '%l%'\)/)
  #   end

  #   it 'Multiple ranged' do
  #     # Desc ranged
  #     filtered_collection = apply_filter_to_collection(@collection, {
  #       login: ['aaubin', 'qbollach', 'andre'],
  #       id: ['74', '75', '76']
  #     })
  #     # puts filtered_collection.to_sql
  #     expect(filtered_collection.to_sql).to match(/WHERE/)
  #     expect(filtered_collection.to_sql).to match(/'login' IN \('aaubin', 'qbollach', 'andre'\)/)
  #     expect(filtered_collection.to_sql).to match(/AND/)
  #   end

  #   it 'invalid args' do
  #     # invalid args
  #     expect do
  #       apply_filter_to_collection(
  #         @collection,
  #         {sorted: ['true', 'baguette']},
  #         format_addtional_ranged_param({sorted: [-> (v) { v }, ['true', 'false', 'maybe']]})
  #       )
  #     end.to raise_error(RiceCooker::InvalidRangeValueException)
  #   end
  # end

  # describe 'Additional params must be correctly formated' do
    

  #   it 'No additional params' do
  #     formated = format_addtional_ranged_param({})
  #     expect(formated).to be_eql({})
  #   end

  #   it 'Already correctly formatted additional params' do
  #     p = {filter: {
  #       proc: @proc,
  #       all: [1, 2, 3],
  #       description: 'A good filter'
  #     }}
  #     formated = format_addtional_ranged_param(p)
  #     expect(formated).to be_eql(p)
  #   end

  #   it 'Missing description additional params' do
  #     p = {filter: {
  #       proc: @proc,
  #       all: [1, 2, 3]
  #     }}
  #     expected = {filter: {
  #       proc: @proc,
  #       all: [1, 2, 3],
  #       description: '
  #     }}
  #     formated = format_addtional_ranged_param(p)
  #     expect(formated).to be_eql(expected)
  #   end


  #   it 'Only proc additional params' do

  #     p = {filter: @proc}
  #     expected = {filter: {
  #       proc: @proc,
  #       all: [],
  #       description: '
  #     }}
  #     formated = format_addtional_ranged_param(p)
  #     expect(formated).to be_eql(expected)
  #   end

  #   it 'Array with proc and all additional params' do

  #     p = {filter: [@proc, @all]}
  #     expected = {filter: {
  #       proc: @proc,
  #       all: @all,
  #       description: '
  #     }}
  #     formated = format_addtional_ranged_param(p)
  #     expect(formated).to be_eql(expected)
  #   end


  #   it 'Multiple, std + Array with proc and all additional params' do

  #     p = {
  #       tata: @proc,
  #       toto: {proc: @proc, all: [1, 2]},
  #       filter: [@proc, @all],
  #       tutu: {proc: @proc, description: 'Buuuuh'}
  #     }
  #     expected = {
  #       tata: {
  #         proc: @proc,
  #         all: [],
  #         description: '
  #       },
  #       toto: {
  #         proc: @proc,
  #         all: [1, 2],
  #         description: '
  #       },
  #       filter: {
  #         proc: @proc,
  #         all: @all,
  #         description: '
  #       },
  #       tutu: {
  #         proc: @proc,
  #         all: [],
  #         description: 'Buuuuh'
  #       }
  #     }
  #     formated = format_addtional_ranged_param(p)
  #     expect(formated).to be_eql(expected)
  #   end


  # end


end




RSpec.describe UsersController, type: :controller do
  
  include RiceCooker::Helpers

  before { request.host = 'example.org' }

  describe 'GET #index' do

    it 'without range parameter' do
      get :index, range: '', format: :json
      expect(response.body).to eq(User.all.order(id: :desc).to_json)
    end

    it 'with simple range parameter' do
      get :index, range: {login: 'aaubin,qbollach'}, format: :json
      expect(response.body).to eq(User.where(login: 'aaubin'..'qbollach').order(id: :desc).to_json)
    end

    it 'with multiple range parameter' do
      get :index, range: {login: 'aaubin,qbollach', id: '1,5'}, format: :json
      expect(response.body).to eq(User.where(login: 'aaubin'..'qbollach', id: 1..5).order(id: :desc).to_json)
    end
  end

end