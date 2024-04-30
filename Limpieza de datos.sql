
-- Se crea base de datos no existente llamada 'Clean' 
create database if not exists clean;


-- Se ocupa la base de datos recien creada llamada Clean
use clean;


-- Se seeleciona todas las columnas de la tabla limpieza con un limite de  10
select * from limpieza limit 10;


-- Se crea una Store procedure para poder acceder a la tabla mas facilmente (es una especie de macro)
DELIMITER //
CREATE PROCEDURE limp()
BEGIN 
	SELECT * FROM limpieza;
END //
DELIMITER ;


call limp();


-- Buscamos Estandarizar los Datos, ahora Cambiamos la columna ID empleados y genero
ALTER TABLE limpieza CHANGE COLUMN `ï»¿Id?empleado` Id_emp varchar (20) null;
ALTER TABLE limpieza CHANGE COLUMN `genero` Gender varchar (20) null;


-- Intentamos contar cuantos duplicados tenemos en la columna de Id_emp con having nos aseguramos que se seleccionen los conjuntos que contengan > 1
-- y porque > 1 porque si tenemos mas de un duplicado nos mostrara que hay mas de un registro identico
select Id_emp, count(*) as cantidad_duplicados from limpieza group by Id_emp having count(*) > 1; 


-- Aqui estamos haciendo una subquery para que nos cuente cuantos numeros de registros hay en la query principal 
select count(*) as cantidad_duplicados
from ( 
select Id_emp, count(*) as cantidad_duplicados from limpieza group by Id_emp having count(*) > 1
)
as subquery; 

-- Ahora que ya sabemos cuantos duplicados tenemos, hay que removerlos. Para eso crearemos una tabla temporal 

rename table limpieza to conduplicados;

create temporary table temp_limpieza AS -- Estas tablas duran solo una sesion 
SELECT DISTINCT * from conduplicados;  -- Ahora seleccionamos todos los registros distintos de la tabla conduplicados

select count(*) as orginal from conduplicados; -- Con estas dos consultas estamos verificando cuantos numeros de registro tienen.
select count(*) as orginal from temp_limpieza;

CREATE TABLE LIMPIEZA AS select * from temp_limpieza;  -- Convertimos la tabla temporal en una tabla permanente con la tabla que no tiene valores duplicados.

call limp();  -- verificamos.

select count(*) as registros_limpieza from limpieza; -- verificamos.

DROP TABLE conduplicados; -- Borramos la tabla que contiene los duplicados.

SET sql_safe_updates = 0; -- Esta linea de codigo sirve para poder tener accesos a cambios mas 'bruscos', es el modo seguro de SQL


-- Ya que limpiamos los datos duplicados vamos a estandarizar las columnas que nos faltan a idioma ENG.

ALTER TABLE limpieza change column `Apellido` Lastname varchar (50) null;
ALTER TABLE limpieza change column `star_date` Start_date varchar (50) null; 

DESCRIBE limpieza; -- usamos DESCRIBE para poder ver en que tipo de datos esta cada columna.


SELECT NAME FROM limpieza
WHERE length(name) - length(trim(name)) > 0;  -- Aca contamos numeros de caracteres de la columna name - la columna name sin espacios. Si da mayor a 0 significa que hay espacios.

select name, trim(name) as name
from limpieza
where length(name) - length(trim(name)) > 0; -- Aca probamos la linea de codigo en un SELECT para estar seguros.

UPDATE limpieza SET NAME = trim(name)		-- Integramos los cambios de manera permanente.
where length(name) - length(trim(name)) > 0; 

call limp(); -- Comprobamos

select lastname, trim(lastname) as lastname
from limpieza
where length(lastname) - length(trim(lastname)) > 0; -- Hacemos lo mismo pero con la columna Lastname.

UPDATE limpieza SET lastname = trim(lastname)
where length(name) - length(trim(lastname)) > 0;

call limp();		-- Comprobamos

ALTER TABLE limpieza CHANGE COLUMN `Lastname` last_name varchar(40) null;  -- Cambiamos el nombre de la columna.

