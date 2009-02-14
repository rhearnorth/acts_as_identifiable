module ActiveRecord
  module Acts
    module Identifiable
      
      ###############
      # Constructor #
      ###############
      
      # This constructor is evoked when this module is included by <i>vendor/plugins/acts_as_identifiable/init.rb</i>. That is, every time your Rails application is loaded, ActiveRecord is extended with the Acts::Identifiable modules, and thus calls this constructor method.
      def self.included(base)
        # Add class methods module of Acts::Identifiable to the superior class ActiveRecord
        # In that module, the InstanceMethods will be added as well
        base.extend ClassMethods
      end

      #######################
      # ClassMethods module #
      #######################
      
      module ClassMethods        
        # Please refer to README for more information about this plugin.
        #
        #
        # Configuration options are:
        # * <tt>column</tt> - specifies a column name to use for the fulltext search (default: +username+)
        def acts_as_identifiable(options = {})
        
          # Load parameters whenever acts_as_identifiable is called
          configuration = { :column => 'username' }
          configuration.update(options) if options.is_a?(Hash)
          
          # This class_eval contains methods which cannot be added wihtout having a concrete model.
          # Say, we want these methods to use parameters like "configuration[:column]", but we
          # don't have these parameters, unless somebody evokes the acts_as_identifiable method in his
          # model. So we use class_eval, which generates methods, when acts_as_identifiable is called,
          # and not already when our plugin's init.rb adds our Acts::Identifiable modules to ActiveRecord.

          def self.keywords(pattern, remove_whitespace = false)
            replacer = remove_whitespace ? '' : ' '
            pattern.gsub(/A-ZÁÀÂÃÉÈÊËÇÑÍÌÎÏÓÒÔÕŒÚÙÛŸÖÄÜßĲÅÆØÞĀĄĂĒĖĘĪĮŐŰŮŬŲŪČĐĎĢĶŁĻĽŃŅŇŔŠŠȘŤȚÝÝŽŻ/i, '').gsub(/ +/, replacer).downcase.strip.chomp
          end

          class_eval <<-EOV

            ###########################
            # Generated class methods #
            ###########################

            # Identify id of an object by +pattern+
            #
            # Returns +id+ if similarity found.
            # Returns +false+ if +pattern+ is less than three letters or no positive match with any user.
            def self.identify(pattern)
              # Is the number of actual legal characters (excl. whitespace) valid?
              return false if keywords(pattern, true).length < 3
              # Is the name exactly the one in the database?
              exact_match = find(:first, :conditions => ['LOWER(#{configuration[:column]}) = ?', pattern.downcase.strip.chomp])
              return exact_match.id unless exact_match.blank?
              # Apparently not, so let's do a full text identification
              array_conditions = Array.new
              for keyword in keywords(pattern).split do # This is injection safe because of "keywords()"
                array_conditions << '(#{configuration[:column]} LIKE ?)'.gsub('?', '"%' +keyword+ '%"')
              end
              found = find(:all, :conditions => array_conditions.join(' AND '))
              # Okay if we found just one user. If more than one were found, that's bad!
              return false unless found.length == 1
              found.first.id
            end

          EOV
        end
      end

    end
  end
end
