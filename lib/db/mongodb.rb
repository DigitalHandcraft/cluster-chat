require 'bundler/setup'
require 'mongo'

class MongoConnector
  attr_accessor :db
  def initialize(addr, db_name)
    Mongo::Logger.logger = ::Logger.new('mongo.log')
    @client = Mongo::Client.new("mongodb://#{addr}/#{db_name}")
    @db = @client.database
  end

  def get_table_names
    @db.collection_names
  end

  def insert(coll, data)
    res = @db[coll].insert_one data
    res.documents[0]
  end

  def update(coll, cond, data)
    @db[coll].update_many cond, {'$set': data}
  end

  def select(coll, cond)
    @db[coll].find(cond).to_a
  end

  def delete(coll, cond)
    @db[coll].delete_many cond
  end

  def get_objid_from_time(t)
    BSON::ObjectId.from_time t
  end
end
