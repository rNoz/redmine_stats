class StatsController < ApplicationController
  unloadable
  


  def index

    check_filter # check filters... if find set_filter variable should route to issues#index

    @dates = date_interval
    parameters = @dates               #dates to filter by

    @s_project = get_project          #project to filter by
    parameters[:project] = @s_project
    
  
  	@statuses = IssueStatus.all
  	@trackers = Tracker.all
  	@priorities = IssuePriority.all.reverse
  	#@assignees = Stat.assignable_users(@s_project)
  	@authors = Stat.authors(@s_project)

    @projects = Project.active           #List os projects that can be used as a filter
    


    @open_issues = Stat.issues_by_priority()
    @issues_by_tracker = Stat.issues_by_tracker(parameters)
  	@issues_by_priority = Stat.issues_by_priority(parameters)
  	@issues_by_assigned_to = Stat.issues_by_assigned_to(parameters)
  	@issues_by_project = Stat.issues_by_project(parameters)
  	@issues_last_days = Stat.issues_by_days(parameters)
  	
    @top5 = Stat.top5(parameters)

    @assignees = @issues_by_assigned_to.map{|obj| User.find obj["assigned_to_id"]}.uniq
    @used_projects = @issues_by_project.map{|obj| Project.find obj["project_id"]}.uniq if @s_project.nil?

  end


  def get_project
    p = get_project_identifier
    return Project.find_by_identifier(get_project_identifier) unless p.nil?
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



end
