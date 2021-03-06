require File.expand_path(File.join(File.dirname(__FILE__), "..", "transport", "json"))
require File.join(File.dirname(__FILE__), "configuration")
require File.join(File.dirname(__FILE__), "base")
require File.join(File.dirname(__FILE__), "view")
require 'yaml'

module CouchModel

  # The Design class acts as a wrapper for CouchDB design documents.
  class Design

    attr_reader   :database
    attr_reader   :model_class
    attr_accessor :id
    attr_reader   :rev
    attr_accessor :language
    attr_reader   :views

    def initialize(database, model_class, attributes = { })
      @database     = database
      @model_class  = model_class
      @language     = "javascript"
      @views        = [ ]

      load_file
      self.id       = attributes[:id]       if attributes.has_key?(:id)
      self.language = attributes[:language] if attributes.has_key?(:language)
      self.views    = attributes[:views]    if attributes.has_key?(:views)
    end

    def filename
      @filename ||= File.join(CouchModel::Configuration.design_directory, "#{@model_class.to_s.underscore}.design")
    end

    def load_file
      hash = YAML::load_file self.filename
      self.class.symbolize_hash_keys hash
      self.id, self.language, self.views = hash.values_at(:id, :language, :views)
      true
    rescue Errno::ENOENT
      false
    end

    def views=(view_hash)
      @views = [ ]
      view_hash.each do |view_name, view|
        @views << View.new(self, view.merge(:name => view_name.to_s)) if view.is_a?(Hash)
      end if view_hash.is_a?(Hash)
    end

    def generate_view(name, options = { })
      view = View.new self, options.merge(:name => name.to_s)
      @views.insert 0, view
      view
    end

    def to_hash
      rev = self.rev
      hash = {
        "_id"       => "_design/#{self.id}",
        "language"  => self.language,
        "views"     => { }
      }
      hash.merge! "_rev" => rev if rev
      @views.each { |view| hash["views"].merge! view.to_hash }
      hash
    end

    def exists?
      Transport::JSON.request :get, self.url, :expected_status_code => 200
      true
    rescue Transport::JSON::UnexpectedStatusCodeError
      false
    end

    def push
      url = self.url
      evaluate Transport::JSON.request(:get, url)

      Transport::JSON.request :put, url, :body => self.to_hash, :expected_status_code => 201
      true
    end

    def url
      "#{@database.url}/_design/#{self.id}"
    end

    private

    attr_writer :rev

    def evaluate(response)
      self.rev = response["_rev"] if response.has_key?("_rev")
    end

    def self.symbolize_hash_keys(hash)
      hash.keys.each do |key|
        value = hash.delete key
        symbolize_hash_keys value if value.is_a?(Hash)
        hash[(key.to_sym rescue key) || key] = value
      end
    end

  end

end
