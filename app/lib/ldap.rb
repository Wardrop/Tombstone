require 'net/ldap'

module Tombstone
  class LDAP
    delegate :server, :servers, :use_ssl, :domain, :logger, :connection, :parse_username, :to => self
    
    @servers = []
    @logger = Logger.new(nil)
    class << self
      attr_accessor :servers, :use_ssl, :domain, :logger, :connection
      
      def server
        servers << servers.shift
        host, port = servers[-1].split(':')
        [host, (port || (use_ssl ? 636 : 389)).to_i]
      end
      
      def parse_username(username)
        username.split('\\')[1] || username.split('@')[0] || username
      end
    end
    
    attr_reader :username, :qualified_username, :last_message
    
    # Username can be equalified or unqualified. An unqualidied username is qualified with the set domain.
    def initialize(username, password)
      raise StandardError, "Username must not be blank" if username.blank?
      raise StandardError, "Password must not be blank" if password.blank?
      username = parse_username(username)
      qualified_username = "#{username}@#{domain}"
      @qualified_username, @username, @password = qualified_username, username.to_s, password.to_s
    end
    
    def connection
      @connection ||= begin
        host, port = server
        conn = Net::LDAP.new(host: host, port: port, encryption: (:simple_tls if use_ssl))
        conn.authenticate(@qualified_username, @password)
        conn
      end
    end
    
    def authenticated?
      !!@authenticated
    end
    
    def authenticate
      @authenticated = nil
      @last_message = nil
      last_error = nil
      servers.length.times do |attempt|
        last_error = nil
        @connection = nil
        logger.info("Attempting to authenticate against #{connection.host}:#{connection.port}.")
        begin
          if connection.bind
            @last_message = "Successfully authenticated #{@qualified_username}."
            @authenticated = true
            break
          elsif connection.get_operation_result.code == 49
            @last_message = "Authentication failed due to invalid credentials."
            @authenticated = false
            break
          else
            op_result = connection.get_operation_result
            @last_message = "Error attempting to authenticate. The error was: #{op_result.code} #{op_result.message}"
          end
        rescue Net::LDAP::LdapError => e
          last_error = e
          @last_message = "Error attempting to authenticate #{@qualified_username}. The error was: #{e.message}"
        end
        logger.error(@last_message) if @last_message
      end
      
      if @authenticated.nil?
        raise StandardError, @last_message
      else
        logger.info(@last_message)
        @authenticated
      end
    end
    
    # Returns the details of the authenticated user (the username that was given when the object was initialized)
    def user_details
      return @user_details if @user_details
      treebase = domain.split('.').map{|v| "dc=#{v}"}.join(',')
      result_set = connection.search(:base => treebase,:filter => Net::LDAP::Filter.eq("userPrincipalName", @qualified_username))
      if result_set.nil?
        op_result = ldap.connection.get_operation_result
        raise StandardError, "Could not get user details for user #{@username}. The error was: (#{op_result.code}) #{op_result.message}" 
      end
      result_set.first
    end
  end
end