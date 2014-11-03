require_dependency 'issue'

module RedmineStats
  module Patches

    module IssuePatch
     
      def self.included(base) # :nodoc:
          base.send(:extend, ClassMethods)
          base.class_eval do    
            unloadable
          end
        end

        module ClassMethods
          def created_on(date)
            where(['created_on >= ? AND created_on < ?', date, date + 1])
          end

          def closed_on(date)
            where(['closed_on >= ? AND closed_on < ?', date, date + 1])
          end

          def top5

            issues = []

            Journal.select("journalized_id, count(journalized_id) AS count").
            group("journalized_id").
            order("count DESC").
            limit(5).each do |row|
              issues << Issue.find(row.issue.id)
            end

            issues
            
          end

        end
    
        module InstanceMethods
          
        end

        
   
    end
  end
end


unless Issue.included_modules.include?(RedmineStats::Patches::IssuePatch)
  Issue.send(:include, RedmineStats::Patches::IssuePatch)
end