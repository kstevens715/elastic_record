require 'helper'

class ElasticRecord::ModelTest < MiniTest::Test
  class InheritedModel < Widget
  end

  def test_elastic_connection
    connection = Widget.elastic_connection

    assert_equal ElasticRecord::Config.servers, connection.servers
    assert_equal ElasticRecord::Config.connection_options.symbolize_keys, connection.options
  end

  def test_elastic_index
    index = Widget.elastic_index

    assert_equal Widget, index.model
  end

  def test_elastic_index_inheritence
    refute_equal Widget.elastic_index.object_id, InheritedModel.elastic_index.object_id
    refute_equal Widget.doctype.object_id, InheritedModel.doctype.object_id
  end
end
