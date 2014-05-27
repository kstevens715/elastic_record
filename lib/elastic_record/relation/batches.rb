module ElasticRecord
  class Relation
    class ScanSearch
      def initialize(model, scroll_id, options = {})
        @model     = model
        @scroll_id = scroll_id
        @options   = options
      end

      def request_more_ids
        json = @model.elastic_index.scroll(@scroll_id, keep_alive)
        json['hits']['hits'].map { |hit| hit['_id'] }
      end

      def keep_alive
        @options[:keep_alive] || (raise "Must provide a :keep_alive option")
      end

      def requested_batch_size
        @options[:batch_size]
      end
    end

    module Batches
      def find_each(options = {})
        find_in_batches(options) do |records|
          records.each { |record| yield record }
        end
      end

      def find_in_batches(options = {})
        find_ids_in_batches(options) do |ids|
          yield klass.find(ids)
        end
      end

      def find_ids_in_batches(options = {}, &block)
        scan_search = create_scan_search(options)

        while (hit_ids = scan_search.request_more_ids).any?
          hit_ids.each_slice(scan_search.requested_batch_size, &block)
        end
      end

      def reindex
        relation.find_in_batches do |batch|
          elastic_index.bulk_add(batch)
        end
      end

      def create_scan_search(options = {})
        options[:batch_size] ||= 100
        options[:keep_alive] ||= ElasticRecord::Config.scroll_keep_alive

        search_options = {search_type: 'scan', size: options[:batch_size], scroll: options[:keep_alive]}
        json = klass.elastic_index.search(as_elastic, search_options)

        ElasticRecord::Relation::ScanSearch.new(klass, json['_scroll_id'], options)
      end
    end
  end
end