UPDATE limpieza SET last_name = trim(last_name)
where length(last_name) - length(trim(last_name)) > 0; 		-- Volvemos a intentar quitar los espacios con el nombre nuevo.

SELECT last_name from limpieza
where last_name regexp '\\s{2,}'; 	-- Aca buscamos 2 o mas espacios con la expresion regexp 

SELECT area, trim(regexp_replace(area, '\\s{2,}', ' ')) as ensayo from limpieza; -- Intentamos limpear esos espacios en una pequeña columna de prueba.

UPDATE limpieza SET area = trim(regexp_replace(area, '\\s{2,}', ' ')); -- Integramos esos cambios a la tabla original


call limp();  -- Comprobamos.

SELECT Gender , 		-- Aca intentamos cambiar de idioma la columna pasar de hombre a male y de mujer a female. Haciendo una pequeña prueba en gender1
CASE
	when Gender = 'hombre' then 'male'
	when Gender = 'mujer' then 'female'
	else 'other'
END AS GENDER1
FROM limpieza;

UPDATE limpieza SET Gender =  		 -- una vez comprobado integramos a la tabla
CASE
	when Gender = 'hombre' then 'male'
	when Gender = 'mujer' then 'female'
	else 'other'
END;

call limp(); 		-- Comprobamos

DESCRIBE limpieza;  -- Revisamos los metadatos.

ALTER TABLE limpieza modify column type TEXT; -- Pasamos la columna type a TEXT

SELECT type , 			-- Aca queremos que los numeros representaban modalidades de trabajo, 0 para remotos 1 para hibridos asi que intentamos aclarar la información.
CASE 
	when type = 0 then 'Remote'
    when type = 1 then 'Hybrid'
    else 'other'
end as type1
from limpieza;

UPDATE limpieza SET type =  			-- Una vez estamos seguros lo pasamos a la tabla principal.
CASE 
	when type = 0 then 'Remote'
    when type = 1 then 'Hybrid'
    else 'other'
end;


call limp();   			-- Comprobamos

SELECT salary,
				CAST(trim(REPLACE(replace(salary, '$',''), ',' , '')) AS decimal (15, 2)) AS salary1 from limpieza;  -- Aca le sacamos los signos $ y los espacios a la columna salary  y luego convertimos en valor decimal

SET SQL_SAFE_UPDATES = 0; -- Le sacamos el modo de seguridad

update limpieza SET salary = CAST(trim(REPLACE(replace(salary, '$',''), ',' , '')) AS decimal (15, 2));  -- Integramos los cambios

call limp(); -- Comprobamos

ALTER TABLE limpieza modify column salary int null; -- Cambiamos el metadato de la columna Salary

DESCRIBE limpieza;  -- Comprobamos los metadatos

SELECT birth_date from limpieza;   -- Aca intentaremos estandarizar las fechas 

select birth_date, case          -- Intentamos cambiar los / y los - a un formato comun.
when birth_date like '%/%' then date_format(str_to_date(birth_date, '%m/%d/%y'), '%y-%m-%d') 
when birth_date like '%-%' then date_format(str_to_date(birth_date, '%m/%d/%y'), '%y-%m-%d')
else null
end as new_birth_date 
from limpieza;

UPDATE limpieza 			-- Ya comprobado integramos a la tabla.
set birth_date = case
when birth_date like '%/%' then date_format(str_to_date(birth_date, '%m/%d/%Y'), '%Y-%m-%d')
when birth_date like '%-%' then date_format(str_to_date(birth_date, '%m/%d/%Y'), '%Y-%m-%d')
else null
end;

call limp(); -- Comprobamos

ALTER TABLE limpieza modify column birth_date date;  -- Hacemos lo mismo pero con start date

SELECT start_date, case 
when start_date like '%/%' then date_format(str_to_date(start_date, '%m/%d/%Y'), '%Y-%m-%d')
when start_date like '%-%' then date_format(str_to_date(start_date, '%m/%d/%Y'), '%Y-%m-%d')

