class StatsController < ApplicationController
  unloadable



  def index

  	@statuses = IssueStatus.all
  	@trackers = Tracker.all
  	@priorities = IssuePriority.all.reverse
  	@assignees = assignable_users
  	@authors = author_users

  	puts "xxx #{@assignees}"

  	@issues_by_tracker = by_tracker
  	@issues_by_priority = by_priority
  	@issues_by_assigned_to = by_assigned_to
  	@issues_by_author = by_author

  	@issues_last_days = by_days

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

  def by_days

  	created = []
  	closed = []
  	dates = []

  	7.times do |days_before|
  		date = Date.today - days_before
  		created << Issue.created_on(date).count
  		closed << Issue.closed_on(date).count
  		dates << date.strftime("%A")
  	end

  	created.reverse!
  	closed.reverse!
  	dates.reverse!

  	{created:created, closed:closed, dates:dates}

  end

   def by_author
    count_and_group_by(:field => 'author_id',
                       :joins => User.table_name)
  end

  def by_assigned_to
    count_and_group_by(:field => 'assigned_to_id',
                       :joins => User.table_name)
  end

  def by_priority
    count_and_group_by(:field => 'priority_id',
                       :joins => IssuePriority.table_name)
  end

  def by_tracker
    count_and_group_by(:field => 'tracker_id',
                       :joins => Tracker.table_name)
  end


  def count_and_group_by(options)

    select_field = options.delete(:field)
    joins = options.delete(:joins)

    where = "#{Issue.table_name}.#{select_field}=j.id"
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
          puts "asd #{sql}"
    ActiveRecord::Base.connection.select_all(sql)
  end


end
