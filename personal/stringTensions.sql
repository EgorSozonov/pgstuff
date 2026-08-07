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
   ('Bare', 8, 0.008, 64,  4.70, 1, 'Any'),
   ('Bare', 9, 0.009, 64,  5.95, 1, 'Any'),
   ('Bare', 18, 0.018, 59, 13.38, 1, 'Any'),
   ('Bare', 19, 0.019, 59, 14.91, 1, 'Any'),
   ('ECG23', 1,  0.01, 64,  7.35, 1, 'D''Addario'),
   ('ECG23', 2, 0.014, 59,  8.07, 1, 'D''Addario'),
   ('ECG23', 3,  0.02, 55,   9.4, 2, 'D''Addario'),
   ('ECG23', 4, 0.028, 50,  9.92, 2, 'D''Addario'),
   ('ECG23', 5, 0.038, 45, 10.12, 2, 'D''Addario'),
   ('ECG23', 6, 0.048, 40,  9.24, 2, 'D''Addario'),
   ('ECG24', 1, 0.011, 64,  8.89, 1, 'D''Addario'),
   ('ECG24', 2, 0.015, 59,  9.29, 1, 'D''Addario'),
   ('ECG24', 3, 0.022, 55, 13.01, 2, 'D''Addario'),
   ('ECG24', 4, 0.030, 50, 12.11, 2, 'D''Addario'),
   ('ECG24', 5, 0.040, 45,  12.2, 2, 'D''Addario'),
   ('ECG24', 6, 0.050, 40, 10.07, 2, 'D''Addario'),
   ('ECG24', 7, 0.065, 35,  9.98, 2, 'D''Addario'),
   ('ECG25', 1, 0.012, 64, 10.61, 1, 'D''Addario'),
   ('ECG25', 2, 0.016, 59, 10.57, 1, 'D''Addario'),
   ('ECG25', 3, 0.024, 55, 15.42, 2, 'D''Addario'),
   ('ECG25', 4, 0.032, 50, 13.7,  2, 'D''Addario'),
   ('ECG25', 5, 0.042, 45, 12.93, 2, 'D''Addario'),
   ('ECG25', 6, 0.052, 40, 10.75, 2, 'D''Addario'),
   ('ECG26', 1, 0.013, 64, 12.44, 1, 'D''Addario'),
   ('ECG26', 2, 0.017, 59, 11.94, 1, 'D''Addario'),
   ('ECG26', 3, 0.026, 55, 18.07, 2, 'D''Addario'),
   ('ECG26', 4, 0.035, 50, 16.26, 2, 'D''Addario'),
   ('ECG26', 5, 0.045, 45, 15.11, 2, 'D''Addario'),
   ('ECG26', 6, 0.056, 40, 12.54, 2, 'D''Addario'),
   ('EJ45',  1, 0.028, 64,  7.35, 5, 'D''Addario'),
   ('EJ45',  2, 0.032, 59,  5.44, 5, 'D''Addario'),
   ('EJ45',  3, 0.040, 55,  5.40, 5, 'D''Addario'),
   ('EJ45',  4, 0.029, 50,  7.08, 8, 'D''Addario'),
   ('EJ45',  5, 0.035, 45,  7.21, 8, 'D''Addario'),
   ('EJ45',  6, 0.043, 40,  6.44, 8, 'D''Addario'),
   ('CF128', 1, 0.027, 64,   6.9, 5, 'Thomastik-Infeld'),
   ('CF128', 2, 0.031, 59,   5.5, 5, 'Thomastik-Infeld'),
   ('CF128', 3, 0.027, 55,   6.5, 7, 'Thomastik-Infeld'),
   ('CF128', 4, 0.030, 50,   6.5, 7, 'Thomastik-Infeld'),
   ('CF128', 5, 0.035, 45,   6.4, 7, 'Thomastik-Infeld'),
   ('CF128', 6, 0.045, 40,   6.4, 7, 'Thomastik-Infeld')
on conflict do nothing;

-- as dev
create or replace function material_and_winding_e(v smallint)
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
   when 8 then return 'Nylon, roundwound by steel';
   else raise 'unknown value % in material_and_winding enum', v;
   end case;
END; $material_and_winding_e$ LANGUAGE plpgsql;


-- as dev
-- example: select calc_tension('ECG26', 6, 38);
create or replace function calc_tension(set_name_arg text, string_id_arg integer, note_arg integer)
returns text 
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
-- example: select calc_tension_at_length('ECG26', 6, 38, 68.5);
create or replace function calc_tension_at_length(
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


--select calc_tension_at_length('ECG23', 1, 66, 67) as "first",
--       calc_tension_at_length('ECG23', 2, 61, 67) as snd,
--       calc_tension_at_length('CF128', 3, 56, 67) as third,
--       calc_tension_at_length('CF128', 4, 51, 67) as fourth,
--       calc_tension_at_length('CF128', 5, 44, 67) as fifth;

-- 11    16  | 17 26 35
-- 10.4 12.4 | 7.9 10.6 7.6
-- 22.8      | 25.8
--select calc_tension_at_length('ECG24', 1, 65, 67) as "first",
--       calc_tension_at_length('ECG25', 2, 60, 67) as snd,
--       calc_tension_at_length('ECG26', 2, 55, 67) as third,
--       calc_tension_at_length('ECG26', 3, 50, 67) as fourth,
--       calc_tension_at_length('ECG26', 4, 43, 67) as fifth;

-- 11 15 | 17 26w 45w
--  21.5 | 23.4
select calc_tension_at_length('ECG24', 1, 64, 67) as "first",
       calc_tension_at_length('ECG24', 2, 61, 67) as snd,
       calc_tension_at_length('ECG26', 2, 54, 67) as third,
       calc_tension_at_length('ECG26', 3, 47, 67) as fourth,
       calc_tension_at_length('ECG26', 5, 40, 67) as fifth;
       
       
--QUINTAR AEBF#B
-- 12 15 | 17 26w 45w
--  23.3 | 23.4
select calc_tension_at_length('ECG25', 1, 64, 67) as "first",
       calc_tension_at_length('ECG24', 2, 61, 67) as snd,
       calc_tension_at_length('ECG26', 2, 54, 67) as third,
       calc_tension_at_length('ECG26', 3, 47, 67) as fourth,
       calc_tension_at_length('ECG26', 5, 40, 67) as fifth;
       
       
-- 10 14 | 16 19 32w
--  22.8 | 23.7
select calc_tension_at_length('ECG23', 1, 67, 67) as "first",
       calc_tension_at_length('ECG23', 2, 62, 67) as snd,
       calc_tension_at_length('ECG25', 2, 57, 67) as third,
       calc_tension_at_length('Bare', 19, 52, 67) as fourth,
       calc_tension_at_length('ECG25', 4, 45, 67) as fifth;

