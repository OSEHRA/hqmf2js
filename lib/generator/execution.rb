module HQMF2JS
  module Generator
    class Execution


      def self.quoted_string_array_or_null(arr)
        if arr
          quoted = arr.map {|e| "\"#{e}\""}
          "[#{quoted.join(',')}]"
        else
          "null"
        end
      end

      # Note that the JS returned by this function is not included when using the in-browser
      # debugger. See app/views/measures/debug.js.erb for the in-browser equivalent.
      def self.measure_js(hqmf_document, population_index, options)
        logic(hqmf_document, population_index, options)
      end

      def self.logic(hqmf_document, population_index=0, options)

        value_sets=options[:value_sets]
        episode_ids=options[:episode_ids]
        continuous_variable=options[:continuous_variable]
        force_sources=options[:force_sources]
        custom_functions=options[:custom_functions]
        check_crosswalk=options[:check_crosswalk]

        gen = HQMF2JS::Generator::JS.new(hqmf_document)
        codes = HQMF2JS::Generator::CodesToJson.from_value_sets(value_sets) if value_sets
        force_sources = force_sources

        if check_crosswalk
          crosswalk_check = "result = hqmf.SpecificsManager.maintainSpecifics(new Boolean(result.isTrue() && patient_api.validateCodeSystems()), result);"
          crosswalk_instrument = "instrumentTrueCrosswalk(hqmfjs);"
        end


        "
        var effective_date = <%= effective_date %>;
        var enable_logging = <%= enable_logging %>;
        var enable_rationale = <%= enable_rationale %>;
        var short_circuit = <%= short_circuit %>;

        hqmfjs.effective_date = effective_date;



        #{gen.to_js(population_index, codes, force_sources)}

        var occurrenceId = #{quoted_string_array_or_null(episode_ids)};



        var variables = function() {
          if (Logger.enable_rationale) {
            return executeIfAvailable(hqmfjs.VARIABLES, patient_api);
          }
        }

        var executeIfAvailable = function(optionalFunction, patient_api) {
          if (typeof(optionalFunction)==='function') {
            result = optionalFunction(patient_api);
            #{crosswalk_check}
            return result;
          } else {
            return false;
          }
        }
        #{crosswalk_instrument}
        if (typeof Logger != 'undefined') {
            // clear out logger
            Logger.logger = [];
            Logger.rationale={};
            if (typeof short_circuit == 'undefined') short_circuit = true;

            // turn on logging if it is enabled
            if (enable_logging || enable_rationale) {
              injectLogger(hqmfjs, enable_logging, enable_rationale, short_circuit);
            } else {
              Logger.enable_rationale = false;
              Logger.short_circuit = short_circuit;
            }
          }

        hqmfjs.calculate = function(patient_api, effective_date, correlation_id) {

          var population = function() {
            return executeIfAvailable(hqmfjs.#{HQMF::PopulationCriteria::IPP}, patient_api);
          }
          var stratification = null;
          if (hqmfjs.#{HQMF::PopulationCriteria::STRAT}) {
            stratification = function() {
              return hqmf.SpecificsManager.setIfNull(executeIfAvailable(hqmfjs.#{HQMF::PopulationCriteria::STRAT}, patient_api));
            }
          }
          var denominator = function() {
            return executeIfAvailable(hqmfjs.#{HQMF::PopulationCriteria::DENOM}, patient_api);
          }
          var numerator = function() {
            return executeIfAvailable(hqmfjs.#{HQMF::PopulationCriteria::NUMER}, patient_api);
          }
          var exclusion = function() {
            return executeIfAvailable(hqmfjs.#{HQMF::PopulationCriteria::DENEX}, patient_api);
          }
          var denexcep = function() {
            return executeIfAvailable(hqmfjs.#{HQMF::PopulationCriteria::DENEXCEP}, patient_api);
          }
          var msrpopl = function() {
            #{msrpopl_function(custom_functions, population_index)}
          }
          var msrpoplex = function() {
            return executeIfAvailable(hqmfjs.#{HQMF::PopulationCriteria::MSRPOPLEX}, patient_api);
          }
          var observ = function(specific_context) {
            #{observation_function(custom_functions, population_index)}
          }

          OidDictionary = hqmfjs.OidDictionary;
          hqmfjs.initializeSpecifics(patient_api, hqmfjs);
          hqmfjs.setEffectiveDate(effective_date);
          if (typeof Logger != 'undefined') {
            Logger.logger = [];
            Logger.rationale={};
            // resetting these here because they could have been overridden by a different measure execution
            // keep in mind that this is based off of how the data criteria was processed to begin with and
            // we are simply setting the global Logger to those values for consistency
            Logger.enable_logging = enable_logging;
            Logger.enable_rationale = enable_rationale;
            Logger.short_circuit = short_circuit;
          }
          try {
           return map(hqmfjs,patient_api, population, denominator, numerator, exclusion, denexcep, msrpopl, msrpoplex, observ, occurrenceId,#{continuous_variable},stratification,variables, correlation_id);
          } catch(err) {
            print(err.stack);
            throw err;
          }
        }

        "
      end

      def self.observation_function(custom_functions, population_index)

        result = "
          var observFunc = hqmfjs.#{HQMF::PopulationCriteria::OBSERV}
          if (typeof(observFunc)==='function')
            return observFunc(patient_api, specific_context);
          else
            return [];"

        if (custom_functions && custom_functions[HQMF::PopulationCriteria::OBSERV])
          result = "return #{custom_functions[HQMF::PopulationCriteria::OBSERV]}(patient_api, hqmfjs)"
        end

        result

      end

      def self.msrpopl_function(custom_functions, population_index)
        if (custom_functions && custom_functions[HQMF::PopulationCriteria::MSRPOPL])
          "return #{custom_functions[HQMF::PopulationCriteria::MSRPOPL]}(patient_api, hqmfjs)"
        else
          "return executeIfAvailable(hqmfjs.#{HQMF::PopulationCriteria::MSRPOPL}, patient_api);"
        end
      end

    end
  end
end