END as new_start_date
from limpieza;

UPDATE limpieza    -- Integramos.
SET start_date = CASE
when start_date like '%/%' then date_format(str_to_date(start_date, '%m/%d/%Y'), '%Y-%m-%d')
when start_date like '%-%' then date_format(str_to_date(start_date, '%m/%d/%Y'), '%Y-%m-%d')
else NULL
END;

call limp();  -- Comporbamos

ALTER TABLE LIMPIEZA MODIFY COLUMN start_date DATE;
DESCRIBE LIMPIEZA; -- Revisamos.

select finish_date from limpieza;  -- Revisamos si finish_date necesita los mismo cambios/

SELECT finish_date, str_to_date(finish_date, '%Y-%m-%d %H:%i:%s') AS fecha from limpieza; 		-- Algo parecido a lo anterior pero ahora integramos las horas minutos y segundos.
SELECT finish_date, date_format(str_to_date(finish_date, '%Y-%m-%d %H:%i:%s'), '%Y-%m-%d') AS fecha from limpieza;
SELECT finish_date, str_to_date(finish_date, '%Y-%m-%d') AS fd FROM limpieza;
SELECT finish_date, str_to_date(finish_date, '%H:%i:%s') AS hour_stamp FROM limpieza;
SELECT finish_date, date_format(finish_date, '%H:%i:%s') AS hour_stamp FROM limpieza;

ALTER TABLE LIMPIEZA add column date_backup text;  -- Agregamos un backup de la fecha.

SET sql_safe_updates = 0;   -- Quitamos la seguridad de SQL

UPDATE limpieza SET date_backup = finish_date;  -- Copimos la columna finish_date para obtener nuestro backup

SELECT finish_date, str_to_date(finish_date, '%Y-%m-%d %H:%i:%s') AS fecha from limpieza;  -- Revisamos que todo este bien.

UPDATE limpieza SET finish_date =  str_to_date(finish_date, '%Y-%m-%d %H:%i:%s UTC')  -- Ya comprobado integramos a la tabla
WHERE finish_date <>'';


ALTER TABLE limpieza        -- Agregamos las columnas date y time para aprovechar todos los datos que conseguimos anteriormente.
	add column fecha date,
    add column hora time;

UPDATE limpieza 		-- Integramos.
	SET fecha= date(finish_date),
		hora= time(finish_date)
	where finish_date is not null and finish_date <> '';

UPDATE limpieza set finish_date = null where finish_date = ''; -- Pedimos que nos devuelva null cuando no tengamos los datos suficientes.

call limp(); -- Revisamos.

ALTER TABLE limpieza MODIFY COLUMN finish_date datetime;      -- Modificamos el metadato.


ALTER TABLE limpieza add column age INT;   -- Agregamos una columna de edad.

select name, birth_date, start_date, timestampdiff(year, birth_Date, start_date) as edad_de_ingreso from limpieza;  -- Ocupamos los datos de ingreso que tenemos con las fechas para conseguir la edad.

UPDATE limpieza
	SET age = timestampdiff(year, birth_date, curdate());

SELECT name, age  from limpieza;   

SELECT concat(substring_index(name,' ', 1),'_', substring(last_name, 1, 2), '.', substring(type, 1, 1), '@consulting.com') as email from limpieza; -- Creamos un correo con el nombre, apellido y modalidad.

ALTER TABLE limpieza add column email varchar(100); -- Añadimos la columna email.

UPDATE limpieza SET email = concat(substring_index(name,' ', 1),'_', substring(last_name, 1, 2), '.', substring(type, 1, 1), '@consulting.com');  -- Una vez comprobado integramos.


SELECT id_emp, name, last_name, age, gender, area, salary, email, finish_date from limpieza  -- Seleccionamos estas columnas  para nuestra tabla "Final"
WHERE finish_date <= curdate() or finish_date is null
order by area, name;


SELECT area, count(*) as cantidad_empleados from limpieza -- Prueba de cantidad de empleados.
GROUP BY area
ORDER BY cantidad_empleados DESC;
