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



          def created_between(begin_date, end_date)
            begin_date = begin_date.to_datetime
            end_date = (end_date + 1.day).to_datetime
            
            where(['created_on >= ? AND created_on < ?', begin_date, end_date])
          end



          def closed_between(begin_date, end_date)
            begin_date = begin_date.to_datetime
            end_date = (end_date + 1.day).to_datetime

            where(['closed_on >= ? AND closed_on < ?', begin_date, end_date])
          end



          def top5(params)

            issues = []
            where = ""

            unless params[:begin_date].nil?
              puts "ccc #{params}"
              begin_date = params[:begin_date].to_datetime
              end_date = (params[:end_date] + 1.day).to_datetime
              
              where = ['created_on >= ? AND created_on < ?', begin_date, end_date] 

            end
            Journal.select("journalized_id, count(journalized_id) AS count").
            where(where).
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