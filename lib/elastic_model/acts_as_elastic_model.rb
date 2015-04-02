module ActsAsElasticModel

  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    # load the index definition, if it exists
    index_path = File.join(Rails.root, "app/es_indices/#{ name.downcase }_index.rb")
    if File.exists?(index_path)
      ActiveSupport::Dependencies.require_or_load(index_path)
    end

    # set the index name based on the environment, useful for specs
    index_name [ Rails.env, model_name.collection ].join('_')

    after_commit on: [:create, :update] do
      elastic_index!
    end

    after_commit on: [:destroy] do
      elastic_delete!
    end

    class << self
      def elastic_search(options = {})
        __elasticsearch__.search(ElasticModel.search_hash(options))
      end

      def elastic_paginate(options={})
        options[:page] ||= 1
        # 20 was the default of Sphinx, which Elasticsearch is replacing for us
        options[:per_page] ||= 20
        options[:fields] ||= :id
        result = elastic_search(options).
          per_page(options[:per_page]).page(options[:page])
        ElasticModel.result_to_will_paginate_collection(result)
      end

      # standard way to bulk index instances. Called without options it will
      # page through all instances 1000 at a time (default for find_in_batches)
      # You can also send options, including scope:
      #   Place.elastic_index!(batch_size: 20)
      #   Place.elastic_index!(scope: Place.where(id: [1,2,3,...]), batch_size: 20)
      def elastic_index!(options = { })
        filter_scope = options.delete(:scope)
        scope = (filter_scope && filter_scope.is_a?(ActiveRecord::Relation)) ?
          filter_scope : self.all
        if self.respond_to?(:load_for_index)
          scope = scope.load_for_index
        end
        scope.find_in_batches(options) do |batch|
          bulk_index(batch)
        end
        __elasticsearch__.refresh_index! if Rails.env.test?
      end

      private

      # standard wrapper for bulk indexing with Elasticsearch::Model
      def bulk_index(batch)
        begin
          __elasticsearch__.client.bulk({
            index: __elasticsearch__.index_name,
            type: __elasticsearch__.document_type,
            body: prepare_for_index(batch)
          })
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
          Rails.logger.error "[Error] elastic_index! failed: #{ e }"
          Rails.logger.error "Backtrace:\n#{ e.backtrace[0..30].join("\n") }\n..."
        end
      end

      # map each instance into its indexable form with `as_indexed_json`
      def prepare_for_index(batch)
        # some models need some extra preparation for faster indexing.
        # I tried to just define a custom `prepare_for_index` in
        # Taxon, but this one from this module took precedence
        if self.respond_to?(:prepare_batch_for_index)
          prepare_batch_for_index(batch)
        end
        batch.map do |obj|
          { index: { _id: obj.id, data: obj.as_indexed_json } }
        end
      end
    end

    def elastic_index!
      begin
        __elasticsearch__.index_document
        # in the test ENV, we will need to wait for changes to be applied
        self.class.__elasticsearch__.refresh_index! if Rails.env.test?
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
        Rails.logger.error "[Error] elastic_index! failed: #{ e }"
        Rails.logger.error "Backtrace:\n#{ e.backtrace[0..30].join("\n") }\n..."
      end
    end

    def elastic_delete!
      __elasticsearch__.delete_document
      # in the test ENV, we will need to wait for changes to be applied
      self.class.__elasticsearch__.refresh_index! if Rails.env.test?
    end

    private

    # usually called within as_indexed_json to make sure the instance
    # has all associations it needs. It is fast to check even if the
    # associations have been loaded. This should help minimize the number
    # of sql calls needed for non-bulk indexing
    def preload_for_elastic_index
      if self.class.respond_to?(:load_for_index)
        self.class.preload_associations(self,
          self.class.load_for_index.values[:includes])
      end
    end

  end
end
