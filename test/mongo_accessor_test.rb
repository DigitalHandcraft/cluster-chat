$LOAD_PATH << 'lib'

require 'test/unit'
require 'db/mongo_accessor'

class TestMongoAccessor < Test::Unit::TestCase
  def setup
    @db = MongoAccessor.new('arch.rk0der.net', 'clchat')
  end

  def test_get_table_names
    arr = @db.get_table_names
    exp = ['users', 'statuses', 'contexts']
    exp.each do |name|
      assert arr.include? name
    end
  end
end
