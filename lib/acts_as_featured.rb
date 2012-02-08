require 'active_record/acts/featured'
ActiveRecord::Base.class_eval { include ActiveRecord::Acts::Featured }
