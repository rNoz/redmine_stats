class Stat < ActiveRecord::Base
  unloadable


 
  #issues more active
  def self.top5(params)

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







  #get all authors of issues
  def self.author_users()
  	
  	

  	users = []

		ActiveRecord::Base.connection.execute("SELECT count(author_id), author_id from issues group by author_id  order by count(author_id) DESC LIMIT 5").each do |row|
					users << User.find(row["author_id"])
				end

		users
		
			
		
  end





  #get all assignable users
  def self.assignable_users(project)

  	return project.assignable_users unless project == nil

  	users = []

		ActiveRecord::Base.connection.execute("select t3.user_id from roles as t1 
				INNER JOIN member_roles as t2 on
				t1.id = t2.role_id
				inner join members as t3
				on t3.id = t2.member_id
				inner join users as t4
				on t3.user_id = t4.id
				where t1.assignable = 't' and t4.type = 'User'
				group by t3.user_id").each do |row|
					users << User.find(row["user_id"])

				end

		users

  end


  #issues opened/closed by date
  def self.by_days(parameters)

  	created = []
  	closed = []
  	dates = []

    begin_date = parameters[:begin_date]
    end_date = parameters[:end_date]
    project = parameters[:project]

    #no date filters
    if(begin_date.nil? and end_date.nil?)

    	7.times do |days_before|

        if(project.nil?)

      		date = Date.today - days_before
      		created << Issue.created_on(date).count
      		closed << Issue.closed_on(date).count
      		dates << date.strftime("%A, %d")
        else #filter by project
          date = Date.today - days_before
          created << project.issues.created_on(date).count
          closed << project.issues.closed_on(date).count
          dates << date.strftime("%A, %d")
        end
    	end

      created.reverse!
      closed.reverse!
      dates.reverse!
      
    else #date filters
      (begin_date..end_date).to_a.each do|d| 
        if(project.nil?) #no project filter

          created << Issue.created_on(d).count
          closed << Issue.closed_on(d).count
          dates << d.strftime("%A, %d") 
        else #project filter
          
          created << @s_project.issues.created_on(d).count
          closed << @s_project.issues.closed_on(d).count
          dates << d.strftime("%A, %d") 
        end
      end
    end

  	

  	{created:created, closed:closed, dates:dates}

  end



  def self.by_author(parameters)
    count_and_group_by(:field => 'author_id',
                       :joins => User.table_name,
                       :begin_date  => parameters[:begin_date],
                       :end_date    => parameters[:end_date],
                       :project     => parameters[:project])
  end

  def self.by_assigned_to(parameters)
    count_and_group_by(:field => 'assigned_to_id',
                       :joins => User.table_name,
                       :begin_date  => parameters[:begin_date],
                       :end_date    => parameters[:end_date],
                       :project     => parameters[:project])
  end

  def self.by_priority(parameters)
    count_and_group_by(:field => 'priority_id',
                       :joins => IssuePriority.table_name,
                       :begin_date  => parameters[:begin_date],
                       :end_date    => parameters[:end_date],
                       :project     => parameters[:project])
  end

  def self.by_tracker(parameters)
    count_and_group_by(:field => 'tracker_id',
                       :joins => Tracker.table_name,
                       :begin_date  => parameters[:begin_date],
                       :end_date    => parameters[:end_date],
                       :project     => parameters[:project])
  end





  def self.count_and_group_by(options)

    select_field = options.delete(:field)
    joins = options.delete(:joins)
    begin_date = options.delete(:begin_date)
    end_date = options.delete(:end_date)
    project = options.delete(:project)

    #create the where clause

    where = "#{Issue.table_name}.#{select_field}=j.id"

    unless begin_date.nil? and end_date.nil?
      begin_date = begin_date.to_datetime
      end_date = (end_date + 1.day).to_datetime
      
      where << " and 
      ((#{Issue.table_name}.created_on >= '#{begin_date}' and #{Issue.table_name}.created_on <= '#{end_date}') or
        (#{Issue.table_name}.closed_on >= '#{begin_date}' and #{Issue.table_name}.closed_on <= '#{end_date}'))"
    
    end

   
      where << " and #{Issue.table_name}.project_id=#{Project.table_name}.id 
      and #{Project.table_name}.identifier = '#{project.identifier}' "  unless project.nil?
    
      
    # end of create the where clause

    
    sql = "select s.id as status_id, 
            s.is_closed as closed, 
            j.id as #{select_field},
            count(#{Issue.table_name}.id) as total 
          from 
              #{Issue.table_name}, #{Project.table_name}, #{IssueStatus.table_name} s, #{joins} j
          where 
            #{Issue.table_name}.status_id=s.id 
            and #{where}
          group by s.id, s.is_closed, j.id"
    
    
    ActiveRecord::Base.connection.select_all(sql)
  end

end
