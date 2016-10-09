require 'bundler/setup'
require 'db/mongodb'

class ChatCore
  attr_accessor :db
  def initialize
    @db = MongoConnector.new 'arch.rk0der.net', 'clchat'
    unless @db.get_table_names.include? 'counter'
      @db.insert 'counter', {col_name: 'users', seq: 0}
      @db.insert 'counter', {col_name: 'statuses', seq: 0}
      @db.insert 'counter', {col_name: 'contexts', seq: 0}
    end
  end

  def join ctx, name
    arr = @db.select 'users', {name: name, ctx_id: ctx}
    if arr.empty?
      id = get_next_id 'users'
      data = {
        user_id: id,
        ctx_id: ctx,
        name: name,
        created_at: Time.now.utc
      }
      @db.insert 'users', data
      data
    else
      arr[0]
    end
  end

  def send user_id, text
    arr = @db.select 'users', {user_id: user_id}
    return if arr.empty?

    usr = arr[0]
    id = get_next_id 'statuses'
    data = {
      status_id: id,
      user_id: user_id,
      ctx_id: usr[:ctx_id],
      text: text,
      created_at: Time.now.utc
    }
    res = @db.insert 'statuses', data
    {status: res, data:data}
  end

  def leave ctx, name
    unless @db.select('users', {name: name, ctx_id: ctx}).empty?
      @db.delete 'users', {name: name, ctx_id: ctx}
    end
  end

  def load_statuses ctx, time0, time1
    dummy0 = @db.get_objid_from_time(time0)
    dummy1 = @db.get_objid_from_time(time1)
    @db.select('statuses', {ctx_id: ctx, "_id": {"$gte": dummy0, "$lte": dummy1}})
  end

  def get_next_id col
    arr = @db.select 'counter', {col_name: col}
    ret = arr[0][:seq].to_i
    @db.update 'counter', {col_name: col}, {seq:ret+1}
    ret
  end
end
