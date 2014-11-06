class StatsController < ApplicationController
  unloadable
  


  def index

  	# check_filter
    @dates = date_interval
    parameters = @dates               #dates to filter by

    @s_project = get_project          #project to filter by
    parameters[:project] = @s_project
    
    @open_issues = Issue.open.count
  
  	@statuses = IssueStatus.all
  	@trackers = Tracker.all
  	@priorities = IssuePriority.all.reverse
  	@assignees = Stat.assignable_users(@s_project)
  	@authors = Stat.author_users

    @projects = Project.all           #List os projects that can be used as a filter
    @projects.insert(0, Project.new(identifier: "all_projects", name: l(:stats_all_projects))) # All projects label


    @issues_by_tracker = Stat.by_tracker(parameters)
  	@issues_by_priority = Stat.by_priority(parameters)
  	@issues_by_assigned_to = Stat.by_assigned_to(parameters)
  	@issues_by_author = Stat.by_author(parameters)
  	@issues_last_days = Stat.by_days(parameters)
  	
    @top5 = Stat.top5(parameters)

  end


  def get_project
    p = get_project_identifier
    return Project.where(identifier: get_project_identifier).first if p != nil
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
end
