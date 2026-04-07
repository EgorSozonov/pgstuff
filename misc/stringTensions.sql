create table string_tension(
   set_name text not null,
   string_id smallint not null,
   gauge_in double precision not null,
   note smallint not null,
   tension_kg double precision not null,
   scale_length_cm double precision not null default 65.5,
   material_and_winding_e smallint not null,
   manufacturer text,
   created_at timestamptz not null default current_timestamp,
   primary key (set_name, string_id)
);

insert into string_tension(
   set_name, string_id, gauge_in, note, tension_kg, 
   material_and_winding_e, manufacturer
) 
values
   ('ECG26', 1, 0.013, 64, 12.44, 1, 'D''Addario'),
   ('ECG26', 2, 0.017, 59, 11.94, 1, 'D''Addario'),
   ('ECG26', 3, 0.026, 55, 18.07, 2, 'D''Addario'),
   ('ECG26', 4, 0.035, 50, 16.26, 2, 'D''Addario'),
   ('ECG26', 5, 0.045, 45, 15.11, 2, 'D''Addario'),
   ('ECG26', 6, 0.056, 40, 12.54, 2, 'D''Addario'),
   ('ECG25', 1, 0.012, 64, 10.61, 1, 'D''Addario'),
   ('ECG25', 2, 0.016, 59, 10.57, 1, 'D''Addario'),
   ('ECG25', 3, 0.024, 55, 15.42, 2, 'D''Addario'),
   ('ECG25', 4, 0.032, 50, 13.7,  2, 'D''Addario'),
   ('ECG25', 5, 0.042, 45, 12.93, 2, 'D''Addario'),
   ('ECG25', 6, 0.052, 40, 10.75, 2, 'D''Addario'),
   ('ECG24', 1, 0.011, 64,  8.89, 1, 'D''Addario'),
   ('ECG24', 2, 0.015, 59,  9.29, 1, 'D''Addario'),
   ('ECG24', 3, 0.022, 55, 13.01, 2, 'D''Addario'),
   ('ECG24', 4, 0.030, 50, 12.11, 2, 'D''Addario'),
   ('ECG24', 5, 0.040, 45,  12.2, 2, 'D''Addario'),
   ('ECG24', 6, 0.050, 40, 10.07, 2, 'D''Addario'),
   ('ECG24', 7, 0.065, 35,  9.98, 2, 'D''Addario')
;


-- as dev
CREATE or replace FUNCTION dev.material_and_winding_e(v smallint)
RETURNS text 
immutable
AS $material_and_winding_e$
declare
   workPath text;
BEGIN
   case v
   when 1 then return 'Naked steel';
   when 2 then return 'Steel, flatwound by steel';
   when 3 then return 'Steel, flatwound by nylon';
   when 4 then return 'Steel, roundwound by steel';
   when 5 then return 'Naked nylon';
   when 6 then return 'Nylon, roundwound by copper';
   when 7 then return 'Nylon, flatwound by steel';
   else raise 'unknown value % in material_and_winding enum', v;
   end case;
END; $material_and_winding_e$ LANGUAGE plpgsql;


-- as dev
-- example: select dev.calc_tension('ECG26', 6, 38);
CREATE or replace FUNCTION dev.calc_tension(set_name_arg text, string_id_arg integer, note_arg integer)
RETURNS text 
immutable
AS $calc_tension$
declare
   teh_string string_tension%ROWTYPE;
   freq_multiplier double precision;
BEGIN
   select * into strict teh_string
      from string_tension where (set_name, string_id) = (set_name_arg, string_id_arg);
   freq_multiplier := power(1.059463094359, note_arg - teh_string.note);
   return teh_string.tension_kg * freq_multiplier * freq_multiplier;
      
END; $calc_tension$ LANGUAGE plpgsql;

-- as dev
-- example: select dev.calc_tension_at_length('ECG26', 6, 38, 68.5);
CREATE or replace FUNCTION dev.calc_tension_at_length(
   set_name_arg text, string_id_arg integer, note_arg integer, scale_length_cm double precision
)
RETURNS text 
immutable
AS $calc_tension$
declare
   teh_string string_tension%ROWTYPE;
   freq_multiplier double precision;
   scale_multiplier double precision;
BEGIN
   select * into strict teh_string
      from string_tension where (set_name, string_id) = (set_name_arg, string_id_arg);
   freq_multiplier := power(1.059463094359, note_arg - teh_string.note);
   scale_multiplier := scale_length_cm/teh_string.scale_length_cm;
   return teh_string.tension_kg * freq_multiplier * freq_multiplier 
      * scale_multiplier * scale_multiplier;
END; $calc_tension$ LANGUAGE plpgsql;


