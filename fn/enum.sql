CREATE or replace FUNCTION dev.current_status_e(v smallint)
RETURNS text 
immutable
AS $current_status_e$
declare
   workPath text;
BEGIN
   case v
   when 0 then return 'new';
   when 1 then return 'processing';
   when 2 then return 'processed';
   when 3 then return 'ignored';
   else raise 'unknown value % in current_status_enum', v;
   end case;
END; $current_status_e$ LANGUAGE plpgsql;

