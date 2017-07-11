require "pg"

class DatabasePersistence
  attr_accessor :error, :success
  
  def initialize(logger)
    @db = PG.connect(dbname: 'todos')
      if Sinatra::Base.production?
        pg.connect(ENV['DATABASE_URL'])
      else
        PG.connect(dbname: "todos")
      end
    @logger = logger
  end
  
  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT l.id, l.name, t.name AS todo_name, t.id AS todo_id, completed FROM lists l LEFT JOIN todo t ON t.list_id = l.id WHERE l.id = $1"
    result = query(sql, id)
    todo = result.map {|tuple| {id: tuple['todo_id'].to_i, name: tuple['todo_name'],
                                completed: tuple['completed'] == 't'}}
    tuple = result.first
    {id: tuple['id'].to_i, name: tuple['name'], todos: todo}
  end
  
  def all_lists
    sql = "SELECT * FROM lists"
    result = query(sql)
    result.map do |tuple|
      todo_result = find_todos_for_list(tuple['id'])
      {id: tuple['id'].to_i, name: tuple['name'], todos: todo_result}
    end
  end
  
  def new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1)"
    query(sql, list_name)
  end
  
  def delete_list(id)
    sql = "DELETE FROM lists WHERE id = $1"
    query(sql, id)
  end
  
  def update_list_name(id, list_name)
    query("UPDATE lists SET name = $1 WHERE id = $2", list_name, id)
  end
  
  def create_new_todo(id, text)
    query("INSERT INTO todo (list_id, name) VALUES ($1, $2)", id, text)
  end
  
  def delete_todo_from_list(list_id, todo_id)
    query("DELETE FROM todo WHERE list_id = $1 AND id = $2", list_id, todo_id)
  end
  
  def update_todo_status(list_id, todo_id, new_status)
    sql ="UPDATE todo SET completed = $1 WHERE list_id = $2 AND id = $3"
    query(sql, new_status, list_id, todo_id)
  end
  
  def mark_all_todos_complete(list_id)
    query("UPDATE todo SET completed = true WHERE list_id = $1", list_id)
  end
  
  private
  
  def find_todos_for_list(id)
    sql = "SELECT id, name, completed FROM todo WHERE list_id = $1"
    result = query(sql, id)
    result.map { |todo| {id: todo['id'].to_i, name: todo['name'],
                        completed: todo['completed'] == 't'}}
  end

end