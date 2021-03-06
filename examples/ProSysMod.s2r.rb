#!/usr/bin/env ruby
require 'spread2rdf'

module Spread2RDF
  Schema.definition 'ProSysMod-Data' do

    namespaces(
      PSM:    'http://homepages.uni-paderborn.de/fbauer/ProSysMod/ontology#',
      QUDT:   'http://qudt.org/schema/qudt#'
    )

    machine_classifications = %w[
        PSM-Lagermittel-Klassifikation.ttl
        PSM-Foerdermittel-Klassifikation.ttl
    ]

    worksheet 'RDF-Export', name: :Settings do
      NS[:Base]                = cell(:B7)
      NS[:PSM_MaterialElement] = cell(:B9)
      NS[:PSM_Process]         = cell(:B10)
      NS[:PSM_Resource]        = cell(:B11)
      NS[:PSM_Characteristic]  = cell(:B12)
      NS[:PSM_Quality]         = cell(:B13)
    end

    template :default_columns do
      column :name, predicate: RDFS.label
      column :uri
    end

    template :quantity_mapping do |value|
      statements(
          [ object, QUDT.numericValue, value.to_i ],
          [ object, QUDT.unit, object_of_column(:unit) ] )
    end

    template :parameter_block do
      column :name,        predicate: PSM.characteristic,
                           object:    { language: 'de',
                                        from: {
                                          worksheet:   :Characteristics,
                                          data_source: 'PSM-Merkmale.ttl' } }
      #column :description, predicate: RDFS.comment
      column :quality,     predicate: PSM.parameterQuality,
                           object:    { from: {
                                          worksheet:   :Qualities,
                                          data_source: 'PSM-Qualitaeten.ttl' } }
      column :min,   predicate: PSM.parameterMinQuantity,
                     object:    { uri: :bnode, type: QUDT.QuantityValue },
                     &quantity_mapping
      column :exact, predicate: PSM.parameterQuantity,
                     object:    { uri: :bnode, type: QUDT.QuantityValue },
                     &quantity_mapping
      column :max,   predicate: PSM.parameterMaxQuantity,
                     object:    { uri: :bnode, type: QUDT.QuantityValue },
                     &quantity_mapping
      column :unit, object: unit_mapping
      column :valuation_method, predicate: PSM.usedByValuationMethod,
                                object:    { from: :ValuationMethods }
    end

    worksheet 'Merkmale',
              name: :Characteristics,
              start:   :B5,
              subject: { uri: { namespace: PSM_Characteristic },
                         type: PSM.Characteristic
              } do
      column :name_de, predicate: RDFS.label, object: { language: 'de' }
      column :name_en, predicate: RDFS.label, object: { language: 'en' }
      column :uri
    end

    worksheet 'Qualitaeten',
              name:    :Qualities,
              start:   :B5,
              subject: { uri: { namespace: PSM_Quality },
                         type:             RDF::RDFS.Class,
                         #sub_class_of:     PSM.Quality
              } do
      include :default_columns
      column :elements, predicate: RDF.type, object: { uri: { namespace: PSM_Quality } },
                        statement: :inverse do |value|
        statement( object, RDF::RDFS.label, value)
      end
    end

    worksheet 'Services',
              start:   :B5,
              subject: { type: PSM.Service } do
      include :default_columns
    end

    worksheet 'Bewertungsmethoden',
              name:    :ValuationMethods,
              start:   :B5,
              subject: { type: PSM.ValuationMethod } do
      include :default_columns
    end

    worksheet 'MaterialelementeKlassen',
              name:    :MaterialElementClasses,
              start:   :B5,
              subject: { uri: { namespace: PSM_MaterialElement },
                         type:         RDF::RDFS.Class,
                         sub_class_of: PSM.MaterialElement
              } do
      include :default_columns

      column :sub_class_of,     predicate: RDFS.subClassOf,
                                object:    { from: :MaterialElementClasses }
      column_block :parameter,  subject: { uri: :bnode, type: PSM.Parameter },
                                predicate: PSM.materialParameter,
                                statement: :restriction,
                                &parameter_block
    end

    worksheet 'Materialelemente',
              name:   :MaterialElements,
              start:  :B5,
              subject: { uri: { namespace: PSM_MaterialElement },
                         type: PSM.MaterialElement
              } do
      include :default_columns

      column :type,             predicate: RDF.type,
                                object:    { from: :MaterialElementClasses }
      column_block :parameter,  subject: { uri: :bnode, type: PSM.Parameter },
                   predicate: PSM.materialParameter,
                   &parameter_block
    end

    worksheet 'ProzesseKlassen',
              name:  :ProcessClasses,
              start: :B5,
              subject: { uri: { namespace: PSM_Process },
                         type:         RDF::RDFS.Class,
                         sub_class_of: PSM.Process
              } do
      include :default_columns

      column :sub_class_of,     predicate: RDFS.subClassOf,
                                object:    { from: :ProcessClasses }
      column :input,            predicate: PSM.input,
                                object: { from: :MaterialElements },
                                statement: :restriction # TODO: Should we allow here Classes also, for which a subProperty with a restricted rdfs:range is introduced
      column :output,           predicate: PSM.ouput,
                                object: { from: :MaterialElements },
                                statement: :restriction # TODO: dto.
      column_block :parameter,  subject: { uri: :bnode, type: PSM.Parameter },
                                predicate: PSM.processParameter,
                                statement: :restriction,
                                &parameter_block
    end

    worksheet 'Prozesse',
              name:  :Processes,
              start: :B5,
              subject: { uri:  { namespace: PSM_Process },
                         type: PSM.Process
              } do
      include :default_columns

      column :type,             predicate: RDF.type,
                                object:    { from: :ProcessClasses }
      column :input,            predicate: PSM.input,
                                object: { from: :MaterialElements }
      column :output,           predicate: PSM.output,
                                object: { from: :MaterialElements }
      column_block :parameter,  subject: { uri: :bnode, type: PSM.Parameter },
                                predicate: PSM.processParameter,
                                &parameter_block
    end

    worksheet 'WerkzeugeKlassen',
              name:   :ToolClasses,
              start:  :B5,
              subject: { uri: { namespace: PSM_Resource },
                         type:         RDF::RDFS.Class,
                         sub_class_of: PSM.Tool
              } do
      include :default_columns

      column :sub_class_of,     predicate: RDFS.subClassOf,
                                object:    { from: :ToolClasses }
      column_block :parameter,  subject: { uri: :bnode, type: PSM.Parameter },
                                predicate: PSM.resourceParameter,
                                statement: :restriction,
                                &parameter_block
    end

    worksheet 'Werkzeuge',
              name:   :Tools,
              start:  :B5,
              subject: { uri: { namespace: PSM_Resource },
                         type: PSM.Tool
              } do
      include :default_columns

      column :type,             predicate: RDF.type,
                                object:  { from: :ToolClasses }
      column_block :parameter,  subject: { uri: :bnode, type: PSM.Parameter },
                                predicate: PSM.resourceParameter,
                                &parameter_block
    end

    worksheet 'VorrichtungenKlassen',
              name:   :DeviceClasses,
              start:  :B5,
              subject: { uri: { namespace: PSM_Resource },
                         type:         RDF::RDFS.Class,
                         sub_class_of: PSM.Device
              } do
      include :default_columns

      column :sub_class_of,     predicate: RDFS.subClassOf,
                                object:    { from: :DeviceClasses }
      column_block :parameter,  subject: { uri: :bnode, type: PSM.Parameter },
                                predicate: PSM.resourceParameter,
                                statement: :restriction,
                                &parameter_block
    end

    worksheet 'Vorrichtungen',
              name:   :Devices,
              start:  :B5,
              subject: { uri: { namespace: PSM_Resource },
                         type: PSM.Device
              } do
      include :default_columns

      column :type,             predicate: RDF.type,
                                object:  { from: :DeviceClasses }
      column_block :parameter,  subject: { uri: :bnode, type: PSM.Parameter },
                                predicate: PSM.resourceParameter,
                                &parameter_block
    end

    worksheet 'WerkerKlassen',
              name:   :WorkerClasses,
              start:  :B5,
              subject: { uri: { namespace: PSM_Resource },
                         type:         RDF::RDFS.Class,
                         sub_class_of: PSM.Worker
              } do
      include :default_columns

      column :sub_class_of,       predicate: RDFS.subClassOf,
                                  object:    { from: :WorkerClasses }
      column :supported_services, predicate: PSM.supportsService,
                                  object:    { from: :Services },
                                  statement: :restriction
      column_block :parameter,    subject: { uri: :bnode, type: PSM.Parameter },
                                  predicate: PSM.resourceParameter,
                                  statement: :restriction,
                                  &parameter_block
    end

    worksheet 'Werker',
              name:   :Workers,
              start:  :B5,
              subject: { uri: { namespace: PSM_Resource },
                         type: PSM.Worker
              } do
      include :default_columns

      column :type,               predicate: RDF.type,
                                  object:  { from: :WorkerClasses }
      column :supported_services, predicate: PSM.supportsService,
                                  object:    { from: :Services }
      column_block :parameter,    subject: { uri: :bnode, type: PSM.Parameter },
                                  predicate: PSM.resourceParameter,
                                  &parameter_block
    end

    worksheet 'MaschinenKlassen',
              name:   :MachineClasses,
              start:  :B5,
              subject: { uri: { namespace: PSM_Resource },
                         type:         RDF::RDFS.Class,
                         sub_class_of: PSM.Machine
              } do
      include :default_columns

      column :sub_class_of,     predicate: RDFS.subClassOf,
                                object: { from: {
                                       worksheet: :MachineClasses,
                                       data_source: machine_classifications } }

      column :tools     # ignored
      column :devices   # ignored
      column :workers   # ignored
      column :required_services, predicate: PSM.requiresService,
                                 object:    { from: :Services },
                                 statement: :restriction
      column :processes # ignored

      column_block :parameter,  subject: { uri: :bnode, type: PSM.Parameter },
                                predicate: PSM.resourceParameter,
                                statement: :restriction,
                                &parameter_block
    end

    worksheet 'Maschinen',
                name:     :Machines,
                start:    :B5,
                subject: { uri:  { namespace: PSM_Resource },
                           type: PSM.Machine
                        } do
      include :default_columns

      column :type,              predicate: RDFS.subClassOf,
                                 object: { from: {
                                       worksheet:   :MachineClasses,
                                       data_source: machine_classifications } }

      column :tools,             predicate: PSM.hasTool,
                                 object:    { from: :Tools }
      column :devices,           predicate: PSM.hasDevice,
                                 object:    { from: :Devices }
      column :workers,           predicate: PSM.hasWorker,
                                 object:    { from: :Workers }
      column :required_services, predicate: PSM.requiresService,
                                 object:    { from: :Services }
      column :processes,         predicate: PSM.realizeProcess,
                                 object:    { from: :Processes }

      column_block :parameter,   subject: { uri: :bnode, type: PSM.Parameter },
                                 predicate: PSM.resourceParameter,
                                 &parameter_block
    end

  end
  Schema.execute
end
