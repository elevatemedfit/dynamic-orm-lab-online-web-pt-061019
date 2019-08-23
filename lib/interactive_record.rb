require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize #creates "students" from Student.
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')" #table_name = students

    table_info = DB[:conn].execute(sql) #table_info = an array of hashes with all data.
    column_names = []
    table_info.each do |row|#select the name in each row and place into column_names.
      column_names << row["name"]# column_names = name=> id, name=>name, name=>grade |id|name|grade| columns
    end
    column_names.compact #["id","name","grade"] for the "students" table_name
  end

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    # table_name_for_insert = "students',
    #column_names_for_insert w/o "id", "name, grade" ===remember, id is set automatically.
    # values_for_insert = "'1', 'Sam', '11'".
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name #Student => "students"
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|#self.class because we use a class method in an instance method.
      values << "'#{send(col_name)}'" unless send(col_name).nil?
      #values = ["'Sam'", "'11'"]
    end
    values.join(", ")# converts to "'Sam','11'"
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    # outputs "name,grade" again, no id needed.
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
    DB[:conn].execute(sql, name)
  end

  def self.find_by(attribute_hash)
    value = attribute_hash.values.first
    attribute_value = value.class == Fixnum ? value : "'#{value}'"

    sql = "SELECT * FROM #{self.table_name} WHERE #{attribute_hash.keys.first} = #{attribute_value}"
    DB[:conn].execute(sql)
  end

end
