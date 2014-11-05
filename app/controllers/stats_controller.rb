class StatsController < ApplicationController
  unloadable
  


  def index

  	check_filter
    @dates = date_interval
    parameters = @dates

    get_project
    parameters[:project] = @s_project
    
    @open_issues = Issue.open.count
  
  	@statuses = IssueStatus.all
  	@trackers = Tracker.all
  	@priorities = IssuePriority.all.reverse
  	@assignees = assignable_users
  	@authors = author_users

    @projects = Project.all
    @projects.insert(0, Project.new(identifier: "all_projects", name: l(:stats_all_projects)))


    @issues_by_tracker = by_tracker(parameters)
  	@issues_by_priority = by_priority(parameters)
  	@issues_by_assigned_to = by_assigned_to(parameters)
  	@issues_by_author = by_author(parameters)
  	@issues_last_days = by_days(parameters)
  	
    @top5 = Issue.top5(parameters)

  end

  def get_project
    p = get_project_identifier
    @s_project =  Project.where(identifier: get_project_identifier).first if p != nil
  end

  def get_project_identifier
      return params[:project] if !params[:project].nil? and params[:project] != "all_projects"
  end

  def date_interval

    begin_date = nil
    end_date = nil

    date = Date.today

    unless params[:time_filter].nil?
      case params[:time_filter]
        when "current_week"
          begin_date = date.beginning_of_week
          end_date = date.end_of_week
        when "last_week"
          date -= 1.week
          begin_date = date.beginning_of_week
          end_date = date.end_of_week
        when "current_month"
          begin_date = date.beginning_of_month
          end_date = date.end_of_month
         when "last_month"
          date -= 1.month
          begin_date = date.beginning_of_month
          end_date = date.end_of_month
      end
    end

    {begin_date: begin_date, end_date: end_date}

  end

  def check_filter
  	if (params[:set_filter])
  		respond_to do |format|
        if @field
          format.html {}
        else
          format.html { redirect_to :controller => 'issues', :action => 'index', :params => params}
        end
      end
  	end
  end

  def author_users
  	

  	users = []

		ActiveRecord::Base.connection.execute("SELECT count(author_id), author_id from issues group by author_id  order by count(author_id) DESC LIMIT 5").each do |row|
					users << User.find(row["author_id"])
				end

		users

  end


  def assignable_users

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

  def by_days(parameters)

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

  def by_author(parameters)
    count_and_group_by(:field => 'author_id',
                       :joins => User.table_name,
                       :begin_date  => parameters[:begin_date],
                       :end_date    => parameters[:end_date],
                       :project     => parameters[:project])
  end

  def by_assigned_to(parameters)
    count_and_group_by(:field => 'assigned_to_id',
                       :joins => User.table_name,
                       :begin_date  => parameters[:begin_date],
                       :end_date    => parameters[:end_date],
                       :project     => parameters[:project])
  end

  def by_priority(parameters)
    count_and_group_by(:field => 'priority_id',
                       :joins => IssuePriority.table_name,
                       :begin_date  => parameters[:begin_date],
                       :end_date    => parameters[:end_date],
                       :project     => parameters[:project])
  end

  def by_tracker(parameters)
    count_and_group_by(:field => 'tracker_id',
                       :joins => Tracker.table_name,
                       :begin_date  => parameters[:begin_date],
                       :end_date    => parameters[:end_date],
                       :project     => parameters[:project])
  end


  def count_and_group_by(options)

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
