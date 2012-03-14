require 'net/ldap'

module Tombstone
  class LDAP
    extend Delegator
    
    delegate self, :server, :servers, :use_ssl, :domain, :logger, :connection
    
    @servers = []
    @logger = Logger.new(nil)
    class << self
      attr_accessor :servers, :use_ssl, :domain, :logger, :connection
      
      def server
        servers << servers.shift
        host, port = servers[-1].split(':')
        [host, (port || (use_ssl ? 636 : 389)).to_i]
      end
    end
    
    attr_reader :username, :qualified_username
    
    # Username can be equalified or unqualified. An unqualidied username is qualified with the set domain.
    def initialize(username, password)
      raise StandardError, "Password must not be of zero length" if password.length == 0
      qualified_username = username
      if username.index(/[\\@]/).nil?
        qualified_username = "#{username}@#{domain}"
      elsif username.index('\\')
        username = username.split('\\')[1]
        qualified_username = "#{username}@#{domain}"
      else
        username = username.split('@')[0]
      end
      
      @qualified_username, @username, @password = qualified_username, username.to_s, password.to_s
      connection.authenticate(@qualified_username, @password)
    end
    
    def connection
      @connection ||= begin
        host, port = server
        Net::LDAP.new(host: host, port: port, encryption: (:simple_tls if use_ssl))
      end
    end
    
    def authenticated?
      !!@authenticated
    end
    
    def authenticate(attempts = 0)
      @connection = nil if attempts > 0
      begin
        if connection.bind
          logger.info("Authenticated #{@qualified_username} by #{connection.host}:#{connection.port}")
          @authenticated = true
        else
          op_result = connection.get_operation_result
          if op_result.code == 49
            logger.info("Error attempting to authenticate #{@qualified_username} by #{connection.host}:#{connection.port}.
              The error was: #{op_result.code} #{op_result.message}")
            false
          elsif attempts >= (servers.length)
            error = "An error occured while authenticating #{@qualified_username}. The error was: #{op_result.code} #{op_result.message}"
            logger.error(error)
            raise StandardError, error
          else
            logger.info("Error attempting to authenticate #{@qualified_username} by #{connection.host}:#{connection.port}. Trying next server.")
            authenticate(attempts + 1)
          end
        end
      rescue Net::LDAP::LdapError => e
        if attempts >= (servers.length)
          error = "An error occured while authenticating #{@qualified_username}. The error was: #{op_result.code} #{op_result.message}"
          logger.error(error)
          raise StandardError, error
        else
          logger.info("Error attempting to authenticate #{@qualified_username} by #{connection.host}:#{connection.port}.
            Trying next server. The error was: #{e.message}")
          authenticate(attempts + 1)
        end
      end
    end
    
    # Returns the details of the authenticated user (the username that was given when the object was initialized)
    def user_details
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