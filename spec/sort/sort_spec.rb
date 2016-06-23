require "pry"
require 'rice_cooker'
require 'active_record'
require 'spec_helper'

# include Sort

RSpec.describe RiceCooker::Sort do

  include RiceCooker::Helpers

  before do
    @collection_class = User
    @collection = @collection_class.all
  end

  describe "Sort params must be okay" do

    it "Default null sorting" do

      # Default null sorting
      sorting_params = parse_sorting_param("", @collection_class)
      expect(sorting_params).to be_eql({})
    end

    it "Default asc sorting" do
      # Default asc sorting
      sorting_params = parse_sorting_param("id", @collection_class)
      expect(sorting_params).to be_eql({:id => :asc})
    end

    it "Desc sorting" do
      # Desc sorting
      sorting_params = parse_sorting_param("-id", @collection_class)
      expect(sorting_params).to be_eql({:id => :desc})
    end

    it "Same param sorting" do
      sorting_params = parse_sorting_param("-id,id", @collection_class)
      expect(sorting_params).to be_eql({:id => :asc})
    end

    it "Multiple args" do
      # Multiple args
      sorting_params = parse_sorting_param("-login,id", @collection_class)
      expect(sorting_params).to be_eql({:login => :desc, :id => :asc})
    end

    it "invalid args" do
      # invalid args
      expect { parse_sorting_param("-turututu,id", @collection_class) }.to raise_error(RiceCooker::InvalidSortException)
    end
  end

  describe "Must apply sort to given collection" do


    it "Default null sorting" do
      # Default null sorting
      sorted_collection = apply_sort_to_collection(@collection, {})
      puts sorted_collection.to_sql
      expect(sorted_collection.to_sql).to match(/^((?!ORDER).)*$/)
    end

    it "Default asc sorting" do
      # Default asc sorting
      sorted_collection = apply_sort_to_collection(@collection, {:id => :asc})
      puts sorted_collection.to_sql
      expect(sorted_collection.to_sql).to match(/ORDER/)
      expect(sorted_collection.to_sql).to match(/"id" ASC/)
    end

    it "Desc sorting" do
      # Desc sorting
      sorted_collection = apply_sort_to_collection(@collection, {:id => :desc})
      puts sorted_collection.to_sql
      expect(sorted_collection.to_sql).to match(/ORDER/)
      expect(sorted_collection.to_sql).to match(/"id" DESC/)
    end

    it "Same param sorting" do
      # Desc sorting
      sorted_collection = apply_sort_to_collection(@collection, {:id => :asc})
      puts sorted_collection.to_sql
      expect(sorted_collection.to_sql).to match(/ORDER/)
      expect(sorted_collection.to_sql).to match(/^((?!DESC).)*$/)
      expect(sorted_collection.to_sql).to match(/"id" ASC/)
    end

    it "Multiple args" do
      # Multiple args
      sorted_collection = apply_sort_to_collection(@collection, {:login => :desc, :id => :asc})
      puts sorted_collection.to_sql
      expect(sorted_collection.to_sql).to match(/ORDER/)
      expect(sorted_collection.to_sql).to match(/"login" DESC/)
      expect(sorted_collection.to_sql).to match(/"id" ASC/)
    end

  end
end


RSpec.describe UsersController, :type => :controller do
  
  include RiceCooker::Helpers

  before { request.host = 'example.org' }

  describe 'GET #index' do

    it 'without sort parameter' do
      get :index, :sort => '', format: :json
      expect(response.body).to eq(User.all.to_json)
    end

    it 'with simple sort parameter' do
      get :index, :sort => 'login', format: :json
      expect(response.body).to eq(User.all.order(:login).to_json)
    end

    it 'with double sort parameter' do
      get :index, :sort => 'login,id', format: :json
      expect(response.body).to eq(User.all.order(:login, :id).to_json)
    end

    it 'with double and reverse sort parameter' do
      get :index, :sort => 'login,-id', format: :json
      expect(response.body).to eq(User.all.order(:login, :id => :desc).to_json)
    end
  end

end