require "pry"
require 'rice_cooker'
require 'active_record'
require 'spec_helper'

RSpec.describe RiceCooker::Filter do

  include RiceCooker::Helpers

  # class User < ActiveRecord::Base; end

  before do
    @collection_class = User
    @allowed_params = filterable_fields_for(@collection_class)
    @collection = @collection_class.all

    @test_filter = {
      with_the_letter: {proc: -> (value) {where('first_name ILIKE ?', value.map{|e| "%#{e}%"})}},
      without_the_letter: {proc: -> (value) {where.not('first_name ILIKE ?', value.map{|e| "%#{e}%"})}}
    }

    @proc = -> (value) { value }
    @all = -> (value) { [1, 2, 3] }
  end


  describe "Filter params must be okay" do

    it "Null filtering" do

      # Default null filtering
      filtering_params = RiceCooker::Filter::parse_filtering_param("", @allowed_params)
      expect(filtering_params).to be_eql({})
    end

    it "Default filtering" do

      params = ({
        login: "aaubin"
      })

      filtering_params = RiceCooker::Filter::parse_filtering_param(params, @allowed_params)
      expect(filtering_params).to be_eql({login: ["aaubin"]})
    end

    it "Double filtering" do

      params = ({
        login: "aaubin,qbollach"
      })

      filtering_params = RiceCooker::Filter::parse_filtering_param(params, @allowed_params)
      expect(filtering_params).to be_eql({login: ["aaubin", "qbollach"]})
    end

    it "Multiple filtering" do

      params = ({
        login: "aaubin,qbollach,andre",
        id: "74,75,76"
      })

      filtering_params = RiceCooker::Filter::parse_filtering_param(params, @allowed_params)
      expect(filtering_params).to be_eql({
        login: ["aaubin", "qbollach", "andre"],
        id: ["74", "75", "76"]
      })
    end

    it "invalid args" do
      # invalid args

      params = ({
        wtf: "aaubin,qbollach,andre",
        id: "74,75,76"
      })

      expect { RiceCooker::Filter::parse_filtering_param(params, @allowed_params) }.to raise_error(RiceCooker::Filter::InvalidFilterException)
    end
  end

  describe "Must apply filter to given collection" do



    it "Default null filtering" do
      filtered_collection = RiceCooker::Filter::apply_filter_to_collection(@collection, {})
      # puts filtered_collection.to_sql
      expect(filtered_collection.to_sql).to match(/^((?!WHERE).)*$/)
    end

    it "Default filtering" do

      filtered_collection = RiceCooker::Filter::apply_filter_to_collection(@collection, {login: ["aaubin"]})
      # puts filtered_collection.to_sql
      expect(filtered_collection.to_sql).to match(/WHERE/)
      expect(filtered_collection.to_sql).to match(/"login" = 'aaubin'/)
    end

    it "Double filtering" do
      # Desc filtering
      filtered_collection = RiceCooker::Filter::apply_filter_to_collection(@collection, {login: ["aaubin", "qbollach"]})
      # puts filtered_collection.to_sql
      expect(filtered_collection.to_sql).to match(/WHERE/)
      expect(filtered_collection.to_sql).to match(/"login" IN \('aaubin', 'qbollach'\)/)
    end

    it "Multiple filtering" do
      # Desc filtering
      filtered_collection = RiceCooker::Filter::apply_filter_to_collection(@collection, {
        login: ["aaubin", "qbollach", "andre"],
        id: ["74", "75", "76"]
      })
      # puts filtered_collection.to_sql
      expect(filtered_collection.to_sql).to match(/WHERE/)
      expect(filtered_collection.to_sql).to match(/"login" IN \('aaubin', 'qbollach', 'andre'\)/)
      expect(filtered_collection.to_sql).to match(/AND/)
    end
  end

  describe "Must apply custom filters to given collection" do



    it "Default null filtering" do
      filtered_collection = RiceCooker::Filter::apply_filter_to_collection(@collection, {}, @test_filter)
      # puts filtered_collection.to_sql
      expect(filtered_collection.to_sql).to match(/^((?!WHERE).)*$/)
    end

    it "Default filtering" do
      filtered_collection = RiceCooker::Filter::apply_filter_to_collection(@collection, {with_the_letter: ["a"]}, @test_filter)
      # puts filtered_collection.to_sql
      expect(filtered_collection.to_sql).to match(/WHERE/)
      expect(filtered_collection.to_sql).to match(/ILIKE/)
    end

    it "Double filtering" do
      # Desc filtering
      filtered_collection = RiceCooker::Filter::apply_filter_to_collection(@collection, {with_the_letter: ["a"], without_the_letter: ["l"]}, @test_filter)
      # puts filtered_collection.to_sql
      expect(filtered_collection.to_sql).to match(/WHERE/)
      expect(filtered_collection.to_sql).to match(/first_name ILIKE '%a%'/)
      expect(filtered_collection.to_sql).to match(/NOT \(first_name ILIKE '%l%'\)/)
    end

    it "Multiple filtering" do
      # Desc filtering
      filtered_collection = RiceCooker::Filter::apply_filter_to_collection(@collection, {
        login: ["aaubin", "qbollach", "andre"],
        id: ["74", "75", "76"]
      })
      # puts filtered_collection.to_sql
      expect(filtered_collection.to_sql).to match(/WHERE/)
      expect(filtered_collection.to_sql).to match(/"login" IN \('aaubin', 'qbollach', 'andre'\)/)
      expect(filtered_collection.to_sql).to match(/AND/)
    end

    it "invalid args" do
      # invalid args
      expect do
        RiceCooker::Filter::apply_filter_to_collection(
          @collection,
          {sorted: ["true", "baguette"]},
          RiceCooker::Filter::format_addtional_filtering_param({sorted: [-> (v) { v }, ["true", "false", "maybe"]]})
        )
      end.to raise_error(RiceCooker::Filter::InvalidFilterValueException)
    end
  end

  describe "Additional params must be correctly formated" do
    

    it "No additional params" do
      formated = RiceCooker::Filter::format_addtional_filtering_param({})
      expect(formated).to be_eql({})
    end

    it "Already correctly formatted additional params" do
      p = {filter: {
        proc: @proc,
        all: [1, 2, 3],
        description: "A good filter"
      }}
      formated = RiceCooker::Filter::format_addtional_filtering_param(p)
      expect(formated).to be_eql(p)
    end

    it "Missing description additional params" do
      p = {filter: {
        proc: @proc,
        all: [1, 2, 3]
      }}
      expected = {filter: {
        proc: @proc,
        all: [1, 2, 3],
        description: ""
      }}
      formated = RiceCooker::Filter::format_addtional_filtering_param(p)
      expect(formated).to be_eql(expected)
    end


    it "Only proc additional params" do

      p = {filter: @proc}
      expected = {filter: {
        proc: @proc,
        all: [],
        description: ""
      }}
      formated = RiceCooker::Filter::format_addtional_filtering_param(p)
      expect(formated).to be_eql(expected)
    end

    it "Array with proc and all additional params" do

      p = {filter: [@proc, @all]}
      expected = {filter: {
        proc: @proc,
        all: @all,
        description: ""
      }}
      formated = RiceCooker::Filter::format_addtional_filtering_param(p)
      expect(formated).to be_eql(expected)
    end


    it "Multiple, std + Array with proc and all additional params" do

      p = {
        tata: @proc,
        toto: {proc: @proc, all: [1, 2]},
        filter: [@proc, @all],
        tutu: {proc: @proc, description: "Buuuuh"}
      }
      expected = {
        tata: {
          proc: @proc,
          all: [],
          description: ""
        },
        toto: {
          proc: @proc,
          all: [1, 2],
          description: ""
        },
        filter: {
          proc: @proc,
          all: !all,
          description: ""
        },
        tutu: {
          proc: @proc,
          all: [],
          description: "Buuuuh"
        }
      }
      formated = RiceCooker::Filter::format_addtional_filtering_param(p)
      expect(formated).to be_eql(expected)
    end


  end


end