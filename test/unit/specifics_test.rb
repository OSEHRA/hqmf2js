require_relative '../test_helper'
require 'hquery-patient-api'

class SpecificsTest < Test::Unit::TestCase
  
  def setup
    @context = get_js_context(HQMF2JS::Generator::JS.library_functions)
    test_initialize_js = 
    "
      Specifics.initialize({'id':'OccurrenceAEncounter', 'type':'Encounter', 'function':'SourceOccurrenceAEncounter'},{'id':'OccurrenceBEncounter', 'type':'Encounter', 'function':'SourceOccurrenceBEncounter'})
      var patient = {}
      hqmfjs.SourceOccurrenceAEncounter = function(patient) {
        return [{'id':1},{'id':2},{'id':3},{'id':4},{'id':5}]
      }
      hqmfjs.SourceOccurrenceBEncounter = function(patient) {
        return [{'id':1},{'id':2},{'id':3},{'id':4},{'id':5}]
      }
    "
    @context.eval(test_initialize_js)
  end


  def test_specifics_initialized_proper
    
    @context.eval('Specifics.KEY_LOOKUP[0]').must_equal 'OccurrenceAEncounter'
    @context.eval('Specifics.KEY_LOOKUP[1]').must_equal 'OccurrenceBEncounter'
    @context.eval('Specifics.FUNCTION_LOOKUP[0]').must_equal 'SourceOccurrenceAEncounter'
    @context.eval('Specifics.FUNCTION_LOOKUP[1]').must_equal 'SourceOccurrenceBEncounter'
    @context.eval("Specifics.TYPE_LOOKUP['Encounter'].length").must_equal 2
    @context.eval("Specifics.TYPE_LOOKUP['Encounter'][0]").must_equal 0
    @context.eval("Specifics.TYPE_LOOKUP['Encounter'][1]").must_equal 1
  end
  
  def test_specifics_row_union
    
    union_rows = "
      var row1 = new Row({'OccurrenceAEncounter':{'id':1}});
      var specific1 = new Specifics([row1]);
      var row2 = new Row({'OccurrenceBEncounter':{'id':2}});
      var specific2 = new Specifics([row2]);
      result = specific1.union(specific2);
      result.rows.length;
    "
    
    @context.eval(union_rows).must_equal 2
    @context.eval("result.rows[0].values[0].id").must_equal 1
    @context.eval("result.rows[0].values[1]").must_equal '*'
    @context.eval("result.rows[1].values[0]").must_equal '*'
    @context.eval("result.rows[1].values[1].id").must_equal 2
    
  end

  def test_row_creation
    
    rows = "
      var row1 = new Row({'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row({'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row({});
    "
    
    @context.eval(rows)
    @context.eval("row1.values[0].id").must_equal 1
    @context.eval("row1.values[1]").must_equal '*'
    @context.eval("row2.values[0]").must_equal '*'
    @context.eval("row2.values[1].id").must_equal 2
    @context.eval("row3.values[0].id").must_equal 1
    @context.eval("row3.values[1].id").must_equal 2
    @context.eval("row4.values[0]").must_equal '*'
    @context.eval("row4.values[1]").must_equal '*'
  end
    

  def test_row_match
    rows = "
      var row1 = new Row({});
    "
    @context.eval(rows)
    @context.eval("Row.match('*', {'id':1}).id").must_equal 1
    @context.eval("Row.match({'id':2}, '*').id").must_equal 2
    @context.eval("Row.match({'id':1}, {'id':1}).id").must_equal 1
    @context.eval("Row.match('*', '*')").must_equal '*'
    @context.eval("typeof(Row.match({'id':3}, {'id':2})) === 'undefined'").must_equal true
    
  end
  
  def test_row_intersect
    
    rows = "
      var row1 = new Row({'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row({'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row({'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':2}});
      var row5 = new Row({'OccurrenceAEncounter':{'id':3},'OccurrenceBEncounter':{'id':3}});
      var row6 = new Row({});
    "
    
    @context.eval(rows)
    @context.eval("row1.intersect(row2).values[0].id").must_equal 1
    @context.eval("row1.intersect(row2).values[1].id").must_equal 2
    @context.eval("row2.intersect(row1).values[0].id").must_equal 1
    @context.eval("row2.intersect(row1).values[1].id").must_equal 2
    @context.eval("row1.intersect(row3).values[0].id").must_equal 1
    @context.eval("row1.intersect(row3).values[1].id").must_equal 2
    @context.eval("row2.intersect(row3).values[0].id").must_equal 1
    @context.eval("row2.intersect(row3).values[1].id").must_equal 2
    @context.eval("typeof(row1.intersect(row4)) === 'undefined'").must_equal true
    @context.eval("row2.intersect(row4).values[0].id").must_equal 2
    @context.eval("row2.intersect(row4).values[1].id").must_equal 2
    @context.eval("typeof(row1.intersect(row5)) === 'undefined'").must_equal true
    @context.eval("typeof(row2.intersect(row5)) === 'undefined'").must_equal true
    @context.eval("typeof(row3.intersect(row4)) === 'undefined'").must_equal true
    @context.eval("row1.intersect(row6).values[0].id").must_equal 1
    @context.eval("row1.intersect(row6).values[1]").must_equal '*'
    @context.eval("row2.intersect(row6).values[0]").must_equal '*'
    @context.eval("row2.intersect(row6).values[1].id").must_equal 2
    @context.eval("row6.intersect(row6).values[0]").must_equal '*'
    @context.eval("row6.intersect(row6).values[1]").must_equal '*'
    
  end
  
  def test_specifics_row_intersection
    
    intersect_rows = "
      var row1 = new Row({'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row({'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row({'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':2}});
      var row5 = new Row({'OccurrenceAEncounter':{'id':3},'OccurrenceBEncounter':{'id':3}});
      var row6 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':3}});
      
      var specific1 = new Specifics([row1]);
      var specific2 = new Specifics([row2]);
      var specific3 = new Specifics([row3,row4]);
      var specific4 = new Specifics([row3,row6]);
      var specific5 = new Specifics([row5,row6]);
    "
    
    @context.eval(intersect_rows)
    @context.eval("specific1.intersect(specific2).rows.length").must_equal 1
    @context.eval("specific1.intersect(specific2).rows[0].values[0].id").must_equal 1
    @context.eval("specific1.intersect(specific2).rows[0].values[1].id").must_equal 2

    @context.eval("specific1.intersect(specific3).rows.length").must_equal 1
    @context.eval("specific1.intersect(specific3).rows[0].values[0].id").must_equal 1
    @context.eval("specific1.intersect(specific3).rows[0].values[1].id").must_equal 2

    @context.eval("specific1.intersect(specific4).rows.length").must_equal 2
    @context.eval("specific1.intersect(specific4).rows[0].values[0].id").must_equal 1
    @context.eval("specific1.intersect(specific4).rows[0].values[1].id").must_equal 2
    @context.eval("specific1.intersect(specific4).rows[1].values[0].id").must_equal 1
    @context.eval("specific1.intersect(specific4).rows[1].values[1].id").must_equal 3

    @context.eval("specific2.intersect(specific3).rows.length").must_equal 2
    @context.eval("specific2.intersect(specific3).rows[0].values[0].id").must_equal 1
    @context.eval("specific2.intersect(specific3).rows[0].values[1].id").must_equal 2
    @context.eval("specific2.intersect(specific3).rows[1].values[0].id").must_equal 2
    @context.eval("specific2.intersect(specific3).rows[1].values[1].id").must_equal 2
    
    @context.eval("specific2.intersect(specific5).rows.length").must_equal 0
    
    @context.eval("specific4.intersect(specific5).rows.length").must_equal 1
    @context.eval("specific4.intersect(specific5).rows[0].values[0].id").must_equal 1
    @context.eval("specific4.intersect(specific5).rows[0].values[1].id").must_equal 3
    
  end
  
  def test_negation
    rows = "
      var row1 = new Row({'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row({'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row({'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':3}});
      var row5 = new Row({'OccurrenceAEncounter':{'id':3},'OccurrenceBEncounter':{'id':4}});
      var row6 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':3}});

      var specific1 = new Specifics([row1]);
      var specific2 = new Specifics([row2]);
      var specific3 = new Specifics([row3,row4]);
      var specific4 = new Specifics([row3,row6]);
      var specific5 = new Specifics([row5,row6]);
      var specific6 = new Specifics([row1,row2])
    "
    
    # test negation single specific
    # test negation multiple specifics
    
    @context.eval(rows)
    
    # has row checks
    @context.eval('specific1.hasRow(row1)').must_equal true
    @context.eval('specific1.hasRow(row2)').must_equal true
    @context.eval('specific1.hasRow(row3)').must_equal true
    @context.eval('specific1.hasRow(row4)').must_equal false
    @context.eval('specific1.hasRow(row5)').must_equal false
    
    # cartesian checks
    @context.eval('Specifics._generateCartisian([[1,2,3]]).length').must_equal 3
    @context.eval('Specifics._generateCartisian([[1,2,3],[5,6]]).length').must_equal 6
    @context.eval('Specifics._generateCartisian([[1,2,3],[5,6]])[0][0]').must_equal 1
    @context.eval('Specifics._generateCartisian([[1,2,3],[5,6]])[0][1]').must_equal 5
    @context.eval('Specifics._generateCartisian([[1,2,3],[5,6]])[1][0]').must_equal 1
    @context.eval('Specifics._generateCartisian([[1,2,3],[5,6]])[1][1]').must_equal 6
    @context.eval('Specifics._generateCartisian([[1,2,3],[5,6]])[2][0]').must_equal 2
    @context.eval('Specifics._generateCartisian([[1,2,3],[5,6]])[2][1]').must_equal 5
    
    # specificsWithValue on Row
    @context.eval('row1.specificsWithValues()[0]').must_equal 0
    @context.eval('row2.specificsWithValues()[0]').must_equal 1
    @context.eval('row3.specificsWithValues()[0]').must_equal 0
    @context.eval('row3.specificsWithValues()[1]').must_equal 1

    # specificsWithValue on Specific
    @context.eval('specific1.specificsWithValues()[0]').must_equal 0
    @context.eval('specific2.specificsWithValues()[0]').must_equal 1
    @context.eval('specific3.specificsWithValues()[0]').must_equal 0
    @context.eval('specific3.specificsWithValues()[1]').must_equal 1
    @context.eval('specific6.specificsWithValues()[0]').must_equal 0
    @context.eval('specific6.specificsWithValues()[1]').must_equal 1
    
    @context.eval('specific1.negate().rows.length').must_equal 4
    @context.eval('specific1.negate().rows[0].values[0].id').must_equal 2
    @context.eval('specific1.negate().rows[1].values[0].id').must_equal 3
    @context.eval('specific1.negate().rows[2].values[0].id').must_equal 4
    @context.eval('specific1.negate().rows[3].values[0].id').must_equal 5
    
    # 5*5 values = 25 in the cartesian - 2 in the non-negated = 23 negated - 5 rows with OccurrA and OccurrB equal = 18!
    @context.eval('specific5.negate().rows.length').must_equal 18
    
  end
  
  def test_add_rows_has_rows_has_specifics
    rows = "
      var row1 = new Row({'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row({'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row({});

      var specific1 = new Specifics();
      var specific2 = new Specifics([row2]);
    "
    
    # test negation single specific
    # test negation multiple specifics
    
    @context.eval(rows)
    
    @context.eval('specific1.hasRows()').must_equal false
    @context.eval('specific2.hasRows()').must_equal true
    @context.eval('specific1.hasSpecifics()').must_equal false
    @context.eval('specific2.hasSpecifics()').must_equal true
    @context.eval('row3.hasSpecifics()').must_equal false
    @context.eval('row2.hasSpecifics()').must_equal true
    
    @context.eval('specific1.rows.length').must_equal 0
    @context.eval('specific1.addRows([row2])')
    @context.eval('specific1.rows.length').must_equal 1
    @context.eval('specific2.rows.length').must_equal 1
    @context.eval('specific2.addRows([row3])')
    @context.eval('specific2.rows.length').must_equal 2
    
  end

  def test_maintain_specfics
    @context.eval('var x = new Boolean(true)')
    @context.eval("x.specificContext = 'specificContext'")
    @context.eval("x.specific_occurrence = 'specific_occurrence'")
    @context.eval('var a = new Boolean(true)')
    @context.eval("a = Specifics.maintainSpecifics(a,x)")
    @context.eval("typeof(a.specificContext) != 'undefined'").must_equal true
    @context.eval("typeof(a.specific_occurrence) != 'undefined'").must_equal true
    
  end

  def test_compact_reused_events
    rows = "
      var row1 = new Row({'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row({'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row({'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':2}});
      var row5 = new Row({'OccurrenceAEncounter':{'id':3},'OccurrenceBEncounter':{'id':3}});
      var row6 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':3}});
      
      var specific1 = new Specifics([row1,row2,row3,row4,row5,row6]);
    "
    
    @context.eval(rows)
    
    @context.eval('specific1.rows.length').must_equal 6
    @context.eval('specific1.compactReusedEvents().rows.length').must_equal 4
    
  end

  def test_row_build_rows_for_matching
    
    events = "
      var entryKey = 'OccurrenceAEncounter';
      var boundsKey = 'OccurrenceBEncounter';
      var entry = {'id':3};
      var bounds = [{'id':1},{'id':2},{'id':3},{'id':4},{'id':5},{'id':6},{'id':7},{'id':8}];
    "

    @context.eval(events)
    @context.eval('var rows = Row.buildRowsForMatching(entryKey,entry,boundsKey,bounds)')
    @context.eval('rows.length').must_equal 8
    @context.eval('rows[0].values.length').must_equal 2
    @context.eval('rows[0].values[0].id').must_equal 3
    @context.eval('rows[0].values[1].id').must_equal 1
    @context.eval('rows[7].values[0].id').must_equal 3
    @context.eval('rows[7].values[1].id').must_equal 8
    @context.eval('var specific = new Specifics(rows)')
    @context.eval('specific.rows.length').must_equal 8
    @context.eval('specific.compactReusedEvents().rows.length').must_equal 7
    
  end
  
  def test_row_build_for_data_criteria

    events = "
      var entryKey = 'OccurrenceAEncounter';
      var entries = [{'id':1},{'id':2},{'id':3},{'id':4},{'id':5},{'id':6},{'id':7},{'id':8}];
    "

    @context.eval(events)
    @context.eval('var rows = Row.buildForDataCriteria(entryKey,entries)')
    @context.eval('rows.length').must_equal 8
    @context.eval('rows[0].values.length').must_equal 2
    @context.eval('rows[0].values[0].id').must_equal 1
    @context.eval('rows[0].values[1]').must_equal '*'
    @context.eval('rows[7].values[0].id').must_equal 8
    @context.eval('rows[7].values[1]').must_equal '*'
    
  end
  
  def test_finalize_events
    rows = "
      var row1 = new Row({'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row({'OccurrenceAEncounter':{'id':2}});
      var row3 = new Row({'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row({'OccurrenceBEncounter':{'id':4}});
      var row5 = new Row({'OccurrenceBEncounter':{'id':5}});
      var row6 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':4}});
      var row7 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':5}});
      var row8 = new Row({'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':4}});
      
      var specific1 = new Specifics([row1,row2]);
      var specific2 = new Specifics([row3,row4,row5]);
      var specific3 = new Specifics([row6,row7,row8]);
    "
    @context.eval(rows)
    @context.eval('var result = specific1.finalizeEvents(specific2,specific3)')
    @context.eval('result.rows.length').must_equal 3
    @context.eval('result.rows[0].values[0].id').must_equal 1
    @context.eval('result.rows[0].values[1].id').must_equal 4
    @context.eval('result.rows[1].values[0].id').must_equal 1
    @context.eval('result.rows[1].values[1].id').must_equal 5
    @context.eval('result.rows[2].values[0].id').must_equal 2
    @context.eval('result.rows[2].values[1].id').must_equal 4

    @context.eval('var result = specific2.finalizeEvents(specific1,specific3)')
    @context.eval('result.rows.length').must_equal 3

    @context.eval('var result = specific1.finalizeEvents(null,specific3)')
    @context.eval('result.rows.length').must_equal 3
    
    # result if 5 and not 6 becasue the 2/2 row gets dropped
    @context.eval('var result = specific1.finalizeEvents(specific2, null)')
    @context.eval('result.rows.length').must_equal 5
    
  end
  
  def test_validate
    rows = "
      var row1 = new Row({'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row({'OccurrenceAEncounter':{'id':2}});
      var row3 = new Row({'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row({'OccurrenceBEncounter':{'id':4}});
      var row5 = new Row({'OccurrenceBEncounter':{'id':5}});
      var row6 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':4}});
      var row7 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':5}});
      var row8 = new Row({'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':4}});

      var row9 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':6}});
      
      var specific1 = new Specifics([row1,row2]);
      var specific2 = new Specifics([row3,row4,row5]);
      var specific3 = new Specifics([row6,row7,row8]);
      var specific4 = new Specifics([row9]);
      var specific5 = new Specifics();
      
      var pop1 = new Boolean(true)
      pop1.specificContext = specific1

      var pop2 = new Boolean(true)
      pop2.specificContext = specific2

      var pop3 = new Boolean(true)
      pop3.specificContext = specific3

      var pop4 = new Boolean(true)
      pop4.specificContext = specific4

      var pop5 = new Boolean(true)
      pop5.specificContext = specific5
      
      var pop3f = new Boolean(false)
      pop3f.specificContext = specific3
            
    "
    @context.eval(rows)
    
    @context.eval('Specifics.validate(pop1,pop2,pop3)').must_equal true
    @context.eval('Specifics.validate(pop1,pop2,pop4)').must_equal false
    @context.eval('Specifics.validate(pop1,pop2,pop5)').must_equal false
    @context.eval('Specifics.validate(pop3f,pop1,pop2)').must_equal false
    
  end
  
  def test_intersect_all

    rows = "
      var row1 = new Row({'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row({'OccurrenceAEncounter':{'id':2}});
      var row3 = new Row({'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row({'OccurrenceBEncounter':{'id':4}});
      var row5 = new Row({'OccurrenceBEncounter':{'id':5}});
      var row6 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':4}});
      var row7 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':5}});
      var row8 = new Row({'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':4}});
      
      var specific1 = new Specifics([row1,row2]);
      var specific2 = new Specifics([row3,row4,row5]);
      var specific3 = new Specifics([row6,row7,row8]);
      
      var pop1 = new Boolean(true)
      pop1.specificContext = specific1

      var pop2 = new Boolean(true)
      pop2.specificContext = specific2

      var pop3 = new Boolean(true)
      pop3.specificContext = specific3
      
            
    "
    @context.eval(rows)
    
    @context.eval('var intersection = Specifics.intersectAll(new Boolean(true), [pop1,pop2,pop3])')
    assert @context.eval('intersection.isTrue()')
    @context.eval('var result = intersection.specificContext')
    
    @context.eval('result.rows.length').must_equal 3

    @context.eval('result.rows[0].values[0].id').must_equal 1
    @context.eval('result.rows[0].values[1].id').must_equal 4
    @context.eval('result.rows[1].values[0].id').must_equal 1
    @context.eval('result.rows[1].values[1].id').must_equal 5
    @context.eval('result.rows[2].values[0].id').must_equal 2
    @context.eval('result.rows[2].values[1].id').must_equal 4

    @context.eval('var intersection = Specifics.intersectAll(new Boolean(true), [pop1,pop2,pop3], true)')
    @context.eval('var result = intersection.specificContext')
    
    # 5*5 = 25 - 5 equal rows - 3 non-negated = 17
    @context.eval('result.rows.length').must_equal 17
    
  end
  
  def test_union_all

    rows = "
      var row1 = new Row({'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row({'OccurrenceAEncounter':{'id':2}});
      var row3 = new Row({'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row({'OccurrenceBEncounter':{'id':4}});
      var row5 = new Row({'OccurrenceBEncounter':{'id':5}});
      var row6 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':4}});
      var row7 = new Row({'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':5}});
      var row8 = new Row({'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':4}});
      
      var specific1 = new Specifics([row1,row2]);
      var specific2 = new Specifics([row3,row4,row5]);
      var specific3 = new Specifics([row6,row7,row8]);
      
      var pop1 = new Boolean(true)
      pop1.specificContext = specific1

      var pop2 = new Boolean(true)
      pop2.specificContext = specific2

      var pop3 = new Boolean(true)
      pop3.specificContext = specific3
      
            
    "
    @context.eval(rows)
    
    @context.eval('var union = Specifics.unionAll(new Boolean(true), [pop1,pop2,pop3])')
    assert @context.eval('union.isTrue()')
    @context.eval('var result = union.specificContext')
    
    @context.eval('result.rows.length').must_equal 8

    @context.eval('var union = Specifics.unionAll(new Boolean(true), [pop1,pop2,pop3], true)')
    assert @context.eval('union.isTrue()')
    @context.eval('var result = union.specificContext')
    
    # originally 5*5, but we remove 1,2 from the left and 2,4,5 from the right
    # that leaves [3,4,5] x [1,3] which is 6 rows... minus the 3,3 row we get 5 rows
    
    @context.eval('result.rows.length').must_equal 5

  end
  
  
end