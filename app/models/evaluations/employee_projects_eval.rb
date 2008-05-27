class EmployeeProjectsEval < ProjectsEval

  DIVISION_METHOD   = :alltime_projects
  CATEGORY_REF      = :employee_id   
  ATTENDANCE        = true   
  SUB_EVALUATION    = nil
  SUB_PROJECTS_EVAL = 'employeesubprojects'
  
  def initialize(employee_id)
    super(Employee.find(employee_id))
  end  
  
  def for?(user)
    self.category == user
  end
  
  def division_supplement(user)
    return [[:add_time_link, ''], [:complete_link, '']] if self.for? user
    []
  end
  
  def employee_id
    category.id
  end
  
  def sub_projects_evaluation(project = nil)
    self.class::SUB_PROJECTS_EVAL + employee_id.to_s if project && project.children?
  end

  # default would turn Employee.alltime_projects too complicated
  def set_division_id(division_id = nil)
    return if division_id.nil?
    @division = Project.find(division_id.to_i)
  end
end
