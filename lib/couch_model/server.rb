require File.expand_path(File.join(File.dirname(__FILE__), "..", "transport", "json"))

module CouchModel

  # The Server class provides methods to retrieve informations and statistics
  # of a CouchDB server.
  class Server

    attr_reader :host
    attr_reader :port

    def initialize(options = { })
      @host = options[:host] || "localhost"
      @port = options[:port] || "5984"
    end

    def ==(other)
      other.is_a?(self.class) && @host == other.host && @port == other.port
    end

    def informations
      Transport::JSON.request :get, url + "/", :expected_status_code => 200
    end

    def statistics
      Transport::JSON.request :get, url + "/_stats", :expected_status_code => 200
    end

    def database_names
      Transport::JSON.request :get, url + "/_all_dbs", :expected_status_code => 200
    end

    def uuids(count = 1)
      response = Transport::JSON.request :get, url + "/_uuids", :expected_status_code => 200, :parameters => { :count => count }
      response["uuids"]
    end

    def url
      "http://#{@host}:#{@port}"
    end

  end

end
