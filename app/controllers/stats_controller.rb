class StatsController < ApplicationController
  unloadable
  


  def index

  	check_filter
    @dates = date_interval

  	@statuses = IssueStatus.all
  	@trackers = Tracker.all
  	@priorities = IssuePriority.all.reverse
  	@assignees = assignable_users
  	@authors = author_users


  	@issues_by_tracker = by_tracker(@dates)
  	@issues_by_priority = by_priority(@dates)
  	@issues_by_assigned_to = by_assigned_to(@dates)
  	@issues_by_author = by_author(@dates)
  	@issues_last_days = by_days(@dates)
  	@top5 = Issue.top5(@dates)

  end

  def date_interval

    begin_date = nil
    end_date = nil

    date = Date.today

    unless params[:active_filter].nil?
      case params[:active_filter]
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

  def by_days(params)

  	created = []
  	closed = []
  	dates = []

    begin_date = params[:begin_date]
    end_date = params[:end_date]

    if(begin_date.nil? and end_date.nil?)

    	7.times do |days_before|
    		date = Date.today - days_before
    		created << Issue.created_on(date).count
    		closed << Issue.closed_on(date).count
    		dates << date.strftime("%A")

        created.reverse!
        closed.reverse!
        dates.reverse!

    	end
      
    else
    
      (begin_date..end_date).to_a.each do|d| 
        created << Issue.created_on(d).count
        closed << Issue.closed_on(d).count
        dates << d.strftime("%A, %d") 
      end
    end

  	

  	{created:created, closed:closed, dates:dates}

  end

   def by_author(params)
    count_and_group_by(:field => 'author_id',
                       :joins => User.table_name,
                       :begin_date  => params[:begin_date],
                       :end_date    => params[:end_date])
  end

  def by_assigned_to(params)
    count_and_group_by(:field => 'assigned_to_id',
                       :joins => User.table_name,
                       :begin_date  => params[:begin_date],
                       :end_date    => params[:end_date])
  end

  def by_priority(params)
    count_and_group_by(:field => 'priority_id',
                       :joins => IssuePriority.table_name,
                       :begin_date  => params[:begin_date],
                       :end_date    => params[:end_date])
  end

  def by_tracker(params)
    count_and_group_by(:field => 'tracker_id',
                       :joins => Tracker.table_name,
                       :begin_date  => params[:begin_date],
                       :end_date    => params[:end_date])
  end


  def count_and_group_by(options)

    select_field = options.delete(:field)
    joins = options.delete(:joins)
    begin_date = options.delete(:begin_date)
    end_date = options.delete(:end_date)

    if begin_date.nil? and end_date.nil?
      where = "#{Issue.table_name}.#{select_field}=j.id"
    else
      begin_date = begin_date.to_datetime
      end_date = (end_date + 1.day).to_datetime
      
      where = "#{Issue.table_name}.#{select_field}=j.id 
          AND #{Issue.table_name}.created_on >= '#{begin_date}' 
          AND #{Issue.table_name}.created_on <= '#{end_date}'"
    
    end
      

    
    sql = "select    s.id as status_id, 
            s.is_closed as closed, 
            j.id as #{select_field},
            count(#{Issue.table_name}.id) as total 
          from 
              #{Issue.table_name}, #{Project.table_name}, #{IssueStatus.table_name} s, #{joins} j
          where 
            #{Issue.table_name}.status_id=s.id 
            and #{where}
          group by s.id, s.is_closed, j.id"
    
    puts "aaa #{sql}"
    ActiveRecord::Base.connection.select_all(sql)
  end


end
