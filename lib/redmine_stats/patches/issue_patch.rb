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
            where(["#{Issue.table_name}.created_on >= ? AND created_on < ?", date, date + 1])
          end



          def closed_on(date)
            where(["#{Issue.table_name}.closed_on >= ? AND closed_on < ?", date, date + 1])
          end
          

          def top5(params)

            issues = []
            where = ""
            where_pre = nil


            begin_date = params[:begin_date].to_datetime unless params[:begin_date].nil?
            end_date = (params[:end_date] + 1.day).to_datetime unless params[:end_date].nil?
            project = params[:project]

            #creating the query... this code is really bad....

            unless project.nil?
              where_pre = "#{Issue.table_name}.project_id = #{project.id}" 
            end

            

            

            if params[:begin_date].nil?
              where = where_pre
            else
              
              
              if where_pre.nil?
                where =["#{Issue.table_name}.created_on >= ? AND #{Issue.table_name}.created_on < ?", begin_date, end_date] 
              else
                where = ["#{where_pre} and #{Issue.table_name}.created_on >= ? AND #{Issue.table_name}.created_on < ?", begin_date, end_date] 
              end
            end

            
            


            Journal.joins(:issue).select("journalized_id, count(journalized_id) AS count").
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