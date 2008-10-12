#--
# Copyright 2008 David Kellum
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License.  You
# may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.
#++

require 'slf4j/version'
require 'java'

# Wrapper and core Logger compatible adapter for the
# SLF4J[http://www.slf4j.org/] logging interface.
#
# == Usage
#
#   require 'slf4j'
#   log = SLF4J.logger( "my.app.logger" )
#   log.info { "Hello World!" }
#
# == Adapters
#
# All of the following output adapters are available via +require+
#
#   require 'slf4j/jcl'       # Output to Jakarta Commons Logging
#   require 'slf4j/jdk14'     # JDK java.util.logging 
#   require 'slf4j/log4j12'   # Log4j (provided elsewhere)
#   require 'slf4j/nop'       # NOP null logger (provided)
#   require 'slf4j/simple'    # Simple logger (provided)
#
# The first loaded output adapter wins (as per SLF4J classpath
# conventions). A warning will be logged to the "slf4j" Logger if an
# attempt is made to require a second output adapter.
#
# And the following input adapters will intercept JCL,
# java.util.logging (jdk14), or log4j log output and direct it through
# SLF4J:
#
#   require 'slf4j/jcl-over-slf4j'   # Route Jakarta Commons Logging to SLF4J
#   require 'slf4j/jul-to-slf4j'     # JDK java.util.logging to SLF4J
#   require 'slf4j/log4j-over-slf4j' # Log4j to SLF4J
#
# Multiple input adapters may be require'd.  However, a RuntimeError
# will be raised in the attempt to require both an output adapter and
# input adapter from/to the same interface, for example
# 'slf4j/jcl-over-slf4j' and 'slf4j/jcl', which would otherwise cause
# a circular logging loop (and stack overflow.)
#
# Adapter names match the corresponding SLF4J jars.
#
module SLF4J

  # Require an adapter by name (add the jar to classpath)
  # This is normally done via require 'slf4j/_name_'
  def self.require_adapter( name ) 
    row = ADAPTERS.assoc( name )
    if row 
      name,ban = row
      output = false
    else
      row = ADAPTERS.rassoc( name )
      ban,name = row
      output = true
    end
   
    if @@loaded[ ban ]
      raise "Illegal attempt to load '#{name}' when '#{ban}' is loaded."
    end

    if output 
      if ! @@output_name.nil? && name != @@output_name
        logger("slf4j").warn do
          "Ignoring attempt to load #{name} after #{@@output_name} already loaded." 
        end
        return
      end
      if java.lang.Thread::current_thread.context_class_loader != @@api_loader
        $stderr.puts( "WARNING: Attempting to load #{name} in child class" + 
                      " loader of slf4j-api.jar loader." )
      end
      require_jar( 'slf4j-' + name )
      @@output_name = name
    else
      require_jar( name )
    end

    # Special case, requires explicit 'install'
    if name == 'jul-to-slf4j' 
      org.slf4j.bridge.SLF4JBridgeHandler.install
    end

    @@loaded[ name ] = true
  end

  def self.require_jar( name ) # :nodoc:
    require File.join( SLF4J_DIR, "#{name}-#{ SLF4J_VERSION }.jar" )
  end
  
  require_jar 'slf4j-api'

  @@api_loader = org.slf4j.ILoggerFactory.java_class.class_loader 
  @@loaded = {}
  @@output_name = nil

  # Output adapter name if one has been added, or nil.
  def self.output_name
    @@output_name
  end

  # SLF4J severity levels 
  LEVELS = %w{ trace debug info warn error }

  # Logger compatible facade over org.slf4j.Logger 
  #
  # === Generated Methods
  #
  # Corresponding methods are generated for each of the SLF4J levels:
  #
  # * trace 
  # * debug 
  # * info 
  # * warn
  # * error
  # * fatal (alias to error)
  #
  # These have the form (using _info_ as example)
  #
  #   log = Logger.new( "name" )
  #   log.info?                    # Is this level enabled for logging?
  #   log.info( "message" )        # Log message 
  #   log.info { "message" }       # Execute block if enabled 
  #                                  and log returned values as string
  class Logger
    attr_reader :name
    
    # Create new or find existing Logger by name
    #
    # Note that loggers are arranged in a hiearchy by dot '.' name
    # notation, i.e.:
    #
    # * "parent"
    # * "parent.child"
    def initialize( name )
      @name = name
      @logger = org.slf4j.LoggerFactory.getLogger( @name )
    end
   
    # Define logging methods for each level: debug(), error(), etc.
    LEVELS.each do |lvl|  
      module_eval( %Q{

        def #{lvl}?
          @logger.is#{lvl.capitalize}Enabled
        end

        def #{lvl}( msg=nil )
          msg = yield if ( block_given? && #{lvl}? )
          @logger.#{lvl}( msg.to_s ) unless msg.nil?
         end

      } )
    end

    # Alias fatal to error for Logger compatibility
    alias_method :fatal, :error
    alias_method :fatal?, :error?
  end
  
  # Get Logger by name
  def logger( name = self.class.name ) 
    Logger.new( name )
  end
  module_function :logger

  # The ILoggerFactory instance if adaptor added
  def self.linked_factory
     org.slf4j.LoggerFactory.getILoggerFactory
  end
end
