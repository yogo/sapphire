module SchemasHelper
  def property_types_opts
    types = Yogo::Collection::Property::COMMON_PROPERTIES.map(&:to_s).zip(
      Yogo::Collection::Property::COMMON_PROPERTIES.map{|p| "Yogo::Collection::Property::" + p.to_s}
    ) + [ 
      ['Prompt', 'controlled_vocabulary'],
      ['Link', 'association'],
      ['Link List', 'list_association']
    ]

    types.map do |type|
      key = case type[0]
      when 'String'   then 'Short Text'
      when 'Text'     then 'Long Text'
      when 'Boolean'  then 'True/False'
      when 'Integer'  then 'Whole Number'
      when 'Float'    then 'Decimal Number'
      when 'DateTime' then 'Date & Time'
      else
        type[0]
      end
      [key,type[1]]
    end

  end
  
  def position_opts(coll)
    len = coll.schema.count 
    (1..len+1).to_a.zip((0..len)).reverse
  end

  def controlled_vocabulary_opts
    project_ids= current_user.memberships(:fields=>[:project_id]).map{|m| m.project_id}.uniq
    my_collection_ids = Yogo::Collection::Data.all(:project_id=> project_ids, :category=>"Controlled Vocabulary").map{|c| c.id}
    public_project_ids = Yogo::Project.all(:private=>false).map{|p| p.id} - project_ids
    public_collection_ids = Yogo::Collection::Data.all(:project_id=> public_project_ids, :category=>"Controlled Vocabulary").map{|c| c.id}
    public_collection_ids = (public_collection_ids + Yogo::Collection::Data.all(:private=>false, :category=>"Controlled Vocabulary").map{|c| c.id}).uniq
    all_collection_ids = (public_collection_ids + my_collection_ids).uniq
    collections = Yogo::Collection::Data.all(:id => all_collection_ids)
    collections.schema.map{|s| [s.data_collection.name + " > " + s.name, s.id] }
  end
  
  def association_opts
    project_ids= current_user.memberships(:fields=>[:project_id]).map{|m| m.project_id}.uniq
    my_collection_ids = Yogo::Collection::Data.all(:project_id=> project_ids).map{|c| c.id}
    public_project_ids = Yogo::Project.all(:private=>false).map{|p| p.id} - project_ids
    public_collection_ids = Yogo::Collection::Data.all(:project_id=> public_project_ids).map{|c| c.id}
    public_collection_ids = (public_collection_ids + Yogo::Collection::Data.all(:private=>false).map{|c| c.id}).uniq
    all_collection_ids = (public_collection_ids + my_collection_ids).uniq
    collections = Yogo::Collection::Data.all(:id => all_collection_ids)
    collections.schema.map{|s| [s.data_collection.name + " > " + s.name, s.id] }
  end
  
end
