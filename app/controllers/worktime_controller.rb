# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class WorktimeController < ApplicationController
 
  include ApplicationHelper
  
  # Checks if employee came from login or from direct url.
  before_filter :authenticate

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :deleteTime, :createTime, :updateTime, :updateProject, :addAttendanceTime ],
         :redirect_to => { :action => :listTime }
   
  def index
    listTime
  end 
   
  #List the time.
  def listTime
    eval = 'userProjects'
    if @worktime != nil && @worktime.absence? 
      @user.absences(true)      #true forces reload
      eval = 'userAbsences'
    end  
    redirect_to :controller => 'evaluator', :action => eval
  end
  
  # Shows the addAbsence page.
  def addAbsence
    createDefaultWorktime
    @accounts = Absence.list
    render :action => 'addTime'
  end
  
  # Shows the addTime page.
  def addTime
    createDefaultWorktime   
    if params.has_key? :absence_id
      @worktime.absence_id = params[:absence_id] 
    else
      @worktime.project_id = params[:project_id] || DEFAULT_PROJECT_ID
    end  
    setWorktimeAccounts
  end
  
  # Shows the edit page for the selected time.
  def editTime    
    @worktime = Worktime.find(params[:id])   
    setWorktimeAccounts
  end
  
    
  # Update the selected worktime on DB.
  def updateTime       
    @worktime = Worktime.find(params[:worktime_id])
    setWorktimeParams
    if @worktime.save
      flash[:notice] = 'Time was successfully updated.'
      listDetailTime
    else
      setWorktimeAccounts
      render :action => 'editTime'
    end  
  end
    
  # Stores the new time the data on DB.
  def createTime
    @worktime = Worktime.new
    @worktime.employee = @user    
    setWorktimeParams
    if @worktime.save      
      flash[:notice] = 'Time was successfully added.'
      if params[:commit] != 'Finish'
        account_id = @worktime.absence_id ?   
          { :absence_id => @worktime.absence_id } : 
          { :project_id => @worktime.project_id }
        redirect_to account_id.merge!({ :action => 'addTime' })
      else
        listDetailTime  
      end
    else
      setWorktimeAccounts
      render :action => 'addTime'
    end  
  end
  
  # Show the change project page.
  def changeProject
    if @user.management then @projects = Project.list
    else @projects = @user.managed_projects
    end  
    @worktime = Worktime.find(params[:worktime_id])
  end
  
  def updateProject
    @worktime = Worktime.find(params[:worktime_id])
    if @worktime.update_attributes(params[:worktime])
      flash[:notice] = 'Project was successfully changed'
      redirect_to evaluation_detail_params.merge!({
                        :controller => 'evaluator',
                        :action => 'details' }) 
    else
      render :action => 'changeProject'
    end
  end
  
  def confirmDeleteTime
    @worktime = Worktime.find(params[:id])
  end
  
  def deleteTime
    Worktime.destroy(params[:id])
    redirect_to evaluation_detail_params.merge!({
                  :controller => 'evaluator', 
                  :action => 'details'})
  end
  
  def attendance
    createDefaultWorktime   
  end
  
  def saveAttendance
    @worktime = Worktime.new
    @worktime.employee = @user
    setWorktimeParams
    if @worktime.valid?     
      attendance = Attendance.new(@worktime)
      if params[:commit] != 'Finish'
        session[:attendance] = attendance
        redirect_to :action => 'splitAttendance'
      else       
        attendance.save
        flash[:notice] = 'Time was successfully added.'
        listDetailTime  
      end
    else
      render :action => 'attendance'
    end  
  end
  
  def splitAttendance
    @attendance = session[:attendance]
    redirect_to :action => 'addTime' if @attendance.nil?
    @worktime = @attendance.worktimeTemplate
    setWorktimeAccounts
  end
  
  def deleteAttendanceTime
    session[:attendance].removeWorktime(params[:attendance_id].to_i)
    redirect_to :action => 'splitAttendance'
  end
  
  def addAttendanceTime
    @worktime = Worktime.new
    @worktime.employee = @user
    setWorktimeParams
    @attendance = session[:attendance]
    if @worktime.valid?      
      @attendance.addWorktime(@worktime)         
      if params[:commit] != 'Finish' && @attendance.incomplete?
        redirect_to :action => 'splitAttendance'
      else
        @attendance.save
        session[:attendance] = nil
        flash[:notice] = 'All times were successfully added.'
        listDetailTime
      end
    else
      setWorktimeAccounts
      render :action => 'splitAttendance'
    end  
  end
  
private

  #List the time.
  def listDetailTime
    eval = 'userProjects'
    if @worktime != nil && @worktime.absence? 
      @user.absences(true)      #true forces reload
      eval = 'userAbsences'
    end  
    if session[:period].nil? || 
        ! session[:period].include?(@worktime.work_date)
      session[:period] = Period.weekFor(@worktime.work_date)
    end
    redirect_to :controller => 'evaluator', 
                :action => 'details', 
                :evaluation => eval, 
                :category_id => @user.id
  end

  def createDefaultWorktime
    @worktime = Worktime.new
    @worktime.from_start_time = Time.now.change(:hour => 8)
    @worktime.report_type = Worktime::TYPE_HOURS_DAY
    period = session[:period]
    if period != nil && period.length == 1
      @worktime.work_date = period.startDate
    end  
  end
  
  def setWorktimeAccounts
    @accounts = @worktime.absence? ? Absence.list : @user.projects 
  end
  
  def setWorktimeParams
    begin
      @worktime.attributes = params[:worktime]
    # Catch the exception from AR::Base
    rescue ActiveRecord::MultiparameterAssignmentErrors => ex
      # Iterarate over the exceptions and remove the invalid field components from the input
      ex.errors.each { |err| params[:worktime].delete_if { |key, value| key =~ /^#{err.attribute}/ } }
      # Recreate the Model with the bad input fields removed
      @worktime.attributes = params[:worktime]
      # remove manually as @worktime already had a valid work_date, we want an error to be thrown
      @worktime.work_date = nil     
    end
  end

end
