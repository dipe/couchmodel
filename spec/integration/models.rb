require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "couch_model"))

CouchModel::Configuration.design_directory = File.join File.dirname(__FILE__), "design"

DATABASE = {
  :url                => "http://localhost:5984/test",
  :create_if_missing  => true,
  :delete_if_exists   => true,
  :push_design        => true
}.freeze unless defined?(DATABASE)

class User < CouchModel::Base

  setup_database DATABASE

  key_accessor :username
  key_accessor :email,    :default => "no email"
  key_accessor :birthday, :type => :date
  key_accessor :lunch,    :type => :time

  has_many :memberships,
           :class_name  => "Membership",
           :view_name   => :by_user_id_and_created_at,
           :query       => lambda { |created_at| { :startkey => [ self.id, (created_at || nil) ], :endkey => [ self.id, (created_at || { }) ] } }

end

class Membership < CouchModel::Base

  setup_database DATABASE

  key_accessor :created_at, :type => :time

  belongs_to :user, :class_name => "User"

end

def create_users_and_memberships
  @user_one = User.create :username => "user one",
                          :birthday => Date.parse("2000-07-07"),
                          :lunch    => Time.parse("2010/10/21 12:13:14")

  @user_two = User.create :username => "user two",
                          "birthday(1i)" => "2010",
                          "birthday(2i)" => "2",
                          "birthday(3i)" => "20",
                          "lunch(1i)" => "2010",
                          "lunch(2i)" => "10",
                          "lunch(3i)" => "21",
                          "lunch(4i)" => "12",
                          "lunch(5i)" => "13",
                          "lunch(6i)" => "14"

  @membership_one = Membership.create :created_at => Time.parse("2010-07-07"),
                                      :user => @user_one

  @membership_two = Membership.create :created_at => Time.parse("2010-07-07"),
                                      :user => @user_two
end
