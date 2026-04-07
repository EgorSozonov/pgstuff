
drop function if exists dev.importData;
CREATE or replace FUNCTION dev.importData(importName text)
RETURNS SETOF text 
AS $importData$
declare
   workPath text;
   fileContent text;
   jsonContent json;
   colCount integer;
   colNamesTypes text;
   colNames text;
   query text;
   i integer;
   importQ text;
BEGIN
   workPath := '/home/onr/pg/';

   -- Read the file content into a text variable
   -- The size limit is specified (e.g., 10,000,000 bytes or ~10MB)
   SELECT pg_read_file(format('%s%s.tabm', workPath, importName), 0, 10000000) 
      INTO fileContent;

   -- Cast the text content to a JSONB type
   jsonContent := fileContent::json;
   return next jsonContent;
   
   colNamesTypes := (jsonContent->0->'col') || ' ' || (jsonContent->0->>'ty')::text;
   colNames := (jsonContent->0->'col');
   colCount := json_array_length(jsonContent);
   for i in 1..(colCount - 1) loop
      colNamesTypes := colNamesTypes 
                     || ',' || (jsonContent->i->'col')
                     || ' ' || (jsonContent->i->>'ty')::text;
      colNames := colNames || ',' || (jsonContent->i->'col');
   end loop;
   
   query :=  'create temporary table imported(' || colNamesTypes || ');';
   
   execute query;
   return next query;
   
   importQ := format(
      $$COPY "imported"(%s) FROM '%s%s.csv' WITH (FORMAT csv, HEADER false, DELIMITER ',');$$,
      colNames, workPath, importName
   );
   return next importQ;
   execute importQ;
   return query select description::text from imported;
   

EXCEPTION
    WHEN others THEN
        RAISE EXCEPTION 'Error reading file or parsing JSON: %', SQLERRM;

END; $importData$ LANGUAGE plpgsql;



drop function if exists dev.exportData;
CREATE or replace FUNCTION dev.exportData(exportName Text, query Text)
RETURNS SETOF text 
AS $exportData$
declare
   workPath text;
   typeQ text;
BEGIN
   workPath := '/home/onr/pg/';
   
   -- creating temporary view to get types of columns
   execute 'create temporary view __v_' || exportName || ' as ' || query;
   typeQ := format(
      $$ 
      select json_agg(row_to_json(a))::text from (
          select 
             column_name as col,
             CASE when data_type = 'USER-DEFINED' then 'text' else data_type END as ty
          from information_schema.columns
          where table_name = '__v_%I'
      ) as a
      $$, exportName, exportName
   );
   
   --execute typeQ into metadata;
   --return next metadata; 
   
   execute format(
      $$copy(%s) to '%s%s.tabm' with (format text, header false)$$, 
      typeQ, workPath, exportName);
   
   execute format(
      $$copy (%s) to '%s%s.csv' with (FORMAT csv, HEADER false, DELIMITER ',')$$, 
      query, workPath, exportName
   );
   --return next fullQ;
   
EXCEPTION
    WHEN others THEN
        RAISE EXCEPTION 'Error exporting query result to file: %', SQLERRM;

END; $exportData$ LANGUAGE plpgsql;

/*
select dev.exportData('bar'::text, $$
select *
from hamster
$$::text);

*/

do $exportData$
declare
   query text := $$
      select *
      from hamster
   $$;
   exportName text := 'bar';
   workPath text := '/home/onr/pg/';
   typeQ text;
BEGIN
   -- creating temporary view to get types of columns
   execute 'create temporary view __v_' || exportName || ' as ' || query;
   typeQ := format(
      $$ 
      select json_agg(row_to_json(a))::text from (
         select 
            column_name as col,
            CASE WHEN data_type = 'USER-DEFINED' THEN 'text' ELSE data_type END as ty
         from information_schema.columns
         where table_name = '__v_%I'
      ) as a
      $$, exportName, exportName
   );
   
   execute format(
      $$copy(%s) to '%s%s.tabm' with (format text, header false)$$, 
      typeQ, workPath, exportName);
   
   execute format(
      $$copy (%s) to '%s%s.csv' with (FORMAT csv, HEADER false, DELIMITER ',')$$, 
      query, workPath, exportName
   );
   
EXCEPTION
    WHEN others THEN
        RAISE EXCEPTION 'Error exporting query result to file: %', SQLERRM;

END; $exportData$ LANGUAGE plpgsql;



--select dev.importData('bar'::text);
